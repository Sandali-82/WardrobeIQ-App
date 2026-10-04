import '../services/api_service.dart';

/// Auth/session operations, backed by [ApiService.instance]. Screens depend
/// on this (via [AuthRepository.instance]) instead of talking to ApiService
/// directly - narrower surface to mock in widget tests, and it's where any
/// auth-specific logic (e.g. future caching, retry) would live.
abstract class AuthRepository {
  static AuthRepository instance = _AuthRepositoryImpl();

  Future<Map<String, dynamic>> register(String name, String email, String password);
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> saveSessionFromDeepLink({
    required String token,
    required String name,
    required String email,
  });
  Future<bool> isLoggedIn();
  Future<void> logout();
}

class _AuthRepositoryImpl implements AuthRepository {
  ApiService get _api => ApiService.instance;

  @override
  Future<Map<String, dynamic>> register(String name, String email, String password) =>
      _api.register(name, email, password);

  @override
  Future<Map<String, dynamic>> login(String email, String password) =>
      _api.login(email, password);

  @override
  Future<void> saveSessionFromDeepLink({
    required String token,
    required String name,
    required String email,
  }) =>
      _api.saveSessionFromDeepLink(token: token, name: name, email: email);

  @override
  Future<bool> isLoggedIn() => _api.isLoggedIn();

  @override
  Future<void> logout() => _api.clearToken();
}