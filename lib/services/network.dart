import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/apiconfig.dart';

class NetworkService {
  static Future<bool> hasInternetConnection() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      // Double vérification avec Google
      final response = await http
          .get(
            Uri.parse('https://www.google.com'),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isServerOnline() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.healthCheckEndpoint))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur serveur: $e');
      return false;
    }
  }

  static Future<ConnectionStatus> checkConnection() async {
    bool hasInternet = await hasInternetConnection();
    if (!hasInternet) return ConnectionStatus.noInternet;

    bool isOnline = await isServerOnline();
    return isOnline ? ConnectionStatus.online : ConnectionStatus.serverOffline;
  }
}

enum ConnectionStatus {
  online,
  noInternet,
  serverOffline,
}
