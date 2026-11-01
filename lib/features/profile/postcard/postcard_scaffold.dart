import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import 'postcard_scroll.dart';
import 'profile_postcard.dart';

/// A page that starts with a postcard (Profile v4): yours or a friend's.
///
/// The postcard opens to the whole photo when pulled down at the top and
/// stays open; scrolling closes it. Scrolled past it, [strip] (the photo
/// strip) stays on top. [buttons] sit top right and [leading] top left in
/// every state.
class PostcardScaffold extends StatefulWidget {
  const PostcardScaffold({
    super.key,
    required this.postcard,
    required this.strip,
    required this.buttons,
    required this.body,
    this.leading,
    this.bottomPadding = 24,
    this.extraHeader = 0,
  });

  /// Builds the postcard; `open` is true while pulled open.
  final Widget Function(BuildContext context, bool open) postcard;
  final Widget strip;
  final Widget buttons;
  final Widget? leading;
  final List<Widget> body;
  final double bottomPadding;

  /// How much taller than the default the postcard is above its name (the
  /// strip appears once the name has scrolled under it).
  final double extraHeader;

  @override
  State<PostcardScaffold> createState() => _PostcardScaffoldState();
}

class _PostcardScaffoldState extends State<PostcardScaffold> {
  final _postcard = PostcardScroll();
  bool _wasOpen = false;

  @override
  void initState() {
    super.initState();
    _postcard.addListener(_changed);
  }

  void _changed() {
    if (_postcard.open && !_wasOpen) HapticFeedback.lightImpact();
    _wasOpen = _postcard.open;
    setState(() {});
  }

  @override
  void dispose() {
    _postcard.removeListener(_changed);
    _postcard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // The strip takes over once the name has gone under where it ends.
    final stripAt =
        8 +
        ProfilePostcard.photoDefault +
        60 +
        widget.extraHeader -
        ProfilePhotoStrip.height;
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _postcard.onScroll(n, stripAt: stripAt);
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: top + 8),
                    child: widget.postcard(context, _postcard.open),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, widget.bottomPadding),
                  sliver: SliverList.list(children: widget.body),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_postcard.strip,
              child: AnimatedOpacity(
                opacity: _postcard.strip ? 1 : 0,
                duration: AppMotion.standard,
                curve: AppMotion.enter,
                child: widget.strip,
              ),
            ),
          ),
          if (widget.leading != null)
            Positioned(top: top + 14, left: 14, child: widget.leading!),
          Positioned(top: top + 14, right: 14, child: widget.buttons),
        ],
      ),
    );
  }
}
