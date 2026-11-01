import 'package:flutter/widgets.dart';

/// What the profile's postcard does with the page's scrolling (Profile v4):
///
/// - pulled down at the top by [openPull] or more, it opens to the whole
///   photo and stays open (Samsung Settings' big title);
/// - scrolled by [closeAt] or more while open, it closes again;
/// - scrolled past `stripAt`, the photo strip shows.
///
/// Works with both Android's clamping scroll (the pull arrives as
/// overscroll) and iOS's bounce (negative pixels).
class PostcardScroll extends ChangeNotifier {
  static const openPull = 64.0;
  static const closeAt = 24.0;

  bool get open => _open;
  bool _open = false;

  bool get strip => _strip;
  bool _strip = false;

  double _pull = 0;

  void onScroll(ScrollNotification n, {required double stripAt}) {
    if (n.depth != 0) return;
    final pixels = n.metrics.pixels;
    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      _pull -= n.overscroll;
      if (_pull >= openPull) _setOpen(true);
    } else if (n is ScrollUpdateNotification) {
      if (pixels < -openPull && n.dragDetails != null) _setOpen(true);
      if (_open && pixels > closeAt) _setOpen(false);
    } else if (n is ScrollEndNotification || n is ScrollStartNotification) {
      _pull = 0;
    }
    final strip = pixels > stripAt;
    if (strip != _strip) {
      _strip = strip;
      notifyListeners();
    }
  }

  /// Opens or closes the postcard (also from a tap, for screen readers).
  void setOpen(bool open) => _setOpen(open);

  void _setOpen(bool open) {
    if (open == _open) return;
    _open = open;
    _pull = 0;
    notifyListeners();
  }
}
