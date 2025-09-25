import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';

class SuggestedFriendRow extends StatefulWidget {
  final String userId;
  final String name;
  final String username;
  final Future<String?> avatarFuture;
  final VoidCallback onTapProfile;
  final VoidCallback onSendRequest;
  final VoidCallback onRemove;
  final bool isSent;
  final double screenWidth;
  final UserFriendsService requestService;
  final String currentUid;
  final VoidCallback? onStateChanged;

  const SuggestedFriendRow({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarFuture,
    required this.onTapProfile,
    required this.onSendRequest,
    required this.onRemove,
    required this.isSent,
    required this.screenWidth,
    required this.requestService,
    required this.currentUid,
    this.onStateChanged,
  });

  @override
  State<SuggestedFriendRow> createState() => _SuggestedFriendRowState();
}

class _SuggestedFriendRowState extends State<SuggestedFriendRow> {
  String? requestStatus;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRequestStatus();
  }

  @override
  void didUpdateWidget(SuggestedFriendRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.currentUid != widget.currentUid) {
      _checkRequestStatus();
    }
  }

  Future<void> _checkRequestStatus() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final status = await widget.requestService.getRequestStatus(
        widget.currentUid,
        widget.userId,
      );

      if (!mounted) return;

      setState(() {
        requestStatus = status;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _showRemoveModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 264,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remove from suggestions?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Irina',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This user will be removed from your search suggestions until the app restarts.',
                      //TODO: change the text until the app restarts for forever
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Irina',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 160,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 253, 65, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onRemove();
                        },
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Irina',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Color.fromARGB(255, 95, 95, 95),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Irina',
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.isSent || requestStatus == 'pending') {
      return Image.asset(
        'assets/images/icons/friends_page/pending.png',
        width: widget.screenWidth * 0.09,
        height: widget.screenWidth * 0.09,
      );
    }

    return GestureDetector(
      onTap: widget.onSendRequest,
      child: Image.asset(
        'assets/images/icons/prof_page/add_friend.png',
        width: widget.screenWidth * 0.09,
        height: widget.screenWidth * 0.09,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          if (!mounted) return;

          await _checkRequestStatus();

          if (!mounted) return;
          widget.onStateChanged?.call();
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: widget.onTapProfile,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.screenWidth * 0.02),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 0),
            leading: FutureBuilder<String?>(
              future: widget.avatarFuture,
              builder: (context, snapshot) {
                ImageProvider avatar;
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  avatar = NetworkImage(snapshot.data!);
                } else {
                  avatar = AssetImage(
                    'assets/images/icons/navbar/icon-profile.png',
                  );
                }
                return CircleAvatar(
                  radius: widget.screenWidth * 0.07,
                  backgroundImage: avatar,
                  backgroundColor: Colors.grey[200],
                );
              },
            ),
            title: Text(
              widget.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.screenWidth * 0.045,
                fontFamily: 'Irina',
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              '@${widget.username}',
              style: TextStyle(
                fontSize: widget.screenWidth * 0.040,
                fontFamily: 'Irina',
                color: Color.fromARGB(255, 94, 94, 94),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _showRemoveModal,
                  child: Image.asset(
                    'assets/images/icons/friends_page/delete_reset.png',
                    width: widget.screenWidth * 0.07,
                    height: widget.screenWidth * 0.07,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
