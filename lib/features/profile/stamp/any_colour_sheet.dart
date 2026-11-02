import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/preferences_store.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../../shared/widgets/user/profile_stamp.dart';

/// "Any colour" (Figma page 13, Round 5): shade and light in a box, the hue
/// on a slider, the colour as a code, recent picks, and a stamp to preview.
/// Returns the colour as 0xAARRGGBB, or null.
class AnyColourSheet extends StatefulWidget {
  const AnyColourSheet({super.key, this.initial, required this.shape});

  final int? initial;
  final StampShape shape;

  static const _recentKey = 'stamp_recent_colours';

  static Future<int?> show(
    BuildContext context, {
    int? initial,
    required StampShape shape,
  }) => showEdgeSheet<int>(
    context,
    (_) => AnyColourSheet(initial: initial, shape: shape),
  );

  /// The hues, for the slider and the "Any colour" swatch.
  static Gradient rainbow({bool sweep = false}) {
    final colors = [
      for (var h = 0; h <= 360; h += 60)
        HSVColor.fromAHSV(1, h.toDouble() % 360, 0.85, 1).toColor(),
    ];
    return sweep
        ? SweepGradient(colors: colors)
        : LinearGradient(colors: colors);
  }

  @override
  State<AnyColourSheet> createState() => _AnyColourSheetState();
}

class _AnyColourSheetState extends State<AnyColourSheet> {
  /// Where the picker starts without a colour: the teal of the design.
  static const _start = 0xFF2A998F;

  late HSVColor _hsv = HSVColor.fromColor(Color(widget.initial ?? _start));
  final _hex = TextEditingController();
  List<int> _recent = const [];

  @override
  void initState() {
    super.initState();
    _hex.text = _code;
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    final raw = await context.read<PreferencesStore>().string(
      uid,
      AnyColourSheet._recentKey,
    );
    if (raw == null || !mounted) return;
    setState(() {
      _recent = [
        for (final s in raw.split(','))
          if (int.tryParse(s, radix: 16) case final v?) 0xFF000000 | v,
      ];
    });
  }

  Future<void> _remember(int argb) async {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    final list = [argb, ..._recent.where((c) => c != argb)].take(6);
    await context.read<PreferencesStore>().setString(
      uid,
      AnyColourSheet._recentKey,
      list.map((c) => (c & 0xFFFFFF).toRadixString(16)).join(','),
    );
  }

  int get _argb => _hsv.toColor().toARGB32();

  String get _code => StampColor.custom(_argb).value;

  void _set(HSVColor hsv) {
    setState(() => _hsv = hsv);
    _hex.text = _code;
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final first = context.select<SessionController, String>(
      (s) => (s.profile?.name ?? '').split(' ').first.toLowerCase(),
    );
    final initial = context.select<SessionController, String>(
      (s) => s.profile?.initial ?? '',
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SheetHandle.v2()),
              Text(
                l10n.stampColourAny,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: palette.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _ShadeBox(hsv: _hsv, onChanged: _set),
                        const SizedBox(height: 16),
                        _HueSlider(hsv: _hsv, onChanged: _set),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      ProfileStamp(
                        style: ProfileStampStyle(
                          shape: widget.shape,
                          color: StampColor.custom(_argb),
                        ),
                        size: 84,
                        initial: initial,
                        caption: first,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.stampPreview,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _hex,
                      maxLength: 7,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[#0-9A-Fa-f]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.stampColourHex,
                        counterText: '',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                      onChanged: (s) {
                        final c = StampColor.parse(
                          s.startsWith('#') ? s : '#$s',
                        );
                        if (c.isCustom) {
                          setState(
                            () => _hsv = HSVColor.fromColor(Color(c.argb!)),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_recent.isNotEmpty) ...[
                    Text(
                      l10n.stampColourRecent,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (final c in _recent.take(4))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Semantics(
                          button: true,
                          label: StampColor.custom(c).value,
                          child: GestureDetector(
                            onTap: () => _set(HSVColor.fromColor(Color(c))),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: Border.all(color: palette.divider),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PillV2(
                  label: l10n.stampDone,
                  onTap: () async {
                    final argb = _argb;
                    await _remember(argb);
                    if (context.mounted) Navigator.pop(context, argb);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saturation left to right, brightness top to bottom, for the current hue.
class _ShadeBox extends StatelessWidget {
  const _ShadeBox({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        const h = 170.0;
        void at(Offset p) => onChanged(
          hsv
              .withSaturation((p.dx / w).clamp(0.0, 1.0))
              .withValue(1 - (p.dy / h).clamp(0.0, 1.0)),
        );
        return GestureDetector(
          onPanDown: (d) => at(d.localPosition),
          onPanUpdate: (d) => at(d.localPosition),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                      ),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.onAccent, Colors.transparent],
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.mediaBlack,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: hsv.saturation * w - 11,
                  top: (1 - hsv.value) * h - 11,
                  child: _Knob(color: hsv.toColor()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        void at(double x) =>
            onChanged(hsv.withHue((x / w).clamp(0.0, 1.0) * 359.9));
        return GestureDetector(
          onPanDown: (d) => at(d.localPosition.dx),
          onPanUpdate: (d) => at(d.localPosition.dx),
          child: SizedBox(
            width: w,
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: AnyColourSheet.rainbow(),
                  ),
                ),
                Positioned(
                  left: hsv.hue / 360 * w - 11,
                  child: _Knob(
                    color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.onAccent, width: 3),
      boxShadow: const [
        BoxShadow(
          color: AppColors.passportShadow,
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    ),
  );
}
