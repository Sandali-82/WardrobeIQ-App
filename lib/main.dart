import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'services/notification_service.dart';
import 'services/deep_link_service.dart';
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

  @override
  void initState() {
    super.initState();
    DeepLinkService.init(_navigatorKey);
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
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