import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/services/geocoding_service.dart';

/// Yellow pill with the place name of a capsule + round icon on the right.
///
/// The place is looked up once per position (cached by [GeocodingService])
/// instead of on every rebuild, so the pill no longer flashes "Loading...".
class CapsulePlacePill extends StatefulWidget {
  const CapsulePlacePill({
    super.key,
    required this.height,
    required this.iconPath,
    this.position,
  });

  final double height;
  final String iconPath;
  final GeoPosition? position;

  @override
  State<CapsulePlacePill> createState() => _CapsulePlacePillState();
}

class _CapsulePlacePillState extends State<CapsulePlacePill> {
  Future<String>? _label;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _label ??= _lookup();
  }

  @override
  void didUpdateWidget(CapsulePlacePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) _label = _lookup();
  }

  Future<String> _lookup() async {
    final position = widget.position;
    if (position == null) return 'No location';
    final name = await context.read<GeocodingService>().placeName(position);
    return name ?? 'Unknown location';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: widget.height,
            decoration: const BoxDecoration(
              color: AppColors.placeYellow,
              borderRadius: AppRadii.lCircular,
            ),
            child: Center(
              child: FutureBuilder<String>(
                future: _label,
                builder: (context, snapshot) => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      snapshot.data ?? 'Loading...',
                      style: AppTextStyles.pill,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: widget.height,
          width: widget.height,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(widget.iconPath),
        ),
      ],
    );
  }
}
