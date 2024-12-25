import 'package:http/http.dart' as http;
import 'package:memoria/config/apiconfig.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String TOKEN_KEY = 'auth_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String USER_EMAIL_KEY = 'user_email';
  static const String USER_NAME_KEY = 'user_name';
  static const String STORED_DECKS_KEY = 'stored_decks';
  static const String STORED_FLASHCARDS_PREFIX = 'stored_flashcards_';

  static Future<http.Response> shareDeck(int deckId, List<int> userIds) async {
    try {
      final isOnline = await isServerAvailable();
      if (!isOnline) {
        return http.Response('{"error": "Mode hors ligne"}', 503);
      }

      final url = Uri.parse(ApiConfig.buildUrl('/decks/share'));
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'deckIds': [deckId], // Wrap deckId in a list
        'recipientIds': userIds
      });

      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 403 && await _refreshAccessToken()) {
        headers['Authorization'] = 'Bearer ${await _getToken()}';
        response = await http.post(url, headers: headers, body: body);
      }

      return response;
    } catch (e) {
      print('Error sharing deck: $e');
      rethrow;
    }
  }

  static Future<bool> isServerAvailable() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.healthCheckEndpoint)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Serveur inaccessible: $e');
      return false;
    }
  }

  static Future<void> saveTokens(
      {required String token, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    await prefs.setString(REFRESH_TOKEN_KEY, refreshToken);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(REFRESH_TOKEN_KEY);
  }

  static Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      print('🔄 Tentative de refresh token...');

      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(
            '/auth/refresh-token')), // Changé de '/auth/refresh' à '/auth/refresh-token'
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      print('📥 Réponse refresh token: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Vérification que les tokens sont présents dans la réponse
        if (data['token'] != null && data['refreshToken'] != null) {
          await saveTokens(
              token: data['token'], refreshToken: data['refreshToken']);
          print('✅ Tokens rafraîchis avec succès');
          return true;
        } else {
          print('❌ Réponse invalide du serveur: tokens manquants');
          return false;
        }
      }

      // Si le refresh token est invalide ou expiré
      if (response.statusCode == 401) {
        print('❌ Refresh token invalide ou expiré');
        await clearTokens(); // Nettoie les tokens stockés
        return false;
      }

      print('❌ Échec du refresh token: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Erreur lors du refresh token: $e');
      return false;
    }
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(REFRESH_TOKEN_KEY);
    await prefs.remove(USER_EMAIL_KEY);
    await prefs.remove(USER_NAME_KEY);
  }

  static Future<void> _storeLocalData(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  static Future<String?> _getLocalData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<http.Response> get(String endpoint) async {
    try {
      final isOnline = await isServerAvailable();
      if (!isOnline) {
        if (endpoint == ApiConfig.recupereEndpoint) {
          final localData = await _getLocalData(STORED_DECKS_KEY);
          return http.Response(localData ?? '{"content": []}', 200);
        }
        if (endpoint.contains('/flashcards/deck/')) {
          final deckId = endpoint.split('/').last.split('?').first;
          final localData =
              await _getLocalData('${STORED_FLASHCARDS_PREFIX}$deckId');
          return http.Response(localData ?? '{"content": []}', 200);
        }
      }

      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 403 && await _refreshAccessToken()) {
        headers['Authorization'] = 'Bearer ${await _getToken()}';
        response = await http.get(url, headers: headers);
      }

      if (response.statusCode == 200) {
        if (endpoint == ApiConfig.recupereEndpoint) {
          await _storeLocalData(STORED_DECKS_KEY, response.body);
        } else if (endpoint.contains('/flashcards/deck/')) {
          final deckId = endpoint.split('/').last.split('?').first;
          await _storeLocalData(
              '${STORED_FLASHCARDS_PREFIX}$deckId', response.body);
        }
      }

      return response;
    } catch (e) {
      print('Erreur GET: $e');
      if (endpoint == ApiConfig.recupereEndpoint) {
        final localData = await _getLocalData(STORED_DECKS_KEY);
        return http.Response(localData ?? '{"content": []}', 200);
      }
      rethrow;
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {required Map<String, String> headers}) async {
    try {
      final isOnline = await isServerAvailable();
      if (!isOnline) {
        return http.Response('{"error": "Mode hors ligne"}', 503);
      }

      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      final token = await _getToken();
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      var response =
          await http.post(url, headers: requestHeaders, body: jsonEncode(body));

      if (response.statusCode == 403 && await _refreshAccessToken()) {
        requestHeaders['Authorization'] = 'Bearer ${await _getToken()}';
        response = await http.post(url,
            headers: requestHeaders, body: jsonEncode(body));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (endpoint == ApiConfig.decksEndpoint) {
          final existingData =
              await _getLocalData(STORED_DECKS_KEY) ?? '{"content": []}';
          final decks = jsonDecode(existingData)['content'] as List;
          decks.add(jsonDecode(response.body));
          await _storeLocalData(
              STORED_DECKS_KEY, jsonEncode({'content': decks}));
        }
      }

      return response;
    } catch (e) {
      print('Erreur POST: $e');
      rethrow;
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      final isOnline = await isServerAvailable();
      if (!isOnline) {
        throw OfflineModeException(
            'Impossible de supprimer en mode hors ligne');
      }

      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      var response = await http.delete(url, headers: headers);

      if (response.statusCode == 403 && await _refreshAccessToken()) {
        headers['Authorization'] = 'Bearer ${await _getToken()}';
        response = await http.delete(url, headers: headers);
      }

      if ((response.statusCode == 200 || response.statusCode == 204) &&
          endpoint.startsWith('/decks/')) {
        final deckId = endpoint.split('/').last;
        final existingData =
            await _getLocalData(STORED_DECKS_KEY) ?? '{"content": []}';
        final decks = jsonDecode(existingData)['content'] as List;
        decks.removeWhere((deck) => deck['id'].toString() == deckId);
        await _storeLocalData(STORED_DECKS_KEY, jsonEncode({'content': decks}));
        await _removeStoredFlashcards(deckId);
      }

      return response;
    } on OfflineModeException catch (e) {
      return http.Response(
          jsonEncode({'error': e.message, 'offline': true}), 503);
    } catch (e) {
      print('Erreur DELETE: $e');
      rethrow;
    }
  }

  static Future<void> _removeStoredFlashcards(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${STORED_FLASHCARDS_PREFIX}$deckId');
  }

  static Future<void> saveUserInfo(
      {required String email, required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(USER_EMAIL_KEY, email);
    await prefs.setString(USER_NAME_KEY, username);
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(USER_EMAIL_KEY),
      'username': prefs.getString(USER_NAME_KEY),
    };
  }

  static Future<bool> isAuthenticated() async {
    final token = await _getToken();
    final refreshToken = await _getRefreshToken();
    return token != null && refreshToken != null;
  }
}

// Ajouter cette classe d'exception:
class OfflineModeException implements Exception {
  final String message;
  OfflineModeException(this.message);
}
