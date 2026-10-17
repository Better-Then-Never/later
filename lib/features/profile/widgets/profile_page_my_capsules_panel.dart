import 'package:flutter/material.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/buttons/default_text_button.dart';
import 'package:later/shared/widgets/profile_page_divider.dart';
import 'package:later/core/l10n/l10n.dart';

class ProfilePageMyCapsulesPanel extends StatelessWidget {
  const ProfilePageMyCapsulesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: DefaultText(
            l10n.profileMyCapsules,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: screenWidth - 32,
          // Two 44 dp rows and the line between them (D-24).
          height: 89,
          decoration: BoxDecorations.whiteCard(context),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppIcons.profileMyCapsules),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 65,
                top: 0,
                right: 20,
                child: SizedBox(
                  height: 44,
                  child: DefaultTextButton(
                    onTap: () {
                      AppRoutes.toCamera(
                        context,
                        privacy: CapsulePrivacy.friends,
                      );
                    },
                    text: l10n.profileAddToMapFriends,
                  ),
                ),
              ),

              Positioned(
                left: 65,
                top: 44,
                right: 20,
                child: ProfilePageDivider(width: screenWidth - 32),
              ),

              Positioned(
                left: 65,
                bottom: 0,
                right: 20,
                child: SizedBox(
                  height: 44,
                  child: DefaultTextButton(
                    onTap: () {
                      AppRoutes.toCamera(
                        context,
                        privacy: CapsulePrivacy.public,
                      );
                    },
                    text: l10n.profileAddToMapEveryone,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
