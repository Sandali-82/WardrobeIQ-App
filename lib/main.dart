import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'services/http_api_service.dart';
import 'services/notification_service.dart';
import 'services/deep_link_service.dart';
import 'screens/login_screen.dart';
import 'screens/startup_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Shared with DeepLinkService so it can navigate (e.g. to Home once an
  // email confirmation link is handled) without needing its own
  // BuildContext.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Several requests can fail with an expired session at the same time
  // (e.g. every tab loading at once). This makes sure we only navigate once.
  bool _handlingExpiredSession = false;

  @override
  void initState() {
    super.initState();
    DeepLinkService.init(_navigatorKey);
    HttpApiService.onSessionExpired = _handleExpiredSession;
  }

  @override
  void dispose() {
    HttpApiService.onSessionExpired = null;
    DeepLinkService.dispose();
    super.dispose();
  }

  void _handleExpiredSession() {
    if (_handlingExpiredSession) return;
    _handlingExpiredSession = true;

    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      // Show the reason once the login screen is on screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your session has expired. Please log in again.')),
          );
        }
      });
    }

    // Allow the handler to run again after the redirect has settled.
    Future.delayed(const Duration(seconds: 2), () => _handlingExpiredSession = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'WardrobeIQ',
      theme: AppTheme.darkTheme,
      home: const StartupRouter(),
    );
  }
}