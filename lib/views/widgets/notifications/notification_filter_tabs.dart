import 'package:flutter/material.dart';

class NotificationFilterTabs extends StatelessWidget {
  final TabController controller;
  
  const NotificationFilterTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> filters = ['All', 'Replies', 'Comments'];
    
    return Center(
      child: IntrinsicWidth(
        child: TabBar(
          controller: controller,
          isScrollable: false,
          indicator: BoxDecoration(
            color: const Color.fromARGB(255, 86, 201, 46),
            borderRadius: BorderRadius.circular(25),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          padding: EdgeInsets.zero,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          tabs: filters.map((filter) {
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}