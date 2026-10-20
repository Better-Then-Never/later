import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/services/geocoding_service.dart';
import '../../motion/app_motion_widgets.dart';

/// The small yellow place pill next to a capsule's title (capsule v3): the
/// place it was left, from the capsule or looked up once; a tap shows it on
/// the map ([onTap]).
class CapsulePlaceChip extends StatefulWidget {
  CapsulePlaceChip({super.key, required Capsule capsule, this.onTap})
    : position = capsule.location,
      placeName = capsule.placeName,
      label = null;

  /// The place of a capsule being made: always shown ("No location" too),
  /// as a tap on it moves the pin; [label] names the tap for screen readers.
  const CapsulePlaceChip.at({
    super.key,
    required this.position,
    required this.onTap,
    required String this.label,
  }) : placeName = null;

  final GeoPosition? position;
  final String? placeName;
  final VoidCallback? onTap;
  final String? label;

  bool get _always => label != null;

  @override
  State<CapsulePlaceChip> createState() => _CapsulePlaceChipState();
}

class _CapsulePlaceChipState extends State<CapsulePlaceChip> {
  Future<String?>? _name;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _name ??= _lookup();
  }

  @override
  void didUpdateWidget(CapsulePlaceChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position ||
        oldWidget.placeName != widget.placeName) {
      _name = _lookup();
    }
  }

  Future<String?> _lookup() async {
    final known = widget.placeName;
    if (known != null && known.isNotEmpty) return known;
    final position = widget.position;
    final l10n = context.l10n;
    if (position == null) return widget._always ? l10n.placeNoLocation : null;
    final name = await context.read<GeocodingService>().placeName(position);
    return name ?? (widget._always ? l10n.placeUnknown : null);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _name,
    builder: (context, snapshot) {
      final name =
          snapshot.data ?? (widget._always ? context.l10n.commonLoading : null);
      if (name == null || name.isEmpty) return const SizedBox.shrink();
      final chip = Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          color: AppColors.placeYellow,
          borderRadius: AppRadii.lCircular,
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.onAccent,
          ),
        ),
      );
      final onTap = widget.onTap;
      if (onTap == null) return chip;
      return Semantics(
        button: true,
        label: widget.label ?? context.l10n.capsulesShowOnMap,
        child: AppPressable(
          child: GestureDetector(onTap: onTap, child: chip),
        ),
      );
    },
  );
}
