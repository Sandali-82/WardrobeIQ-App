import '../services/api_service.dart';

abstract class ProfileRepository {
  static ProfileRepository instance = _ProfileRepositoryImpl();

  Future<ShapeResult> calculateFaceShape({
    required double foreheadWidth,
    required double cheekboneWidth,
    required double jawlineWidth,
    required double faceLength,
  });
  Future<ShapeResult> calculateBodyShape({
    required double shoulderWidth,
    required double bustWidth,
    required double waistWidth,
    required double hipWidth,
  });
  Future<String?> getSavedFaceShape();
  Future<String?> getSavedBodyShape();
  Future<String?> getSavedUndertone();
  Future<UndertoneResult> analyzeUndertone({
    required String imageBase64,
    required String mimeType,
  });
  Future<StylingGuide> getStylingGuide();
  Future<UserInfo> getSavedUserInfo();
  Future<ProfileUpdateResult> updateProfile({String? name, String? email});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class _ProfileRepositoryImpl implements ProfileRepository {
  ApiService get _api => ApiService.instance;

  @override
  Future<ShapeResult> calculateFaceShape({
    required double foreheadWidth,
    required double cheekboneWidth,
    required double jawlineWidth,
    required double faceLength,
  }) =>
      _api.calculateFaceShape(
        foreheadWidth: foreheadWidth,
        cheekboneWidth: cheekboneWidth,
        jawlineWidth: jawlineWidth,
        faceLength: faceLength,
      );

  @override
  Future<ShapeResult> calculateBodyShape({
    required double shoulderWidth,
    required double bustWidth,
    required double waistWidth,
    required double hipWidth,
  }) =>
      _api.calculateBodyShape(
        shoulderWidth: shoulderWidth,
        bustWidth: bustWidth,
        waistWidth: waistWidth,
        hipWidth: hipWidth,
      );

  @override
  Future<String?> getSavedFaceShape() => _api.getSavedFaceShape();

  @override
  Future<String?> getSavedBodyShape() => _api.getSavedBodyShape();

  @override
  Future<String?> getSavedUndertone() => _api.getSavedUndertone();

  @override
  Future<UndertoneResult> analyzeUndertone({
    required String imageBase64,
    required String mimeType,
  }) =>
      _api.analyzeUndertone(imageBase64: imageBase64, mimeType: mimeType);

  @override
  Future<StylingGuide> getStylingGuide() => _api.getStylingGuide();

  @override
  Future<UserInfo> getSavedUserInfo() => _api.getSavedUserInfo();

  @override
  Future<ProfileUpdateResult> updateProfile({String? name, String? email}) =>
      _api.updateProfile(name: name, email: email);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}