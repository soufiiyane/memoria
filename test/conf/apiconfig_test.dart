import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/config/apiconfig.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl should be correctly defined', () {
      expect(
        ApiConfig.baseUrl,
        'https://aware-willingly-monkfish.ngrok-free.app/api/v1/memoria',
      );
    });

    group('Endpoints', () {
      test('healthCheckEndpoint should be correctly formatted', () {
        expect(
          ApiConfig.healthCheckEndpoint,
          '${ApiConfig.baseUrl}/health',
        );
      });

      test('searchUsersEndpoint should be correctly formatted', () {
        const searchTerm = 'test';
        expect(
          ApiConfig.searchUsersEndpoint(searchTerm),
          '${ApiConfig.baseUrl}/users/search',
        );
      });

      test('registerEndpoint should be correctly formatted', () {
        expect(
          ApiConfig.registerEndpoint,
          '${ApiConfig.baseUrl}/auth/register',
        );
      });

      test('loginEndpoint should be correctly formatted', () {
        expect(
          ApiConfig.loginEndpoint,
          '${ApiConfig.baseUrl}/auth/authenticate',
        );
      });

      test('resetPasswordEndpoint should be correctly formatted', () {
        expect(
          ApiConfig.resetPasswordEndpoint,
          '${ApiConfig.baseUrl}/auth/reset-password',
        );
      });

      test('decksEndpoint should be correctly formatted', () {
        expect(ApiConfig.decksEndpoint, '/decks');
      });

      test('createFlashcardEndpoint should be correctly formatted', () {
        const deckId = '123';
        expect(
          ApiConfig.createFlashcardEndpoint(deckId),
          '/flashcards',
        );
      });

      test('getFlashcardsEndpoint should be correctly formatted', () {
        const deckId = '123';
        const page = 0;
        const size = 10;
        expect(
          ApiConfig.getFlashcardsEndpoint(deckId, page: page, size: size),
          '/flashcards/deck/123',
        );
      });

      test('deleteDeckEndpoint should be correctly formatted', () {
        const deckId = '123';
        expect(
          ApiConfig.deleteDeckEndpoint(deckId),
          '/decks/123',
        );
      });

      test('deleteFlashcardEndpoint should be correctly formatted', () {
        const flashcardId = '123';
        expect(
          ApiConfig.deleteFlashcardEndpoint(flashcardId),
          '/flashcards/123',
        );
      });

      test(
          'searchFlashcardsEndpoint should be correctly formatted with default values',
          () {
        const deckId = '123';
        const query = 'test query';
        expect(
          ApiConfig.searchFlashcardsEndpoint(deckId, query),
          '/flashcards/search?deckId=123&query=test%20query&page=0&size=20',
        );
      });

      test(
          'searchFlashcardsEndpoint should be correctly formatted with custom page and size',
          () {
        const deckId = '123';
        const query = 'test query';
        const page = 2;
        const size = 15;
        expect(
          ApiConfig.searchFlashcardsEndpoint(deckId, query,
              page: page, size: size),
          '/flashcards/search?deckId=123&query=test%20query&page=2&size=15',
        );
      });
    });

    group('buildUrl', () {
      test(
          'should correctly combine baseUrl and endpoint when endpoint starts with /',
          () {
        const endpoint = '/test';
        expect(
          ApiConfig.buildUrl(endpoint),
          '${ApiConfig.baseUrl}/test',
        );
      });

      test(
          'should correctly combine baseUrl and endpoint when endpoint doesn\'t start with /',
          () {
        const endpoint = 'test';
        expect(
          ApiConfig.buildUrl(endpoint),
          '${ApiConfig.baseUrl}/test',
        );
      });

      test('should return endpoint as is when it already starts with baseUrl',
          () {
        final endpoint = '${ApiConfig.baseUrl}/test';
        expect(
          ApiConfig.buildUrl(endpoint),
          endpoint,
        );
      });

      test('should handle empty endpoint', () {
        const endpoint = '';
        expect(
          ApiConfig.buildUrl(endpoint),
          '${ApiConfig.baseUrl}/',
        );
      });
    });

    test('refreshTokenEndpoint should be correctly defined', () {
      expect(
        ApiConfig.refreshTokenEndpoint,
        '/auth/refresh-token',
      );
    });

    test('recupereEndpoint should be correctly defined', () {
      expect(
        ApiConfig.recupereEndpoint,
        '/decks',
      );
    });
  });
}
