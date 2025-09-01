import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:later/firebase_options.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/pages/login_page.dart';
import 'package:later/views/pages/options_profile_page/add_friends_page.dart';
import 'package:later/views/pages/options_profile_page/my_friends_page.dart';
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
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:later/services/cache_firebase/deep_link_handler.dart';

// Add global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  static const platform = MethodChannel('later.app/deeplink');

  @override
  void initState() {
    super.initState();
    _setupDeepLinkHandling();
  }

  void _setupDeepLinkHandling() {
    // Set up method channel to receive deep links
    platform.setMethodCallHandler((call) async {
      if (call.method == 'handleDeepLink') {
        final String link = call.arguments as String;
        _handleIncomingLink(link);
      }
    });

    // Check for initial deep link
    _getInitialLink();
  }

  Future<void> _getInitialLink() async {
    try {
      final String? initialLink = await platform.invokeMethod('getInitialLink');
      if (initialLink != null) {
        // Delay handling to ensure app is fully initialized
        Future.delayed(Duration(seconds: 2), () {
          _handleIncomingLink(initialLink);
        });
      }
    } on PlatformException {
      // Handle error
    }
  }

  void _handleIncomingLink(String link) {
    if (navigatorKey.currentContext != null) {
      DeepLinkHandler.handleDeepLink(navigatorKey.currentContext!, link);
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        if (navigatorKey.currentContext != null) {
          DeepLinkHandler.handleDeepLink(navigatorKey.currentContext!, link);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
        '/addFriendsPage': (context) => const AddFriendsPage(),
        '/myFriendsPage': (context) => const MyFriendsPage(),
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