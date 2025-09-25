import 'package:flutter/material.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/_common/default_elements/default_loading_container.dart';
import 'package:provider/provider.dart';

class AddFriendProfileUserInfo extends StatelessWidget {
  final String userId;

  const AddFriendProfileUserInfo({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: Provider.of<UserDataService>(
        context,
        listen: false,
      ).getUserData(userId),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final name = snapshot.data?['name'] ?? 'Unknown User';
        final username = snapshot.data?['username'] ?? 'unknown';

        return Column(
          children: [
            isLoading
                ? const DefaultLoadingContainer(
                    width: 120,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  )
                : Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
            const SizedBox(height: 8),
            isLoading
                ? const DefaultLoadingContainer(
                    width: 80,
                    height: 22,
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                  )
                : Text(
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
}
