import 'package:flutter/widgets.dart';

/// Messages made only of emoji (one to three, spaces allowed) are shown
/// large and without a bubble, like stickers.
abstract final class EmojiOnly {
  /// Most emoji a message may have to be shown large.
  static const max = 3;

  // One emoji: a pictograph or a flag, with any skin tones, variation
  // selectors and joiners (families, professions) it carries.
  // (The analyzer checks patterns without Unicode mode; this one is valid
  // with it, see emoji_only_test.dart.)
  static final _emoji = RegExp(
    // ignore: valid_regexps
    r'^(?:[\u{1F1E6}-\u{1F1FF}]{2}|\p{Extended_Pictographic}[\u{FE0F}\u{1F3FB}-\u{1F3FF}\u{20E3}]*(?:\u{200D}\p{Extended_Pictographic}[\u{FE0F}\u{1F3FB}-\u{1F3FF}]*)*)$',
    unicode: true,
  );

  /// How many emoji [text] is made of (1 to [max]), or null when it has
  /// anything else, or more.
  static int? count(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    var count = 0;
    for (final grapheme in trimmed.characters) {
      if (grapheme.trim().isEmpty) continue;
      if (!_emoji.hasMatch(grapheme)) return null;
      if (++count > max) return null;
    }
    return count == 0 ? null : count;
  }

  /// Font size for [count] large emoji: the fewer, the larger.
  static double size(int count) => switch (count) {
    1 => 56,
    2 => 44,
    _ => 36,
  };
}
