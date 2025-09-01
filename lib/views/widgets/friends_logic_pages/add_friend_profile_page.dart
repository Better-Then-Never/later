import 'package:flutter/material.dart';
import 'package:later/views/widgets/friends_logic_pages/your_friend_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:later/services/profile_friends/friend_request.dart';
import 'package:later/services/profile_friends/user_data_services.dart';
import 'package:later/services/cache_firebase/firebase_storage_services.dart';
import 'package:later/services/appearance/notification_system.dart';
import 'package:later/services/appearance/widget_factory.dart';

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
  bool _isLoading = false;
  bool _isCancelling = false;
  String _buttonState = 'add'; 
  final FriendRequestService _requestService = FriendRequestService();

  @override
  void initState() {
    super.initState();
    _checkRelationshipStatus();
  }

  @override
  void dispose() {
    UnifiedNotification.hide(); 
    super.dispose();
  }

  Future<void> _checkRelationshipStatus() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final currentUserUid = userService.uid;

      if (currentUserUid != null) {
        final areFriends = await _requestService.areFriends(
          currentUserUid,
          widget.userId,
        );
        if (areFriends) {
          setState(() => _buttonState = 'friends');
          return;
        }

        final requestExists = await _requestService.requestExists(
          currentUserUid,
          widget.userId,
        );
        setState(() => _buttonState = requestExists ? 'pending' : 'add');
      }
    } catch (e) {
      setState(() => _buttonState = 'add');
    }
  }

    Future<void> _handleButtonPress() async {
    if (_buttonState == 'friends') {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YourFriendProfilePage(friendUid: widget.userId),
          ),
        );
      }
      return;
    }

    if (_buttonState == 'pending') {
      if (context.mounted) {
        UnifiedNotification.showInfo(
          context: context,
          message: 'Friend request is pending',
          position: NotificationPosition.center,
        );
      }
      return;
    }

    if (_buttonState == 'pending') {
      if (context.mounted) {
        UnifiedNotification.showInfo(
          context: context,
          message: 'Friend request is pending',
          position: NotificationPosition.center,
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userService = Provider.of<UserService>(context, listen: false);

      final requestExists = await _requestService.requestExists(
        userService.uid!,
        widget.userId,
      );

      if (requestExists) {
        if (mounted) {
          setState(() => _buttonState = 'pending');
          widget.onStateChanged?.call();

          if (context.mounted) {
            UnifiedNotification.showInfo(
              context: context,
              message: 'Friend request already exists',
              position: NotificationPosition.center,
            );
          }
        }
        return;
      }

      await _requestService.sendFriendRequest(userService.uid!, widget.userId);

      if (mounted) {
        setState(() => _buttonState = 'pending');
        widget.onStateChanged?.call();

        if (context.mounted) {
          UnifiedNotification.showSuccess(
            context: context,
            message: 'Friend request sent!',
            position: NotificationPosition.center,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UnifiedNotification.showError(
          context: context,
          message: 'Failed to send friend request',
          position: NotificationPosition.center,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelFriendRequest() async {
    setState(() => _isCancelling = true);

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      
      await _requestService.cancelFriendRequest(userService.uid!, widget.userId);

      if (mounted) {
        setState(() => _buttonState = 'add');
        widget.onStateChanged?.call();
        UnifiedNotification.showInfo(
          context: context,
          message: 'Friend request cancelled',
          position: NotificationPosition.center,
        );
      }
    } catch (e) {
      if (mounted) {
        UnifiedNotification.showError(
          context: context,
          message: 'Failed to cancel request',
          position: NotificationPosition.center,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  String _getButtonText() {
    switch (_buttonState) {
      case 'pending':
        return 'Pending';
      case 'friends':
        return 'View Profile';
      default:
        return 'Add';
    }
  }

  Color _getButtonColor() {
    switch (_buttonState) {
      case 'pending':
        return Color.fromARGB(255, 253, 219, 7);
      case 'friends':
        return const Color.fromARGB(255, 54, 144, 255);
      default:
        return const Color.fromARGB(255, 86, 201, 46);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double bgHeight = screenHeight * 0.32;
    final double avatarRadius = 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: screenHeight * 0.45),
            child: Column(
              children: [
                _buildHeaderSection(screenWidth, bgHeight, avatarRadius),
                SizedBox(height: 110),
                _buildUserInfo(),
              ],
            ),
          ),
          _buildActionButtons(screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    double screenWidth,
    double bgHeight,
    double avatarRadius,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildBackgroundImage(screenWidth, bgHeight),
        _buildShadowOverlay(screenWidth),
        _buildNavigationButtons(),
        _buildProfileAvatar(screenWidth, bgHeight, avatarRadius),
      ],
    );
  }

  Widget _buildBackgroundImage(double screenWidth, double bgHeight) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(25),
        bottomRight: Radius.circular(25),
      ),
      child: SizedBox(
        width: screenWidth,
        height: bgHeight,
        child: FutureBuilder<String?>(
          future: FirebaseStorageService.getBackgroundImageUrl(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return WidgetFactory.buildLoadingContainer(
                width: screenWidth,
                height: bgHeight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              return Image.network(
                snapshot.data!,
                width: screenWidth,
                height: bgHeight,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return WidgetFactory.buildLoadingContainer(
                    width: screenWidth,
                    height: bgHeight,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey[500],
                    ),
                  );
                },
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShadowOverlay(double screenWidth) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        width: screenWidth,
        height: 1,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              spreadRadius: 60,
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned(
      top: 32,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Image.asset(
              'assets/images/icons/prof_page/go_back_circle.png',
              width: 44,
              height: 44,
            ),
          ),
          Image.asset(
            'assets/images/icons/prof_page/share_button.png',
            width: 44,
            height: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    double screenWidth,
    double bgHeight,
    double avatarRadius,
  ) {
    return Positioned(
      top: bgHeight - avatarRadius,
      left: (screenWidth - avatarRadius * 2) / 2,
      child: Material(
        elevation: 8,
        shape: const CircleBorder(),
        child: FutureBuilder<String?>(
          future: FirebaseStorageService.getOriginalProfileImageUrl(
            widget.userId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return WidgetFactory.buildLoadingContainer(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                borderRadius: BorderRadius.circular(avatarRadius),
              );
            }

            return WidgetFactory.buildUserAvatar(
              imageUrl: snapshot.data,
              radius: avatarRadius,
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return FutureBuilder<Map<String, String>>(
      future: UserDataService.getUserNameAndUsername(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              WidgetFactory.buildLoadingContainer(
                width: 120,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
              SizedBox(height: 8),
              WidgetFactory.buildLoadingContainer(
                width: 80,
                height: 22,
                borderRadius: BorderRadius.circular(11),
              ),
            ],
          );
        }

        final name = snapshot.data?['name'] ?? 'Unknown User';
        final username = snapshot.data?['username'] ?? 'unknown';

        return Column(
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 22,
                color: Color.fromARGB(255, 94, 94, 94),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(double screenWidth, double screenHeight) {
    return Stack(
      children: [
        if (_buttonState != 'pending')
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: screenHeight * 0.1,
            child: _buildMainActionButton(screenWidth, screenHeight),
          ),
        if (_buttonState == 'pending')
          Positioned(
            left: screenWidth * 0.25,
            right: screenWidth * 0.25,
            bottom: screenHeight * 0.1,
            child: _buildCancelButton(screenWidth, screenHeight),
          ),
      ],
    );
  }

  Widget _buildMainActionButton(double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      child: SizedBox(
        width: screenWidth * 0.73,
        height: screenHeight * 0.06,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _handleButtonPress,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _getButtonText(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.065,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      child: SizedBox(
        width: screenWidth * 0.5,
        height: screenHeight * 0.05,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          onPressed: _isCancelling ? null : _cancelFriendRequest,
          child: _isCancelling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Cancel Request',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}