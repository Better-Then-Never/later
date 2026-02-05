import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:later/services/deep_link_service.dart';
import 'package:later/views/pages/friends_pages/add_friend_profile_page.dart';
import 'package:page_transition/page_transition.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  static Future<void> open(BuildContext context) async {
    final result = await Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 10),
        reverseDuration: const Duration(milliseconds: 10),
        child: QRScannerPage(),
      ),
    );

    if (result != null && result is String) {
      if (DeepLinkService.isLaterDeepLink(result)) {
        final userId = DeepLinkService.extractUserIdFromLink(result);
        if (userId != null && context.mounted) {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 10),
              reverseDuration: const Duration(milliseconds: 10),
              child: AddFriendProfilePage(userId: userId),
            ),
          );
        }
      }
    }
  }

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _isTorchEnabled = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanning && capture.barcodes.isNotEmpty) {
      final String? scannedData = capture.barcodes.first.rawValue;

      if (scannedData != null) {
        _isScanning = false;

        if (DeepLinkService.isLaterDeepLink(scannedData)) {
          Navigator.pop(context, scannedData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: DefaultText(
                'Invalid QR code. Please scan a Later profile QR code.',
                color: Colors.white,
              ),
              backgroundColor: Colors.red,
            ),
          );

          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isScanning = true;
              });
            }
          });
        }
      }
    }
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          _cameraBorderWithCutout(screenWidth),

          SafeArea(
            child: Container(
              height: 100,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GoBackButton(context: context, isBlack: false),
                  SizedBox(width: 16),
                  DefaultText(
                    'Scan QR Code',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              child: DefaultText(
                'Point your camera at the QR code to add a friend',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),

          Positioned(
            bottom: 200,
            right: 20,
            child: GestureDetector(
              onTap: () {
                cameraController.toggleTorch();
                setState(() {
                  _isTorchEnabled = !_isTorchEnabled;
                });
              },
              child: Container(
                width: 56,
                height: 56,
                child: Icon(
                  _isTorchEnabled ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _cameraBorderWithCutout(final double screenWidth) {
  return Container(
    decoration: ShapeDecoration(
      shape: QRScannerOverlayShape(
        borderColor: Colors.white,
        borderRadius: 20,
        borderLength: 30,
        borderWidth: 8,
        cutOutSize: screenWidth * 0.7,
      ),
    ),
  );
}

class QRScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QRScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path cutOut = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, cutOut);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > cutOutSize / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top + height / 2 - mCutOutSize / 2 + borderOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndCorners(
          cutOutRect,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();

    final path = Path()
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + mBorderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(
        cutOutRect.left - borderOffset,
        cutOutRect.top - borderOffset,
        cutOutRect.left + borderRadius,
        cutOutRect.top - borderOffset,
      )
      ..lineTo(cutOutRect.left + mBorderLength, cutOutRect.top - borderOffset);

    canvas.drawPath(path, borderPaint);

    final path2 = Path()
      ..moveTo(cutOutRect.right - mBorderLength, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top - borderOffset)
      ..quadraticBezierTo(
        cutOutRect.right + borderOffset,
        cutOutRect.top - borderOffset,
        cutOutRect.right + borderOffset,
        cutOutRect.top + borderRadius,
      )
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + mBorderLength);

    canvas.drawPath(path2, borderPaint);

    final path3 = Path()
      ..moveTo(
        cutOutRect.right + borderOffset,
        cutOutRect.bottom - mBorderLength,
      )
      ..lineTo(
        cutOutRect.right + borderOffset,
        cutOutRect.bottom - borderRadius,
      )
      ..quadraticBezierTo(
        cutOutRect.right + borderOffset,
        cutOutRect.bottom + borderOffset,
        cutOutRect.right - borderRadius,
        cutOutRect.bottom + borderOffset,
      )
      ..lineTo(
        cutOutRect.right - mBorderLength,
        cutOutRect.bottom + borderOffset,
      );

    canvas.drawPath(path3, borderPaint);

    final path4 = Path()
      ..moveTo(
        cutOutRect.left + mBorderLength,
        cutOutRect.bottom + borderOffset,
      )
      ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset)
      ..quadraticBezierTo(
        cutOutRect.left - borderOffset,
        cutOutRect.bottom + borderOffset,
        cutOutRect.left - borderOffset,
        cutOutRect.bottom - borderRadius,
      )
      ..lineTo(
        cutOutRect.left - borderOffset,
        cutOutRect.bottom - mBorderLength,
      );

    canvas.drawPath(path4, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QRScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
