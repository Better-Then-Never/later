import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:later/firebase_options.dart';
import 'package:later/services/capsule_data_service.dart';
import 'package:later/services/chat_service.dart';
import 'package:later/services/firebase_auth_service.dart';
import 'package:later/services/map_capsule_jump_service.dart';
import 'package:later/services/user_favorite_capsules_service.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_image_service.dart';
import 'package:later/views/pages/auth_pages/login_page.dart';
import 'package:later/views/pages/friends_pages/add_friends_page.dart';
import 'package:later/views/pages/friends_pages/my_friends_page.dart';
import 'package:later/views/pages/auth_pages/welcome_page.dart';
import 'package:later/views/pages/navbar_pages/camera_page.dart';
import 'package:later/views/pages/auth_pages/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/core_pages/settings_page.dart';
import 'package:later/views/pages/core_pages/notifications_page.dart';
import 'package:later/views/pages/core_pages/share_profile_page.dart';
import 'package:later/views/pages/navbar_pages/profile_page.dart';
import 'package:later/views/pages/settings_pages/name_settings_page.dart';
import 'package:later/views/pages/core_pages/widget_tree_wrapper_page.dart';
import 'package:later/services/deep_link_service.dart';
import 'package:later/views/pages/auth_pages/permission_gate_page.dart';
import 'package:later/services/user_data_service.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final userImageService = UserImageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FirebaseAuthService()),
        ChangeNotifierProvider(create: (_) => UserDataService()),
        ChangeNotifierProvider(create: (_) => UserFriendsService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => CapsuleDataService()),
        ChangeNotifierProvider(create: (_) => FavoriteCapsuleService()),
        ChangeNotifierProvider(create: (_) => CapsuleJumpService()),
        ChangeNotifierProvider.value(value: userImageService),
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
      DeepLinkService.handleDeepLink(navigatorKey.currentContext!, link);
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        if (navigatorKey.currentContext != null) {
          DeepLinkService.handleDeepLink(navigatorKey.currentContext!, link);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox(),
            IgnorePointer(
              child: SnowFallAnimation(
                config: SnowfallConfig(
                  numberOfSnowflakes: 15,
                  speed: 0.5,
                  useEmoji: true,
                  customEmojis: ['❄️', '❅', '❆'],
                ),
              ),
            ),
          ],
        );
      },
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
