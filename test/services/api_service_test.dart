import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memoria/services/api_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiService', () {
    test('saveTokens devrait sauvegarder les tokens', () async {
      // Act
      await ApiService.saveTokens(
        token: 'test_token',
        refreshToken: 'test_refresh_token',
      );

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ApiService.TOKEN_KEY), 'test_token');
      expect(
          prefs.getString(ApiService.REFRESH_TOKEN_KEY), 'test_refresh_token');
    });

    test('clearTokens devrait supprimer tous les tokens', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiService.TOKEN_KEY, 'test_token');
      await prefs.setString(ApiService.REFRESH_TOKEN_KEY, 'test_refresh_token');
      await prefs.setString(ApiService.USER_EMAIL_KEY, 'test@test.com');

      // Act
      await ApiService.clearTokens();

      // Assert
      expect(prefs.getString(ApiService.TOKEN_KEY), null);
      expect(prefs.getString(ApiService.REFRESH_TOKEN_KEY), null);
      expect(prefs.getString(ApiService.USER_EMAIL_KEY), null);
    });

    test('saveUserInfo devrait sauvegarder les informations utilisateur',
        () async {
      // Act
      await ApiService.saveUserInfo(
        email: 'test@test.com',
        username: 'testuser',
      );

      // Assert
      final userInfo = await ApiService.getUserInfo();
      expect(userInfo['email'], 'test@test.com');
      expect(userInfo['username'], 'testuser');
    });

    test('isAuthenticated devrait retourner true si les tokens existent',
        () async {
      // Arrange
      await ApiService.saveTokens(
        token: 'test_token',
        refreshToken: 'test_refresh_token',
      );

      // Act & Assert
      final isAuth = await ApiService.isAuthenticated();
      expect(isAuth, true);
    });

    test('isAuthenticated devrait retourner false si pas de tokens', () async {
      // Act & Assert
      final isAuth = await ApiService.isAuthenticated();
      expect(isAuth, false);
    });

    test('isServerAvailable devrait retourner false en cas d\'erreur',
        () async {
      // Act
      final isAvailable = await ApiService.isServerAvailable();

      // Assert
      expect(isAvailable, false);
    });

    test('OfflineModeException devrait avoir le bon message', () {
      // Arrange & Act
      final exception = OfflineModeException('Test message');

      // Assert
      expect(exception.message, 'Test message');
    });
  });
}
