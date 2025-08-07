import 'package:flutter/material.dart';
import 'package:later/firebase_options.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/pages/login_page.dart';
import 'package:later/views/widget_tree.dart';
import 'package:later/views/pages/welcome_page.dart';
import 'package:later/views/pages/camera_page.dart';
import 'package:later/views/pages/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
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
        '/widgetTree': (context) => const WidgetTree(),
        '/welcome': (context) => const WelcomePage(),
        '/camera': (context) => const CameraPage(),
        '/loginPage': (context) => const LoginPage(),
        '/signupPage': (context) => const SignupPage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return snapshot.hasData ? const WidgetTree() : const WelcomePage();
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
