class ApiConfig {
  static const String baseUrl =
      'https://aware-willingly-monkfish.ngrok-free.app/api/v1/memoria';

  //static const String baseUrl = 'http://192.168.137.171:8080/api/v1/memoria';
  // Nouvel endpoint pour le refresh token
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  // Health check endpoint
  static String get healthCheckEndpoint => '$baseUrl/health';
  //user search
  static String searchUsersEndpoint(String searchTerm) =>
      '$baseUrl/users/search';
  // Les endpoints
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get loginEndpoint => '$baseUrl/auth/authenticate';
  static String get resetPasswordEndpoint => '$baseUrl/auth/reset-password';
  static String get decksEndpoint => '/decks';
  static String createFlashcardEndpoint(String deckId) => '/flashcards';
  static String getFlashcardsEndpoint(String deckId,
          {required int page, required int size}) =>
      '/flashcards/deck/$deckId';
  static String deleteDeckEndpoint(String deckId) => '/decks/$deckId';
  static String get recupereEndpoint => '/decks';

  // Ajout de l'endpoint de suppression de flashcard
  static String deleteFlashcardEndpoint(String id) => '/flashcards/$id';
  static String searchFlashcardsEndpoint(String deckId, String query,
      {int page = 0, int size = 20}) {
    final encodedQuery = Uri.encodeComponent(query);
    return '/flashcards/search?deckId=$deckId&query=$encodedQuery&page=$page&size=$size';
  }

  static String buildUrl(String endpoint) {
    // Vérifier si l'endpoint commence déjà par le baseUrl
    if (endpoint.startsWith(baseUrl)) {
      return endpoint;
    }

    // Ajouter un '/' si l'endpoint n'en commence pas par un
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }

    return '$baseUrl$endpoint';
  }
}
