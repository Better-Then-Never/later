import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareProfileQR extends StatelessWidget {
  final String profileLink;
  final double screenWidth;

  const ShareProfileQR({
    Key? key,
    required this.profileLink,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth * 0.75,
      height: screenWidth * 0.75,
      decoration: BoxDecorations.whiteCard(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: QrImageView(
          data: profileLink,
          version: QrVersions.auto,
          size: screenWidth * 0.55,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
          errorStateBuilder: (context, error) => Center(
            child: DefaultText("Something went wrong...", color: Colors.red),
          ),
        ),
      ),
    );
  }
}
