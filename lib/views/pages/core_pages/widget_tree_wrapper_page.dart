import 'package:flutter/material.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_image_service.dart';
import 'package:later/views/pages/core_pages/widget_tree.dart';
import 'package:later/services/user_data_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WidgetTreeWrapper extends StatefulWidget {
  const WidgetTreeWrapper({super.key});

  @override
  State<WidgetTreeWrapper> createState() => _WidgetTreeWrapperState();
}

class _WidgetTreeWrapperState extends State<WidgetTreeWrapper> {
  bool _preloaded = false;

  @override
  void initState() {
    super.initState();
    selectedPageNotifier.value = 0;

    final userProfileService = context.read<UserDataService>();
    final userFriendsService = context.read<UserFriendsService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    userProfileService.getCurrentUserProfile(uid!);
    userFriendsService.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_preloaded) {
      _preloaded = true;

      final userImageService = context.read<UserImageService>();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      userImageService.preloadBackgroundImageForUser(uid, context);
      userImageService.preloadProfileImageForUser(uid, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const WidgetTree();
  }
}
