import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

/// Green pill showing a date as dd.MM.yyyy.
class CapsuleDatePill extends StatelessWidget {
  const CapsuleDatePill({
    super.key,
    required this.height,
    this.backgroundColor = AppColors.brandGreen,
    this.date,
  });

  final double height;
  final Color backgroundColor;

  /// Null while the server timestamp is pending: shown as today.
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.lCircular,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              DateFormat('dd.MM.yyyy').format(date ?? DateTime.now()),
              style: AppTextStyles.pill,
            ),
          ),
        ),
      ),
    );
  }
}
