import 'package:flutter/material.dart';
import 'package:later/data/notifiers.dart';
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
  final userProfileService = UserDataService();

  @override
  void initState() {
    super.initState();
    selectedPageNotifier.value = 0;

    final userProfileService = context.read<UserDataService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      userProfileService.getCurrentUserProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const WidgetTree();
  }
}
