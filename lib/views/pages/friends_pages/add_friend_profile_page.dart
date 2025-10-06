import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/friends/add_friend_profile_controller.dart';
import 'package:later/views/pages/friends_pages/your_friend_profile_page.dart';
import 'package:later/views/widgets/add_friend_profile/add_friend_profile_action_button.dart';
import 'package:later/views/widgets/add_friend_profile/add_friend_profile_header.dart';
import 'package:later/views/widgets/user/user_name_and_username.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/sharing_service.dart';
import 'package:later/services/user_data_service.dart';

class AddFriendProfilePage extends StatefulWidget {
  final String userId;
  final VoidCallback? onStateChanged;

  const AddFriendProfilePage({
    super.key,
    required this.userId,
    this.onStateChanged,
  });

  @override
  State<AddFriendProfilePage> createState() => _AddFriendProfilePageState();
}

class _AddFriendProfilePageState extends State<AddFriendProfilePage> {
  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddFriendProfileController(
        userId: widget.userId,
        requestService: Provider.of<UserFriendsService>(context, listen: false),
        userService: Provider.of<UserDataService>(context, listen: false),
        onNavigateToFriendProfile: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 10),
              reverseDuration: const Duration(milliseconds: 10),
              child: YourFriendProfilePage(friendUid: widget.userId),
            ),
          );
        },
      ),
      child: Consumer<AddFriendProfileController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F6F6),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: Column(
                    children: [
                      AddFriendProfileHeader(
                        userId: widget.userId,
                        bgHeight: MediaQuery.of(context).size.height * 0.32,
                        avatarRadius: 100,
                        onBack: () => Navigator.of(context).pop(),
                        onShare: () => SharingService.shareUserProfile(
                          context: context,
                          userId: widget.userId,
                        ),
                      ),
                      SizedBox(height: 110),
                      UserNameAndUsername(
                        userId: widget.userId,
                        crossAxisAlignment: CrossAxisAlignment.center,
                      ),
                    ],
                  ),
                ),
                AddFriendProfileActionButton(
                  isLoading: controller.isLoading,
                  isCancelling: controller.isCancelling,
                  onCancel: () => controller.cancelFriendRequest(context),
                  onAction: () => controller.handleButtonPress(context),
                  buttonState: controller.buttonState,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
