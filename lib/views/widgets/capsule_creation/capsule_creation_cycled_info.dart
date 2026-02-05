import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class CapsuleCreationCycledInfo extends StatelessWidget {
  final String infoText;
  final String? trailingLeadingIconPath;

  const CapsuleCreationCycledInfo({
    Key? key,
    required this.infoText,
    this.trailingLeadingIconPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Container(
        decoration: BoxDecorations.defaultBorderRadius(
          color: const Color.fromARGB(217, 217, 217, 217),
        ),
        width: screenWidth * 0.4,
        alignment: Alignment.centerRight,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  DefaultText(
                    infoText,
                    fontSize: 35,
                    color: const Color.fromARGB(255, 106, 106, 106),
                  ),
                  if (trailingLeadingIconPath != null) const SizedBox(width: 8),
                  if (trailingLeadingIconPath != null)
                    Image.asset(
                      trailingLeadingIconPath!,
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
