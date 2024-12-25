import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/services/network.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'package:memoria/config/apiconfig.dart';

// Create a mock for Connectivity
class MockConnectivity extends Mock implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi]; // Default mock implementation
  }
}

// Create a mock for HttpClient
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('NetworkService', () {
    late MockConnectivity mockConnectivity;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockConnectivity = MockConnectivity();
      mockHttpClient = MockHttpClient();
    });

    test('hasInternetConnection returns false when no connectivity', () async {
      // Simulate no internet connectivity
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await NetworkService.hasInternetConnection();
      expect(result, false);
    });

    test('hasInternetConnection returns false on network request timeout',
        () async {
      // Simulate connectivity exists but network request fails
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      // Simulate HTTP request timeout
      when(http.get(Uri.parse('https://www.google.com')))
          .thenThrow(TimeoutException('Connection timeout'));

      final result = await NetworkService.hasInternetConnection();
      expect(result, false);
    });

    test('hasInternetConnection returns true on successful network request',
        () async {
      // Simulate connectivity exists
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      // Simulate successful HTTP response
      when(http.get(Uri.parse('https://www.google.com')))
          .thenAnswer((_) async => http.Response('OK', 200));

      final result = await NetworkService.hasInternetConnection();
      expect(result, true);
    });

    test('isServerOnline returns false on network request failure', () async {
      // Simulate server endpoint request failure
      when(http.get(Uri.parse(ApiConfig.healthCheckEndpoint)))
          .thenThrow(Exception('Network error'));

      final result = await NetworkService.isServerOnline();
      expect(result, false);
    });

    test('isServerOnline returns true on successful server response', () async {
      // Simulate successful server response
      when(http.get(Uri.parse(ApiConfig.healthCheckEndpoint)))
          .thenAnswer((_) async => http.Response('OK', 200));

      final result = await NetworkService.isServerOnline();
      expect(result, true);
    });

    test('checkConnection returns noInternet when no internet', () async {
      // Mock no internet connection
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await NetworkService.checkConnection();
      expect(result, ConnectionStatus.noInternet);
    });

    test('checkConnection returns serverOffline when server is not responding',
        () async {
      // Mock internet connection exists
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      // Mock server not responding
      when(http.get(Uri.parse(ApiConfig.healthCheckEndpoint)))
          .thenThrow(Exception('Server error'));

      final result = await NetworkService.checkConnection();
      expect(result, ConnectionStatus.serverOffline);
    });

    test(
        'checkConnection returns online when both internet and server are available',
        () async {
      // Mock internet connection exists
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      // Mock successful server response
      when(http.get(Uri.parse(ApiConfig.healthCheckEndpoint)))
          .thenAnswer((_) async => http.Response('OK', 200));

      final result = await NetworkService.checkConnection();
      expect(result, ConnectionStatus.online);
    });
  });
}

// Custom exception for timeout simulation
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
