import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/app_dates.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';

/// An opened capsule's sheet under its wrapping until it is held open (D1):
/// the sheet is laid out underneath, so the wrapping covers it exactly and
/// tears open onto it. [onOpened] runs the moment it opens.
class CapsuleWrapHost extends StatefulWidget {
  const CapsuleWrapHost({
    super.key,
    required this.capsule,
    required this.radius,
    required this.onOpened,
    required this.child,
  });

  final Capsule capsule;

  /// The sheet's top corners.
  final double radius;
  final VoidCallback onOpened;
  final Widget child;

  @override
  State<CapsuleWrapHost> createState() => _CapsuleWrapHostState();
}

class _CapsuleWrapHostState extends State<CapsuleWrapHost> {
  bool _wrapped = true;

  @override
  Widget build(BuildContext context) => HeroMode(
    // The photo flies nowhere from under the wrapping (full screen waits
    // for it to open).
    enabled: !_wrapped,
    child: Stack(
      children: [
        ExcludeSemantics(excluding: _wrapped, child: widget.child),
        if (_wrapped)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(widget.radius),
              ),
              child: CapsuleWrap(
                capsule: widget.capsule,
                onOpen: widget.onOpened,
                onDone: () => setState(() => _wrapped = false),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The wrapping of a capsule opened for the first time (D1-D3): the
/// profile-cover pattern in the capsule's colour, its pin on a white seal, a
/// gift tag (from, title, when and where it was left) and how long it waited.
/// Press and hold about a second: a ring fills, the pin wobbles, ticks you
/// can feel come closer together; let go early and it winds back. Then one
/// firmer tick and the wrapping tears apart from the pin. Reduced motion: no
/// wobble, and a plain fade instead of the tear. A screen reader's double
/// tap opens it at once.
class CapsuleWrap extends StatefulWidget {
  const CapsuleWrap({
    super.key,
    required this.capsule,
    required this.onOpen,
    required this.onDone,
  });

  final Capsule capsule;

  /// The moment it opens (the tear starts).
  final VoidCallback onOpen;

  /// The wrapping is gone.
  final VoidCallback onDone;

  /// The wrapping's colour: the capsule's, paler in light, deeper in dark.
  static Color coverOf(CapsuleColor color, {required bool dark}) {
    final pin = switch (color) {
      CapsuleColor.red => AppColors.capsuleRed,
      CapsuleColor.blue => AppColors.capsuleBlue,
      CapsuleColor.green => AppColors.capsuleGreen,
      CapsuleColor.yellow => AppColors.capsuleYellow,
      CapsuleColor.orange => AppColors.capsuleOrange,
      CapsuleColor.purple => AppColors.capsulePurple,
    };
    return dark
        ? Color.lerp(pin, AppColors.mediaBlack, 0.7)!
        : Color.lerp(pin, AppColors.onAccent, 0.6)!;
  }

  @override
  State<CapsuleWrap> createState() => _CapsuleWrapState();
}

enum _Hint { hold, keep, longer }

class _CapsuleWrapState extends State<CapsuleWrap>
    with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final AnimationController _tear = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );

  /// How far the ring has filled, 0 to 1.
  final _progress = ValueNotifier<double>(0);
  Duration _last = Duration.zero;
  Duration _lastTick = Duration.zero;
  double _clockMs = 0;
  bool _holding = false;
  bool _opened = false;
  Offset? _downAt;
  _Hint _hint = _Hint.hold;

  /// The torn edge, down the middle from the top: x as a share of the width.
  late final List<Offset> _edge = _tornEdge(math.Random());

  @override
  void dispose() {
    _ticker.dispose();
    _tear.dispose();
    _pulse.dispose();
    _progress.dispose();
    super.dispose();
  }

  static List<Offset> _tornEdge(math.Random random) {
    final points = <Offset>[];
    var y = 0.0;
    while (y < 1) {
      points.add(Offset(0.5 + (random.nextDouble() * 0.07 - 0.035), y));
      y += 0.03 + random.nextDouble() * 0.05;
    }
    return points..add(const Offset(0.5, 1));
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1000;
    _last = elapsed;
    _clockMs = elapsed.inMicroseconds / 1000;
    final hold = AppMotion.holdToOpen.inMilliseconds;
    final back = AppMotion.holdWindBack.inMilliseconds;
    final p = _holding
        ? math.min(1.0, _progress.value + dt / hold)
        : math.max(0.0, _progress.value - dt / back);
    _progress.value = p;
    if (_holding) {
      // Ticks every 150 ms at first, every 50 ms near the end.
      final every = 150 - 100 * p;
      if ((elapsed - _lastTick).inMicroseconds / 1000 > every) {
        _lastTick = elapsed;
        unawaited(
          p > 0.75
              ? HapticFeedback.lightImpact()
              : HapticFeedback.selectionClick(),
        );
        if (!AppMotion.reduced(context)) _pulse.forward(from: 0);
      }
    }
    if (p >= 1) {
      _open();
    } else if (!_holding && p == 0) {
      _ticker.stop();
    }
  }

  void _down(PointerDownEvent event) {
    if (_opened) return;
    _downAt = event.position;
    _holding = true;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _hint = _Hint.keep);
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _move(PointerMoveEvent event) {
    // A drag is the sheet closing, not a hold.
    final at = _downAt;
    if (_holding && at != null && (event.position - at).distance > kTouchSlop) {
      _up();
    }
  }

  void _up() {
    if (!_holding) return;
    _holding = false;
    if (!_opened) setState(() => _hint = _Hint.longer);
  }

  void _open() {
    if (_opened) return;
    _opened = true;
    _holding = false;
    if (_ticker.isActive) _ticker.stop();
    _progress.value = 1;
    unawaited(HapticFeedback.heavyImpact());
    widget.onOpen();
    _tear.duration = AppMotion.reduced(context)
        ? AppMotion.standard
        : AppMotion.tear;
    setState(() {});
    unawaited(_tear.forward());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = palette.isDark;
    final cover = CapsuleWrap.coverOf(widget.capsule.color, dark: dark);
    final reduced = AppMotion.reduced(context);
    final l10n = context.l10n;
    final content = _WrapContent(
      capsule: widget.capsule,
      cover: cover,
      progress: _progress,
      pulse: _pulse,
      wobbleClock: () => _holding && !reduced ? _clockMs : null,
      hint: switch (_hint) {
        _Hint.hold => l10n.capsulesWrapHold,
        _Hint.keep => l10n.capsulesWrapKeepHolding,
        _Hint.longer => l10n.capsulesWrapHoldLonger,
      },
    );
    final pattern = _WrapPattern(
      cover: cover,
      pin: AppIcons.mapPin(widget.capsule.color.name),
      dark: dark,
    );
    return Semantics(
      container: true,
      button: true,
      label: l10n.capsulesWrapOpen,
      onTap: _opened ? null : _open,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: AnimatedBuilder(
          animation: _tear,
          builder: (context, _) {
            final t = _tear.value;
            if (!_opened) {
              return Stack(fit: StackFit.expand, children: [pattern, content]);
            }
            if (reduced) {
              return Opacity(
                opacity: 1 - t,
                child: Stack(
                  fit: StackFit.expand,
                  children: [pattern, content],
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, box) => _torn(
                t: t,
                size: box.biggest,
                pattern: pattern,
                content: content,
                surface: palette.surface,
              ),
            );
          },
        ),
      ),
    );
  }

  /// The wrapping tearing open: the halves fly apart from the torn edge, the
  /// seal swells and drops away, the words fade first.
  Widget _torn({
    required double t,
    required Size size,
    required Widget pattern,
    required _WrapContent content,
    required Color surface,
  }) {
    final total = AppMotion.tear.inMilliseconds;
    final halves = Interval(
      60 / total,
      1,
      curve: AppMotion.tearCurve,
    ).transform(t);
    final words = 1 - const Interval(0, 0.22).transform(t);
    final seal = Interval(0, 420 / total).transform(t);
    Widget half(bool left) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(
          size.width * 0.7 * halves * (left ? -1 : 1),
          0,
          0,
          1,
        )
        ..rotateZ((left ? -9 : 9) * math.pi / 180 * halves),
      child: ClipPath(
        clipper: _HalfClipper(edge: _edge, left: left),
        child: pattern,
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        half(true),
        half(false),
        content.torn(words: words, seal: seal),
      ],
    );
  }
}

/// Clips one half of the wrapping along the torn edge.
class _HalfClipper extends CustomClipper<Path> {
  const _HalfClipper({required this.edge, required this.left});

  final List<Offset> edge;
  final bool left;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(left ? 0 : size.width, 0);
    for (final p in edge) {
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    return path
      ..lineTo(left ? 0 : size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_HalfClipper old) => old.edge != edge || old.left != left;
}

/// The cover pattern: the app's line icons scattered on the capsule's
/// colour, as the profile covers are (a 4 × 4 tile of 60 dp cells, every
/// other row shifted).
class _WrapPattern extends StatelessWidget {
  const _WrapPattern({
    required this.cover,
    required this.pin,
    required this.dark,
  });

  final Color cover;
  final String pin;
  final bool dark;

  static const _cell = 60.0;
  static const _icon = 24.0;

  @override
  Widget build(BuildContext context) {
    final marks = [
      AppIcons.capsuleTimer,
      AppIcons.capsuleLocation,
      AppIcons.cameraFull,
      AppIcons.friendsBook,
      AppIcons.messagesNew,
      AppIcons.capsulePrivacy,
      pin,
    ];
    return RepaintBoundary(
      child: ColoredBox(
        color: cover,
        child: LayoutBuilder(
          builder: (context, box) {
            final rows = (box.maxHeight / _cell).ceil() + 1;
            final cols = (box.maxWidth / _cell).ceil() + 1;
            return ClipRect(
              child: Stack(
                children: [
                  for (var row = 0; row < rows; row++)
                    for (var col = 0; col < cols; col++) _mark(marks, row, col),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mark(List<String> marks, int row, int col) {
    final r = row % 4;
    final c = col % 4;
    final name = marks[((r * 4 + c) * 3 + r) % marks.length];
    final isPin = name == pin;
    final alpha = (isPin ? 0.24 : 0.17) * (dark ? 1.2 : 1);
    return Positioned(
      left: col * _cell + (row.isOdd ? _cell / 2 : 0) + 8,
      top: row * _cell + 12,
      width: _icon,
      child: Transform.rotate(
        angle: ((r * 7 + c * 13) % 9 - 4) * 0.06,
        child: Image.asset(
          name,
          width: _icon,
          opacity: AlwaysStoppedAnimation(alpha),
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// What lies on the wrapping: "Waited N days" at the top, the seal with its
/// ring and pin, the gift tag on its string, and the hint.
class _WrapContent extends StatelessWidget {
  const _WrapContent({
    required this.capsule,
    required this.cover,
    required this.progress,
    required this.pulse,
    required this.wobbleClock,
    required this.hint,
    this.words = 1,
    this.seal = 0,
  });

  final Capsule capsule;
  final Color cover;
  final ValueListenable<double> progress;
  final Animation<double> pulse;

  /// Milliseconds for the pin's wobble while it is held; null: still.
  final double? Function() wobbleClock;
  final String hint;

  /// The words' opacity while it tears.
  final double words;

  /// How far the seal has swelled and dropped away, 0 to 1.
  final double seal;

  _WrapContent torn({required double words, required double seal}) =>
      _WrapContent(
        capsule: capsule,
        cover: cover,
        progress: progress,
        pulse: pulse,
        wobbleClock: wobbleClock,
        hint: hint,
        words: words,
        seal: seal,
      );

  static const _sealSize = 168.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final waited = capsule.createdAt == null
        ? 0
        : DateTime.now().difference(capsule.createdAt!).inDays;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (waited > 0)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: words,
                child: _Pill(
                  text: context.l10n.capsulesWrapWaited(waited),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sealed(context, palette),
                  Opacity(
                    opacity: words,
                    child: Column(
                      children: [
                        Container(
                          width: 2,
                          height: 30,
                          color: palette.surface.withValues(alpha: 0.9),
                        ),
                        _GiftTag(capsule: capsule, cover: cover),
                        const SizedBox(height: 22),
                        _Pill(text: hint, fontSize: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The seal: a calm patch of the cover, a white disc, the ring that fills
  /// and the pin that wobbles; it swells and drops away when it tears.
  Widget _sealed(BuildContext context, AppPalette palette) {
    final swell = seal < 0.35
        ? 1 + 0.16 * AppMotion.tearCurve.transform(seal / 0.35)
        : 1.16 - 0.96 * AppMotion.tearCurve.transform((seal - 0.35) / 0.65);
    final drop = seal < 0.35
        ? 0.0
        : AppMotion.tearCurve.transform((seal - 0.35) / 0.65);
    final ring = AnimatedBuilder(
      animation: Listenable.merge([progress, pulse]),
      builder: (context, _) {
        final p = progress.value;
        final clock = wobbleClock();
        final wobble = clock == null
            ? 0.0
            : math.sin(clock / 38) * (1.5 + 6 * p) * math.pi / 180;
        final beat = 1 + 0.035 * math.sin(math.pi * pulse.value);
        return Transform.scale(
          scale: beat,
          child: SizedBox.square(
            dimension: _sealSize,
            child: CustomPaint(
              painter: _RingPainter(
                progress: p,
                track: palette.surface.withValues(alpha: 0.55),
                fill: AppColors.brandGreen,
              ),
              child: Center(
                child: Container(
                  width: _sealSize - 32,
                  height: _sealSize - 32,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadowRaised,
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: wobble,
                    child: Transform.scale(
                      scale: 1 + 0.14 * p,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
                        child: Image.asset(
                          AppIcons.mapPin(capsule.color.name),
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return SizedBox.square(
      dimension: _sealSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Calms the pattern around the seal.
          Positioned(
            left: -66,
            top: -66,
            right: -66,
            bottom: -66,
            child: Opacity(
              opacity: words,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [cover, cover, cover.withValues(alpha: 0)],
                    stops: const [0, 0.69, 1],
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -60 * drop),
            child: Transform.scale(
              scale: swell,
              child: Opacity(opacity: 1 - drop, child: ring),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ring around the seal: a pale track, and green as it fills from the
/// top, clockwise.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(6 + 3.5);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        stroke..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

/// The gift tag: who it is from, the title, when and where it was left.
class _GiftTag extends StatefulWidget {
  const _GiftTag({required this.capsule, required this.cover});

  final Capsule capsule;
  final Color cover;

  @override
  State<_GiftTag> createState() => _GiftTagState();
}

class _GiftTagState extends State<_GiftTag> {
  Future<String?>? _place;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _place ??= _lookup();
  }

  Future<String?> _lookup() async {
    final known = widget.capsule.placeName;
    if (known != null && known.isNotEmpty) return known;
    final position = widget.capsule.location;
    if (position == null) return null;
    return context.read<GeocodingService>().placeName(position);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final capsule = widget.capsule;
    final me = context.read<SessionController>().uid;
    final mine = capsule.ownerId == me;
    final owner = mine ? null : CapsuleAuthorRow.ownerNameOf(context, capsule);
    final from = mine
        ? Text(
            l10n.capsulesWrapFromYou,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          )
        : owner == null
        ? null
        : _from(l10n.capsulesWrapFrom(owner), owner, palette);
    final left = capsule.createdAt;
    return Transform.rotate(
      angle: -2 * math.pi / 180,
      child: Container(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.shadowRaised,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // The hole the string goes through.
            Positioned(
              top: -13,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.cover,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.divider, width: 1.5),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?from,
                Text(
                  capsule.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                if (left != null)
                  FutureBuilder<String?>(
                    future: _place,
                    builder: (context, snapshot) {
                      final date = AppDates.medium(left, l10n.localeName);
                      final place = snapshot.data;
                      return Text(
                        place == null || place.isEmpty
                            ? l10n.capsulesDatesLeft(date)
                            : l10n.capsulesWrapLeftIn(date, place),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "From Bob" with the name bold.
  Widget _from(String text, String name, AppPalette palette) {
    final at = text.indexOf(name);
    final base = AppTextStyles.body.copyWith(
      fontSize: 14,
      color: palette.textSecondary,
    );
    if (at < 0) return Text(text, style: base);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          TextSpan(text: text.substring(at + name.length)),
        ],
      ),
      style: base,
    );
  }
}

/// A white pill on the wrapping ("Waited 365 days", "Hold to open").
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize > 14 ? 16 : 12,
        vertical: fontSize > 14 ? 9 : 5,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: palette.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: palette.textPrimary,
        ),
      ),
    );
  }
}
