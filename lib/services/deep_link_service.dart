import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';

/// Listens for wardrobeiq:// deep links (currently only the email
/// confirmation link) and handles them app-wide. Call [init] once, early,
/// passing a `GlobalKey<NavigatorState>` so it can navigate without needing
/// a BuildContext of its own.
class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // Handles the case where the app was fully closed and got launched
    // directly by tapping the link.
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri, navigatorKey);
    }

    // Handles the case where the app is already running (foreground or
    // background) and the link arrives while it's alive.
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, navigatorKey);
    });
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static void _handleUri(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    if (uri.scheme != 'wardrobeiq' || uri.host != 'login-success') return;

    final token = uri.queryParameters['token'];
    final name = uri.queryParameters['name'];
    final email = uri.queryParameters['email'];
    if (token == null || name == null || email == null) return;

    _saveAndGoHome(token, name, email, navigatorKey);
  }

  static Future<void> _saveAndGoHome(
    String token,
    String name,
    String email,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // The confirm-email page (hit by the browser) already confirmed the
    // account server-side and minted this JWT - we just need to store it
    // locally so the app treats itself as logged in.
    await ApiService.saveSessionFromDeepLink(token: token, name: name, email: email);

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}