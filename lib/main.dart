import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:later/firebase_options.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/pages/auth_pages/login_page.dart';
import 'package:later/views/pages/friends_pages/add_friends_page.dart';
import 'package:later/views/pages/friends_pages/my_friends_page.dart';
import 'package:later/views/pages/auth_pages/welcome_page.dart';
import 'package:later/views/pages/tree_pages/camera_page.dart';
import 'package:later/views/pages/auth_pages/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/core_pages/settings_page.dart';
import 'package:later/views/pages/core_pages/notifications_page.dart';
import 'package:later/views/pages/core_pages/share_profile_page.dart';
import 'package:later/views/pages/tree_pages/profile_page.dart';
import 'package:later/views/pages/options_settings_pages/name_changing_page.dart';
import 'package:later/views/pages/core_pages/widget_tree_wrapper_page.dart';
import 'package:later/services/cache_firebase/firebase_user_services.dart';
import 'package:later/services/cache_firebase/deep_link_handler.dart';
import 'package:later/views/pages/auth_pages/permission_gate_page.dart';
import 'package:later/services/user_profile_data_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => FirebaseUserService()),
        ChangeNotifierProvider(create: (_) => UserProfileService()),
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
        '/camera': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return CameraPage(arguments: args);
        },
        '/loginPage': (context) => const LoginPage(),
        '/signupPage': (context) => const SignupPage(),
        '/settingsPage': (context) => const SettingsPage(),
        '/notificationsPage': (context) => const NotificationsPage(),
        '/sharePage': (context) => const ShareProfilePage(),
        '/profile_page': (context) => const ProfilePage(),
        '/nameChangingWidget': (context) => const NameSettingsPage(),
        '/addFriendsPage': (context) => const AddFriendsPage(),
        '/myFriendsPage': (context) => const MyFriendsPage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData) {
            return const WelcomePage();
          }

          return PermissionGatePage(
            onAllGranted: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WidgetTreeWrapper()),
              );
            },
          );
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
