import 'package:flutter/material.dart';
import 'package:later/app/router/app_link_handler.dart';
import 'package:later/features/notifications/notification_router.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/views/pages/core_pages/widget_tree.dart';
import 'package:provider/provider.dart';

/// Home shell of a signed-in user. Only built by the AuthGate while a user is
/// signed in, so the session uid is always available here.
class WidgetTreeWrapper extends StatefulWidget {
  const WidgetTreeWrapper({super.key});

  @override
  State<WidgetTreeWrapper> createState() => _WidgetTreeWrapperState();
}

class _WidgetTreeWrapperState extends State<WidgetTreeWrapper> {
  late final AppLinkHandler _links;
  late final NotificationRouter _notificationRouter;

  @override
  void initState() {
    super.initState();
    selectedPageNotifier.value = 0;

    _links = context.read<AppLinkHandler>();
    _notificationRouter = context.read<NotificationRouter>();
    // Pending deep links open once the home screen is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _links.onHomeReady();
      _notificationRouter.onHomeReady();
    });
  }

  @override
  void dispose() {
    _links.onHomeGone();
    _notificationRouter.onHomeGone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const WidgetTree();
  }
}
