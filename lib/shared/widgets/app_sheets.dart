import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';

/// The two ways the app opens something over a page (F-32), over the same
/// dimmed scrim (MOTION_CATALOG.md, "Sheets and cards"):
///
/// * [showCenteredSheet]: a card in the middle of the screen for menus,
///   confirmations, short forms and the capsule dialog ([AppCardRoute]): it
///   rises from below and settles; a tap outside or a drag down closes it;
///   the keyboard pushes it up.
/// * [showEdgeSheet]: a panel from the bottom edge for lists and threads,
///   built with [EdgeSheet] (rounded top, grab handle); dragging it down
///   closes it.
abstract final class AppSheets {
  /// Corner radius of every card and sheet.
  static const double radius = 25;

  /// Width of the centred cards (menus and confirmations).
  static const double cardWidth = 264;
}

Future<T?> showCenteredSheet<T>(BuildContext context, Widget child) =>
    Navigator.of(context).push(
      AppCardRoute<T>(
        builder: (_) => child,
        barrierColor: context.palette.scrim,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );

Future<T?> showEdgeSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: context.palette.scrim,
      sheetAnimationStyle: AppMotion.reduced(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppMotion.emphasized,
              reverseDuration: AppMotion.standard,
              curve: AppMotion.emphasizedCurve,
              reverseCurve: AppMotion.standardCurve,
            ),
      builder: builder,
    );

/// A card over the page, centred, on a scrim: the route of
/// [showCenteredSheet] and of dialogs. A page route (not a popup), so a
/// [Hero] can fly into it. Enter: the card rises from below the screen and
/// settles from 96 % while the scrim darkens; no fade (an opacity layer the
/// size of the card every frame made the capsule dialog janky). Out: a tap
/// outside, back, or a drag down past a third of the card or with a flick.
/// Reduced motion: no animation.
class AppCardRoute<T> extends PageRoute<T> {
  AppCardRoute({
    required this.builder,
    required Color barrierColor,
    required String barrierLabel,
    this.alignment = Alignment.center,
    this.rise = true,
    super.settings,
  }) : _barrierColor = barrierColor,
       _barrierLabel = barrierLabel;

  final WidgetBuilder builder;

  /// The card rises from below the screen; false: it fades in where it is
  /// (a card over the keyboard, which lifts it as it opens).
  final bool rise;

  /// Where the card sits in the space above the keyboard: centred, or at
  /// the bottom (right above the keyboard, as the quick reply does).
  final AlignmentGeometry alignment;
  final Color _barrierColor;
  final String _barrierLabel;

  @override
  Color? get barrierColor => _barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppMotion.emphasized;

  @override
  Duration get reverseTransitionDuration => AppMotion.standard;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Material(
    // Text and fields on the card take the theme's styles (without it, a
    // title fell back to Flutter's yellow-underlined error style).
    type: MaterialType.transparency,
    // The top card (with its text field) stays above the keyboard; a card
    // under another one keeps its place (it overflowed when squeezed). The
    // page is built once; the builder follows the route becoming covered.
    child: Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: ModalRoute.isCurrentOf(context) ?? true
              ? MediaQuery.viewInsetsOf(context).bottom
              : 0,
        ),
        child: Align(
          alignment: alignment,
          child: _DragToClose(child: builder(context)),
        ),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    if (!rise) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
        child: child,
      );
    }
    final curve = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasizedCurve,
      reverseCurve: AppMotion.exit,
    );
    // A rise only. Fading the card was an offscreen layer of the whole card
    // every frame (the capsule dialog went 20 % janky); scaling it made
    // Impeller draw its letters again at every new size (glyph atlas).
    final travel = MediaQuery.sizeOf(context).height * 0.6;
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, travel * (1 - curve.value)),
        child: child,
      ),
    );
  }
}

/// The thumbnail a sheet opens from: where it is on screen and its corner
/// radius ([AppSheetRoute.origin]).
class SheetOrigin {
  const SheetOrigin(this.rect, {required this.radius});

  /// In global coordinates.
  final Rect rect;
  final double radius;

  /// Where [context]'s box is now (null when it is not laid out).
  static SheetOrigin? of(BuildContext? context, {required double radius}) {
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return SheetOrigin(
      box.localToGlobal(Offset.zero) & box.size,
      radius: radius,
    );
  }
}

/// A sheet from the bottom edge over the page, on a scrim: the opened
/// capsule (v3). It rises from below the screen, or grows out of the
/// thumbnail it opened from ([origin]); out: a tap above it, back, or a drag
/// down past a third of it or with a flick. Its content gets up to the
/// screen less the status bar and 23 dp (the opened capsule takes all of
/// it), at most 560 dp wide. Reduced motion: no animation.
class AppSheetRoute<T> extends PageRoute<T> {
  double _top = 0;

  AppSheetRoute({
    required this.builder,
    required Color barrierColor,
    required String barrierLabel,
    this.origin,
    super.settings,
  }) : _barrierColor = barrierColor,
       _barrierLabel = barrierLabel;

  final WidgetBuilder builder;
  final Color _barrierColor;
  final String _barrierLabel;

  /// The thumbnail the sheet opens from, for a sheet with a [SheetPicture]:
  /// the picture starts on it and grows into place while the sheet rises
  /// around it, its surface fading in ([SheetSurface]), all as one piece;
  /// closing, it all goes back into the thumbnail the same way.
  final SheetOrigin? origin;

  @override
  Color? get barrierColor => _barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppMotion.emphasized;

  @override
  Duration get reverseTransitionDuration =>
      origin == null ? AppMotion.standard : AppMotion.emphasized;

  /// The rise, eased: in with the emphasized curve; out with exit, or, back
  /// into a thumbnail, the same curve mirrored, so the picture settles into
  /// it as it settled into place.
  CurvedAnimation? _rise;
  CurvedAnimation get _eased => _rise ??= CurvedAnimation(
    parent: animation!,
    curve: AppMotion.emphasizedCurve,
    reverseCurve: origin == null
        ? AppMotion.exit
        : AppMotion.emphasizedCurve.flipped,
  );

  /// The sheet's picture (it registers itself).
  _SheetPictureState? _picture;

  /// Whether the sheet grows out of [origin] (or back into it) this time:
  /// decided once per direction, once the picture is laid out. Scrolled
  /// away from its picture, the sheet just slides down.
  bool _grows = false;
  AnimationStatus? _decided;

  void _decide() {
    final status = animation!.status;
    if (origin == null || status == _decided) return;
    final place = _place();
    // Opening: until the picture's first layout (it is laid out before the
    // first frame is drawn).
    if (place == null && status == AnimationStatus.forward) return;
    _decided = status;
    _grows = place != null && !_picture!._scrolled;
  }

  /// The picture's place in the page as laid out (the rise does not move
  /// it); null before its first layout.
  Rect? _place() {
    final box = _picture?.context.findRenderObject();
    final page = subtreeContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (page is! RenderBox || !page.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: page) & box.size;
  }

  /// [origin] in the page's coordinates.
  Rect _from() {
    final overlay = navigator?.overlay?.context.findRenderObject();
    final shift = overlay is RenderBox && overlay.attached
        ? overlay.localToGlobal(Offset.zero)
        : Offset.zero;
    return origin!.rect.shift(-shift);
  }

  /// How far the sheet's surface (and its handle and the buttons on its
  /// picture) has faded in: over the first part of a rise from a thumbnail,
  /// out over the last part of the way back; 1 otherwise.
  double get _fade =>
      _grows ? const Interval(0, 0.3).transform(animation!.value) : 1;

  @override
  void dispose() {
    _rise?.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // Only the size and the status bar: the whole MediaQuery would rebuild
    // the sheet on every frame of a keyboard opened over it.
    final height = MediaQuery.sizeOf(context).height;
    // The tallest status bar seen: Android's share sheet hides it for a
    // moment, and the sheet grew into the gap (it jumped up).
    _top = math.max(_top, MediaQuery.paddingOf(context).top);
    final top = _top;
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // 23 dp under the status bar, as the design (52 of 800).
            maxHeight: math.max(0, height - top - 23),
            maxWidth: 560,
          ),
          child: _DragToClose(child: builder(context)),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final rise = _eased;
    final travel = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: rise,
      child: child,
      builder: (context, child) {
        _decide();
        final place = _grows ? _place() : null;
        // From just below the screen (no fade: see AppCardRoute), or from
        // where the picture sits on the thumbnail: the picture's top edge
        // then follows the thumbnail's way into place.
        final from = place == null ? travel : _from().top - place.top;
        return Transform.translate(
          offset: Offset(0, from * (1 - rise.value)),
          child: child,
        );
      },
    );
  }
}

/// A sheet's surface: [color], its top corners [radius], clipping [child].
/// Growing out of a thumbnail ([AppSheetRoute.origin]), the colour fades in
/// around the picture, so the tapped card seems to become the sheet.
class SheetSurface extends StatelessWidget {
  const SheetSurface({
    super.key,
    required this.color,
    required this.radius,
    required this.child,
  });

  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => _GrowFade(
    child: child,
    builder: (fade, child) => Material(
      color: color.withValues(alpha: color.a * fade),
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

/// A sheet's square picture, its corners [radius], that grows out of the
/// thumbnail the sheet opened from ([AppSheetRoute.origin]): it starts on
/// the thumbnail, with its corners, and grows into place while the sheet
/// rises around it; [over] (badges, buttons) grows with it, fading in.
/// Anywhere else: [child] clipped to [radius] with [over] on top.
class SheetPicture extends StatefulWidget {
  const SheetPicture({
    super.key,
    required this.radius,
    required this.child,
    this.over = const [],
  });

  final double radius;
  final Widget child;

  /// Laid over the picture (children of a [Stack]), not clipped.
  final List<Widget> over;

  @override
  State<SheetPicture> createState() => _SheetPictureState();
}

class _SheetPictureState extends State<SheetPicture> {
  AppSheetRoute<Object?>? _route;
  ScrollPosition? _scroll;

  /// Scrolled away from the top of its sheet.
  bool get _scrolled {
    final scroll = _scroll;
    return scroll != null && scroll.hasPixels && scroll.pixels > 0.5;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scroll = Scrollable.maybeOf(context)?.position;
    final route = ModalRoute.of(context);
    if (route is AppSheetRoute<Object?> &&
        route.origin != null &&
        route != _route) {
      _leave();
      _route = route.._picture = this;
    }
  }

  void _leave() {
    if (_route?._picture == this) _route!._picture = null;
    _route = null;
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }

  // The same widgets at rest and growing, so nothing in the picture is
  // built again when it lands.
  Widget _layers(double radius, double fade, Matrix4 transform) => Transform(
    transform: transform,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: widget.child,
        ),
        Opacity(
          opacity: fade,
          child: Stack(fit: StackFit.expand, children: widget.over),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final route = _route;
    if (route == null) {
      return _layers(widget.radius, 1, Matrix4.identity());
    }
    final rise = route._eased;
    return AnimatedBuilder(
      animation: rise,
      builder: (context, _) {
        final t = rise.value;
        final place = route._grows && t < 1 ? route._place() : null;
        if (place == null || place.isEmpty) {
          return _layers(widget.radius, 1, Matrix4.identity());
        }
        // Where it is drawn now: from the thumbnail to its place. The sheet
        // has moved its top edge there already (AppSheetRoute); this moves
        // it sideways and scales it from that edge.
        final now = Rect.lerp(route._from(), place, t)!;
        final scale = now.width / place.width;
        final from = route.origin!.radius;
        final radius = (from + (widget.radius - from) * t) / scale;
        return _layers(
          radius,
          route._fade,
          Matrix4.diagonal3Values(scale, scale, 1)
            ..setTranslationRaw(now.left - place.left, 0, 0),
        );
      },
    );
  }
}

/// Builds with how far a sheet growing out of a thumbnail has faded in (1 on
/// any other route, and once it has).
class _GrowFade extends StatelessWidget {
  const _GrowFade({required this.builder, required this.child});

  final Widget Function(double fade, Widget child) builder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is! AppSheetRoute<Object?> || route.origin == null) {
      return builder(1, child);
    }
    return AnimatedBuilder(
      animation: route._eased,
      child: child,
      builder: (context, child) => builder(route._fade, child!),
    );
  }
}

/// Follows a downward drag on the card; past a third of its height, or on a
/// flick, the route closes; otherwise the card springs back.
class _DragToClose extends StatefulWidget {
  const _DragToClose({required this.child});

  final Widget child;

  @override
  State<_DragToClose> createState() => _DragToCloseState();
}

class _DragToCloseState extends State<_DragToClose>
    with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );
  double _dy = 0;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _back.addListener(() {
      setState(() => _dy = _from * (1 - AppMotion.exit.transform(_back.value)));
    });
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails details) {
    _back.stop();
    setState(() => _dy = (_dy + details.delta.dy).clamp(0, double.infinity));
  }

  void _end(DragEndDetails details) {
    final height = context.size?.height ?? 1;
    if (_dy > height / 3 || details.velocity.pixelsPerSecond.dy > 700) {
      Navigator.of(context).maybePop();
      return;
    }
    _from = _dy;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onVerticalDragUpdate: _update,
    onVerticalDragEnd: _end,
    child: Transform.translate(offset: Offset(0, _dy), child: widget.child),
  );
}

/// A [showEdgeSheet] panel: [height] tall, rounded top corners, the grab
/// handle on top of [child].
class EdgeSheet extends StatelessWidget {
  const EdgeSheet({
    super.key,
    required this.height,
    required this.child,
    this.color,
  });

  final double height;
  final Widget child;

  /// The page background when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color ?? context.palette.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: Column(
        children: [
          const SheetHandle(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The grab handle at the top of a sheet: it can be dragged down to close.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key}) : _v2 = false;

  /// The v2 sheets' grabber (capsule v3): divider grey, 20 dp to the content.
  const SheetHandle.v2({super.key}) : _v2 = true;

  final bool _v2;

  @override
  Widget build(BuildContext context) {
    // Fades in with a sheet growing out of a thumbnail (SheetSurface).
    return _GrowFade(
      builder: (fade, child) => Opacity(opacity: fade, child: child),
      child: Padding(
        padding: EdgeInsets.only(top: 8, bottom: _v2 ? 8 : 4),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: _v2 ? context.palette.divider : context.palette.disabled,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// A list in an edge sheet that lets the sheet close with a drag down
/// anywhere: a short list leaves its empty space to the sheet's own drag,
/// and pulling a long one down past its top closes the sheet too (one used
/// to have to reach for the handle).
class SheetList extends StatefulWidget {
  const SheetList({super.key, required this.list});

  /// The list, built with `shrinkWrap: true` so it is only as tall as its
  /// rows.
  final Widget list;

  @override
  State<SheetList> createState() => _SheetListState();
}

class _SheetListState extends State<SheetList> {
  /// Pulled this far past the top, the sheet closes.
  static const _closeAfter = 64.0;

  double _pulled = 0;
  bool _closing = false;

  bool _onScroll(ScrollNotification n) {
    if (n is OverscrollNotification &&
        n.dragDetails != null &&
        n.overscroll < 0) {
      _pulled -= n.overscroll;
      if (_pulled > _closeAfter && !_closing) {
        _closing = true;
        Navigator.of(context).maybePop();
      }
    } else if (n is ScrollEndNotification ||
        (n is ScrollUpdateNotification && n.metrics.pixels > 0)) {
      _pulled = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Align(alignment: Alignment.topCenter, child: widget.list),
      );
}

/// A card that types (a quick reply, the description) shown together with
/// the keyboard: it stays hidden until the keyboard starts to rise and then
/// comes up on it (it used to sit at the bottom first and be pushed up a
/// moment later). After [wait] it shows anyway (a hardware keyboard).
class AppearWithKeyboard extends StatefulWidget {
  const AppearWithKeyboard({super.key, required this.child});

  final Widget child;

  static const wait = Duration(milliseconds: 700);

  @override
  State<AppearWithKeyboard> createState() => _AppearWithKeyboardState();
}

class _AppearWithKeyboardState extends State<AppearWithKeyboard> {
  bool _shown = false;
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    _wait = Timer(AppearWithKeyboard.wait, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown && MediaQuery.viewInsetsOf(context).bottom > 0) {
      _shown = true;
      _wait?.cancel();
    }
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: AppMotion.of(context, AppMotion.fast),
      child: widget.child,
    );
  }
}

/// Opens [child] (a card that types) at the bottom, on the keyboard: it
/// fades in as the keyboard rises and closes on a tap outside, back or a
/// drag down.
Future<T?> showOnKeyboard<T>(BuildContext context, Widget child) =>
    Navigator.of(context).push(
      AppCardRoute<T>(
        builder: (_) => AppearWithKeyboard(child: child),
        alignment: Alignment.bottomCenter,
        // The keyboard lifts it; rising as well looked like a jolt.
        rise: false,
        barrierColor: context.palette.scrim,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );
