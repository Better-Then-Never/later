import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/social.dart';
import '../../../data/repositories/repositories.dart';

/// Reactions and comments of one open capsule, live.
///
/// Counts come from the reactions themselves while there are fewer than
/// [reactionLimit] (no wait for the server counters), otherwise from the
/// capsule's counters. The user's own reaction changes at once and rolls
/// back if the save fails.
class CapsuleSocialController extends ChangeNotifier {
  CapsuleSocialController({
    required this.capsule,
    required this.uid,
    required SocialRepository social,
    this.reactionLimit = 100,
    this.commentPage = 200,
  }) : _social = social {
    _reactionsSub = _social
        .watchReactions(capsule.id, limit: reactionLimit)
        .listen(_onReactions, onError: _onError('reactions'));
    _subscribeComments();
  }

  /// Comments are loaded this many at a time, newest first.
  final int commentPage;
  late int _commentLimit = commentPage;
  bool _loadingMoreComments = false;

  /// Older comments may exist before the first loaded one.
  bool get canLoadMoreComments => _comments.length >= _commentLimit;
  bool get isLoadingMoreComments => _loadingMoreComments;

  void _subscribeComments() {
    unawaited(_commentsSub?.cancel());
    _commentsSub = _social
        .watchComments(capsule.id, limit: _commentLimit)
        .listen(_onComments, onError: _onError('comments'));
  }

  /// Loads the next page of older comments.
  void loadMoreComments() {
    if (_loadingMoreComments || !canLoadMoreComments || _disposed) return;
    _loadingMoreComments = true;
    _commentLimit += commentPage;
    _notify();
    _subscribeComments();
  }

  final Capsule capsule;

  /// The signed-in user.
  final String uid;
  final SocialRepository _social;
  final int reactionLimit;

  StreamSubscription<List<CapsuleReaction>>? _reactionsSub;
  StreamSubscription<List<CapsuleComment>>? _commentsSub;
  List<CapsuleReaction> _reactions = const [];
  List<CapsuleComment> _comments = const [];
  bool _commentsLoaded = false;
  bool _disposed = false;

  /// The user's reaction while a change is being saved (null = none).
  ReactionType? _pending;
  bool _hasPending = false;

  bool get isOwner => capsule.ownerId == uid;
  bool get commentsLoaded => _commentsLoaded;
  List<CapsuleComment> get comments => _comments;

  /// Top-level comments, oldest first, each followed by its replies.
  List<CapsuleComment> get thread {
    final replies = <String, List<CapsuleComment>>{};
    final roots = <CapsuleComment>[];
    for (final c in _comments) {
      final parent = c.replyTo;
      if (parent == null) {
        roots.add(c);
      } else {
        replies.putIfAbsent(parent, () => []).add(c);
      }
    }
    final rootIds = {for (final r in roots) r.id};
    return [
      for (final r in roots) ...[r, ...?replies[r.id]],
      // Replies whose comment is gone stay visible at the end.
      for (final e in replies.entries)
        if (!rootIds.contains(e.key)) ...e.value,
    ];
  }

  int get commentCount =>
      _commentsLoaded ? _comments.length : capsule.commentCount;

  ReactionType? get myReaction {
    if (_hasPending) return _pending;
    for (final r in _reactions) {
      if (r.uid == uid) return r.type;
    }
    return null;
  }

  /// How many people chose each reaction (the user's choice included).
  Map<ReactionType, int> get counts {
    if (_reactions.length >= reactionLimit) {
      return {...capsule.reactionCounts};
    }
    final result = <ReactionType, int>{};
    for (final r in _reactions) {
      if (r.uid == uid) continue;
      result[r.type] = (result[r.type] ?? 0) + 1;
    }
    final mine = myReaction;
    if (mine != null) result[mine] = (result[mine] ?? 0) + 1;
    return result;
  }

  void _onReactions(List<CapsuleReaction> reactions) {
    _reactions = reactions;
    _notify();
  }

  void _onComments(List<CapsuleComment> comments) {
    _loadingMoreComments = false;
    _comments = comments;
    _commentsLoaded = true;
    _notify();
  }

  void Function(Object, StackTrace) _onError(String what) => (e, st) {
    AppLogger.warning('Capsule $what stream failed', error: e, stackTrace: st);
    if (what == 'comments') _commentsLoaded = true;
    _notify();
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Tapping the user's current reaction removes it; any other replaces it.
  Future<AppFailure?> react(ReactionType type) async {
    final next = myReaction == type ? null : type;
    _pending = next;
    _hasPending = true;
    _notify();
    try {
      await _social.setReaction(capsule.id, uid, next);
      return null;
    } catch (e, st) {
      AppLogger.warning('Reaction failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.capsulesReactionFailed,
      );
    } finally {
      _hasPending = false;
      _pending = null;
      _notify();
    }
  }

  Future<AppFailure?> addComment(String text, {String? replyTo}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > CapsuleComment.maxLength) {
      return ValidationFailure(AppL10n.current.capsulesCommentTooLong);
    }
    try {
      await _social.addComment(
        capsule.id,
        authorId: uid,
        text: trimmed,
        replyTo: replyTo,
      );
      return null;
    } catch (e, st) {
      AppLogger.warning('Comment failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.capsulesCommentFailed,
      );
    }
  }

  /// The author and the capsule's owner may delete a comment.
  bool canDelete(CapsuleComment comment) => comment.authorId == uid || isOwner;

  Future<AppFailure?> deleteComment(CapsuleComment comment) async {
    try {
      await _social.deleteComment(capsule.id, comment.id);
      return null;
    } catch (e, st) {
      AppLogger.warning('Deleting a comment failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.capsulesCommentDeleteFailed,
      );
    }
  }

  Future<AppFailure?> report({
    required ReportTarget target,
    required String targetPath,
    required ReportReason reason,
  }) async {
    try {
      await _social.report(
        reporterId: uid,
        target: target,
        targetPath: targetPath,
        reason: reason,
      );
      return null;
    } catch (e, st) {
      AppLogger.warning('Report failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.commonErrorGeneric,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_reactionsSub?.cancel());
    unawaited(_commentsSub?.cancel());
    super.dispose();
  }
}
