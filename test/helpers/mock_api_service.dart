import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/services/api_service.dart';

/// Mocktail mock of the whole ApiService contract - the Flutter equivalent
/// of the Moq mocks on the backend. In a test:
///   final api = MockApiService();
///   ApiService.instance = api;
///   when(() => api.login(any(), any())).thenAnswer((_) async => {...});
class MockApiService extends Mock implements ApiService {}