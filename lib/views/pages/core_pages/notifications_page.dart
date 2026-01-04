import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/notifications/notification_filter_tabs.dart';
import 'package:later/views/widgets/notifications/notifications_list.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          PageHeader(
            mainText: 'Notifications',
            leadingButton: GoBackButton(context: context),
            actionButtonsRow: NotificationFilterTabs(
              controller: _tabController,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                NotificationsList(filterType: 'All'),
                NotificationsList(filterType: 'Replies'),
                NotificationsList(filterType: 'Comments'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}