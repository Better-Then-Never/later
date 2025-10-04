import 'package:flutter/material.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:provider/provider.dart';

class UserNameAndUsername extends StatelessWidget {
  final String userId;

  final TextAlign textAlign;
  final double nameFontSize;
  final double usernameFontSize;
  final Color nameColor;
  final Color usernameColor;
  final FontWeight nameFontWeight;
  final FontWeight usernameFontWeight;
  final CrossAxisAlignment crossAxisAlignment;

  const UserNameAndUsername({
    super.key,
    required this.userId,
    this.textAlign = TextAlign.center,
    this.nameFontSize = 32,
    this.usernameFontSize = 22,
    this.nameColor = Colors.black,
    this.usernameColor = const Color.fromARGB(255, 94, 94, 94),
    this.nameFontWeight = FontWeight.bold,
    this.usernameFontWeight = FontWeight.bold,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

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
          crossAxisAlignment: crossAxisAlignment,
          children: [
            isLoading
                ? Center()
                : DefaultText(
                    name,
                    fontSize: nameFontSize,
                    fontWeight: nameFontWeight,
                    color: nameColor,
                    textAlign: textAlign,
                    height: 1.0,
                  ),
            isLoading
                ? Center()
                : DefaultText(
                    '@$username',
                    fontSize: usernameFontSize,
                    color: usernameColor,
                    fontWeight: usernameFontWeight,
                    textAlign: textAlign,
                  ),
          ],
        );
      },
    );
  }
}
