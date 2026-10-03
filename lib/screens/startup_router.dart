import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Checks for a saved login token on app start, so a returning user skips
// straight to Home instead of seeing the login screen every launch.
class StartupRouter extends StatelessWidget {
  const StartupRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthRepository.instance.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}