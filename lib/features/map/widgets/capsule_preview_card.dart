import 'package:flutter/material.dart';
import 'package:later/shared/widgets/app_network_image.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../shared/widgets/capsule/capsule_date_pill.dart';
import '../../../shared/widgets/capsule/capsule_place_pill.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../core/theme/app_palette.dart';

/// Dialog content showing an opened capsule: photo, title, description,
/// place and creation date. Tapping the place calls [onPlaceTap]; tapping
/// the photo shows it full screen.
class CapsulePreviewCard extends StatelessWidget {
  const CapsulePreviewCard({super.key, required this.capsule, this.onPlaceTap});

  final Capsule capsule;
  final VoidCallback? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final imageUrl = capsule.imageUrl;

    return Container(
      width: screen.width,
      height: screen.height * 0.45,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadii.lCircular,
        boxShadow: AppShadows.raised(context),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (imageUrl != null)
            SizedBox(
              width: screen.width * 0.45,
              height: double.infinity,
              child: GestureDetector(
                onTap: () => PhotoViewer.show(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  child: AppNetworkImage(url: imageUrl),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: screen.width * 0.05,
                    fontWeight: FontWeight.bold,
                    fontFamily: kAppFontFamily,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      capsule.description ??
                          context.l10n.mapCapsuleNoDescription,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: kAppFontFamily,
                        color: context.palette.textFaint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: capsule.location == null ? null : onPlaceTap,
                  child: CapsulePlacePill(
                    height: screen.height * 0.05,
                    iconPath: AppIcons.capsuleLocation,
                    position: capsule.location,
                  ),
                ),
                const SizedBox(height: 8),
                CapsuleDatePill(
                  height: screen.height * 0.05,
                  date: capsule.createdAt,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
