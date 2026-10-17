import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/friends/pinned_friends_controller.dart';
import 'package:later/shared/widgets/buttons/default_text_button.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/features/profile/widgets/pinned_friends/pinned_friends_row.dart';
import 'package:later/shared/widgets/profile_page_divider.dart';
import 'package:provider/provider.dart';

class ProfilePageMyFriendsPanel extends StatelessWidget {
  final String currentUserUid;
  final double screenWidth;

  const ProfilePageMyFriendsPanel({
    super.key,
    required this.currentUserUid,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final edge = BorderSide(color: palette.cardBorder);
    return Stack(
      children: [
        Container(
          width: screenWidth - 32,
          // Room for the section name above the friends (F-39).
          height: 176,
          decoration: BoxDecorations.whiteCard(context),
        ),

        // The section's name (F-39: the card had none).
        Positioned(
          top: 10,
          left: 18,
          child: Text(
            context.l10n.profileFriendsSection,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.textSecondary,
            ),
          ),
        ),

        Positioned(
          bottom: 35,
          left: 0,
          right: 0,
          child: ChangeNotifierProvider(
            create: (context) => PinnedFriendsController(
              friends: context.read<FriendsStore>(),
              prefs: context.read<PreferencesStore>(),
            ),
            child: const PinnedFriendsRow(),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: screenWidth - 32,
            height: 45,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              // This strip covers the bottom of the card: repeat the card's
              // dark-mode hairline edge so it does not stop halfway.
              border: palette.isDark
                  ? Border(left: edge, right: edge, bottom: edge)
                  : null,
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Row(
            children: [
              const SizedBox(width: 18),
              SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  AppIcons.profileMyFriends,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: screenWidth - 95,
                // A full tap target (D-24).
                height: 44,
                child: DefaultTextButton(
                  onTap: () => AppRoutes.toMyFriends(context),
                  text: context.l10n.profileMyFriends,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 45,
          left: 0,
          child: ProfilePageDivider(width: screenWidth - 32),
        ),
      ],
    );
  }
}
