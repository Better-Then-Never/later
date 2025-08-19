import 'package:flutter/material.dart';
import 'package:later/firebase_options.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/pages/login_page.dart';
import 'package:later/views/pages/welcome_page.dart';
import 'package:later/views/pages/camera_page.dart';
import 'package:later/views/pages/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/options_profile_page/settings_page.dart';
import 'package:later/views/pages/options_profile_page/notifications_page.dart';
import 'package:later/views/pages/options_profile_page/share_page.dart';
import 'package:later/views/pages/profile_page.dart';
import 'package:later/views/pages/options_settings_page/name_changing.dart';
import 'package:later/views/widget_tree_wrapper.dart';
import 'package:later/services/auth/user_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => UserService()),
      ],
      child: const Application(),
    ),
  );
}

class Application extends StatelessWidget {
  const Application({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/widgetTree': (context) => const WidgetTreeWrapper(),
        '/welcome': (context) => const WelcomePage(),
        '/camera': (context) => const CameraPage(),
        '/loginPage': (context) => const LoginPage(),
        '/signupPage': (context) => const SignupPage(),
        '/settingsPage': (context) => const SettingsPage(),
        '/notificationsPage': (context) => const NotificationsPage(),
        '/sharePage': (context) => const SharePage(),
        '/profile_page': (context) => const ProfilePage(),
        '/nameChangingWidget': (context) => const NameChangingWidget(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return snapshot.hasData
              ? const WidgetTreeWrapper()
              : const WelcomePage();
        },
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        fontFamily: "Irina",
      ),
    );
  }
}
