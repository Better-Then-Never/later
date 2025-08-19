import 'package:flutter/material.dart';
import 'package:later/data/models/time_capsule.dart';

class CapsulePrivacyDropdown extends StatelessWidget {
  final CapsulePrivacy value;
  final ValueChanged<CapsulePrivacy> onChanged;

  const CapsulePrivacyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<CapsulePrivacy>(
      value: value,
      items: CapsulePrivacy.values
          .map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text(p.toString().split('.').last.toUpperCase()),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          onChanged(v);
        }
      },
    );
  }
}
