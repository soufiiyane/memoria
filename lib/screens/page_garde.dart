import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memoria/config/apiconfig.dart';

import 'package:http/http.dart' as http;
import 'package:memoria/screens/mes_paquets.dart';
import 'package:memoria/screens/parametre.dart';
import 'package:memoria/screens/statistique.dart';
import 'package:memoria/services/api_service.dart';
import 'package:memoria/services/network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memoria/models/deck_info.dart';
import 'package:file_picker/file_picker.dart';

class User {
  final int id;
  final String username;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'],
    );
  }
}

class PageGarde extends StatefulWidget {
  @override
  _PageGardeState createState() => _PageGardeState();
}

class _PageGardeState extends State<PageGarde> {
  int streakCount = 0;
  DateTime? lastOpenDate;
  final TextEditingController paquetController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<DeckInfo> decks = [];
  bool isSearching = false;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadStreak();
    _loadDecks();
  }

  @override
  void dispose() {
    paquetController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<List<User>> _searchUsers(String searchTerm) async {
    try {
      final response =
          await ApiService.get('/users/search?searchTerm=$searchTerm');
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = json.decode(response.body);
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Échec de la recherche d\'utilisateurs');
    } catch (e) {
      print('Erreur lors de la recherche des utilisateurs: $e');
      throw e;
    }
  }

  Future<void> _shareDeck(
      BuildContext context, int deckId, List<int> userIds) async {
    if (deckId == 0 || userIds.isEmpty) {
      throw Exception('Deck ID et IDs utilisateurs ne doivent pas être vides');
    }

    try {
      final response = await ApiService.shareDeck(deckId, userIds);
      if (response.statusCode != 200) {
        throw Exception('Échec du partage du paquet: ${response.body}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paquet partagé avec succès')),
        );
      }
    } catch (e) {
      print('Erreur lors du partage du paquet: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage du paquet: $e')),
        );
      }
      rethrow;
    }
  }

  void _showShareDialog(BuildContext context, DeckInfo deck) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return _ShareDialogContent(
          deck: deck,
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  Future<int> _getCardCount(int deckId) async {
    print('📊 Récupération du nombre de cartes pour le deck $deckId');
    try {
      final url =
          ApiConfig.getFlashcardsEndpoint(deckId.toString(), page: 0, size: 0);
      print('🌐 URL: $url');

      final response = await ApiService.get(url);
      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('📥 Réponse: $jsonResponse');

        int totalElements = jsonResponse['totalElements'] as int;
        print('🔢 Nombre de cartes: $totalElements');
        return totalElements;
      }
      return 0;
    } catch (e) {
      print('❌ Erreur comptage cartes: $e');
      return 0;
    }
  }

  Future<void> _checkConnection() async {
    final connectionStatus = await NetworkService.checkConnection();
    if (mounted) {
      setState(() {
        isOffline = connectionStatus != ConnectionStatus.online;
      });

      if (isOffline && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              connectionStatus == ConnectionStatus.noInternet
                  ? 'Vous êtes en mode hors ligne'
                  : 'Le serveur est actuellement indisponible',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () async {
                await _checkConnection();
                if (!isOffline) {
                  await _loadDecks();
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _importCSV() async {
    try {
      print('🚀 Début de l\'import CSV');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) Navigator.pop(context);
        return;
      }

      PlatformFile file = result.files.first;

      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('Le fichier est vide');
      }

      String csvString = utf8.decode(file.bytes!, allowMalformed: true);
      csvString = csvString
          .replaceAll('"""', '"')
          .replaceAll('""', '"')
          .replaceAll('"question,answer"', 'question,answer')
          .replaceAll('\r\n', '\n')
          .trim();

      List<String> lines = csvString.split('\n');
      if (lines.length < 2) {
        throw Exception(
            'Le fichier CSV doit contenir au moins une ligne de données');
      }

      List<List<String>> cleanedRows = [];
      for (int i = 1; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;

        RegExp regex = RegExp(r'"([^"]+)","([^"]+)"');
        Match? match = regex.firstMatch(line);

        if (match != null && match.groupCount == 2) {
          String question = match.group(1)!.trim();
          String answer = match.group(2)!.trim();

          // Découper les réponses trop longues en plusieurs cartes
          if (answer.length > 50) {
            List<String> answerParts = _splitAnswer(answer);
            for (int j = 0; j < answerParts.length; j++) {
              String partQuestion =
                  j == 0 ? question : '$question (partie ${j + 1})';
              cleanedRows.add([partQuestion, answerParts[j]]);
            }
          } else if (answer.length < 5) {
            // Ignorer les réponses trop courtes
            print('⚠️ Réponse trop courte ignorée: $answer');
            continue;
          } else {
            cleanedRows.add([question, answer]);
          }
        }
      }

      if (cleanedRows.isEmpty) {
        throw Exception('Aucune donnée valide trouvée dans le fichier CSV');
      }

      final Map<String, dynamic> deckData = {
        'name': file.name.replaceAll('.csv', ''),
        'description': 'Importé depuis CSV',
        'tags': [],
        'isPublic': false,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final deckResponse =
          await ApiService.post('/decks', deckData, headers: headers);

      if (deckResponse.statusCode == 401) {
        throw Exception('Session expirée');
      }

      if (deckResponse.statusCode != 200 && deckResponse.statusCode != 201) {
        throw Exception(
            'Erreur lors de la création du paquet: ${deckResponse.body}');
      }

      final deckJson = jsonDecode(deckResponse.body);
      final deckId = deckJson['id'];

      int successCount = 0;
      for (var row in cleanedRows) {
        // Vérification finale des longueurs
        String question = row[0];
        String answer = row[1];

        if (answer.length < 5 || answer.length > 50) {
          print(
              '⚠️ Longueur invalide - Question: ${question.length} chars, Réponse: ${answer.length} chars');
          continue;
        }

        final Map<String, dynamic> cardData = {
          'question': question,
          'answer': answer,
          'deckId': deckId
        };

        try {
          final cardResponse =
              await ApiService.post('/flashcards', cardData, headers: headers);

          if (cardResponse.statusCode == 200 ||
              cardResponse.statusCode == 201) {
            successCount++;
            print(
                '✅ Carte $successCount créée: Q=${question.length} chars, R=${answer.length} chars');
          } else {
            print('⚠️ Échec création carte: ${cardResponse.body}');
          }
        } catch (e) {
          print('⚠️ Erreur création carte: $e');
        }
      }

      if (successCount == 0) {
        throw Exception('Aucune carte n\'a pu être créée');
      }

      final newDeck = DeckInfo(
        id: deckId,
        name: deckJson['name'],
        description: deckJson['description'] ?? '',
        tags: List<String>.from(deckJson['tags'] ?? []),
        totalCards: successCount,
        masteredCards: 0,
        averageSuccessRate: 0.0,
      );

      if (context.mounted) {
        Navigator.pop(context);

        setState(() {
          decks.add(newDeck);
        });
        await _saveDecks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import réussi: $successCount cartes créées'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadDecks();
      }
    } catch (e, stackTrace) {
      print('❌ ERREUR: $e');
      print('📍 StackTrace: $stackTrace');
      if (context.mounted) {
        Navigator.pop(context);
        if (e.toString().contains('Session expirée')) {
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'import: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

// Fonction pour découper les réponses longues
  List<String> _splitAnswer(String answer) {
    List<String> parts = [];
    int start = 0;
    while (start < answer.length) {
      // Chercher un point ou une virgule près de 45 caractères
      int endPos = start + 45;
      if (endPos >= answer.length) {
        parts.add(answer.substring(start).trim());
        break;
      }

      // Chercher le dernier point ou virgule
      int lastPunct = answer.substring(start, endPos).lastIndexOf('. ');
      if (lastPunct == -1) {
        lastPunct = answer.substring(start, endPos).lastIndexOf(', ');
      }

      if (lastPunct != -1) {
        // Couper à la ponctuation
        parts.add(answer.substring(start, start + lastPunct + 1).trim());
        start += lastPunct + 2;
      } else {
        // Pas de ponctuation trouvée, couper au dernier espace
        int lastSpace = answer.substring(start, endPos).lastIndexOf(' ');
        if (lastSpace == -1 || lastSpace < 5) {
          // Si pas d'espace ou trop court, couper à 45 caractères
          parts.add(answer.substring(start, endPos).trim());
          start = endPos;
        } else {
          parts.add(answer.substring(start, start + lastSpace).trim());
          start += lastSpace + 1;
        }
      }
    }
    return parts;
  }

  Future<void> _loadDecks() async {
    if (isOffline) {
      final prefs = await SharedPreferences.getInstance();
      final String? decksString = prefs.getString('decks');

      if (decksString != null) {
        setState(() {
          decks = (jsonDecode(decksString) as List)
              .map((json) => DeckInfo.fromJson(json))
              .toList();
        });
      }
      return;
    }

    try {
      final response = await ApiService.get(ApiConfig.recupereEndpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('content')) {
          final List<dynamic> decksJson = jsonResponse['content'];
          setState(() {
            decks = decksJson.map((json) => DeckInfo.fromJson(json)).toList();
          });
        } else {
          setState(() {
            decks = [];
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des decks : $e');
    }
  }

  Future<void> _saveDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final String decksString =
        jsonEncode(decks.map((deck) => deck.toJson()).toList());
    await prefs.setString('decks', decksString);
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      streakCount = prefs.getInt('streak_count') ?? 0;
      final lastOpenString = prefs.getString('last_open_date');
      if (lastOpenString != null) {
        lastOpenDate = DateTime.parse(lastOpenString);
      }
    });
    _updateStreak();
  }

  Future<void> _updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastOpenDate == null) {
      streakCount = 1;
    } else {
      final yesterday = today.subtract(Duration(days: 1));
      final lastOpen =
          DateTime(lastOpenDate!.year, lastOpenDate!.month, lastOpenDate!.day);

      if (today == lastOpen) {
        return;
      } else if (yesterday == lastOpen) {
        streakCount += 1;
      } else {
        streakCount = 1;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak_count', streakCount);
    await prefs.setString('last_open_date', now.toIso8601String());

    setState(() {});
  }

  Future<void> _createNewDeck() async {
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de créer un paquet en mode hors ligne'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (paquetController.text.isNotEmpty) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        final Map<String, dynamic> deckData = {
          'name': paquetController.text,
          'description': '',
          'tags': [],
          'isPublic': false,
        };

        final response = await ApiService.post('/decks', deckData, headers: {});
        Navigator.pop(context);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          final newDeck = DeckInfo(
            id: responseData['id'],
            name: responseData['name'],
            description: responseData['description'] ?? '',
            tags: List<String>.from(responseData['tags'] ?? []),
            totalCards: responseData['totalCards'] ?? 0,
            masteredCards: responseData['masteredCards'] ?? 0,
            averageSuccessRate:
                responseData['averageSuccessRate']?.toDouble() ?? 0.0,
          );

          setState(() {
            decks.add(newDeck);
          });
          await _saveDecks();

          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Le paquet "${newDeck.name}" a été créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _handleCreateDeckError(response.statusCode);
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion au serveur'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _createNewDeck,
            ),
          ),
        );
      }
    }
  }

  void _handleCreateDeckError(int statusCode) async {
    switch (statusCode) {
      case 400:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Données invalides'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      case 401:
      case 403:
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session expirée. Veuillez vous reconnecter.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reconnecter',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur inattendue est survenue ($statusCode)'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<http.Response> deleteDeck(int deckId) async {
    try {
      final endpoint = ApiConfig.deleteDeckEndpoint(deckId.toString());
      return await ApiService.delete(endpoint);
    } catch (e) {
      print('Erreur lors de la suppression du deck : $e');
      rethrow;
    }
  }

  void _showStreakInfo(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/fire (2).png",
                          width: 24,
                          height: 24,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ta série',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Le nombre de jours d\'affilée lesquels tu as appris',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/fire (2).png",
                            width: 20,
                            height: 20,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$streakCount',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Jour de série',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Continuez à étudier\nquotidiennement pour\naugmenter votre streak !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeckList() {
    List<DeckInfo> filteredDecks =
        isSearching && searchController.text.isNotEmpty
            ? decks
                .where((deck) => deck.name
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase()))
                .toList()
            : decks;

    if (filteredDecks.isEmpty) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/plus.png",
                  width: 16,
                  height: 16,
                ),
                Text(
                  'Créer un nouveau',
                  style: TextStyle(
                    color: Color(0xFFDCDCDC),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' paquet',
                  style: TextStyle(
                    color: Color(0xFF8F8F8F),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredDecks.length,
        itemBuilder: (context, index) {
          final deck = filteredDecks[index];
          final originalIndex = decks.indexOf(deck);
          return _buildDeckItem(deck, originalIndex);
        },
      ),
    );
  }

  Widget _buildDeckItem(DeckInfo deck, int originalIndex) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A324F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDeckDetails(deck),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildCardCount(deck.id),
                    ],
                  ),
                ),
                _buildDeckActions(deck, originalIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardCount(int deckId) {
    return FutureBuilder<int>(
      future: _getCardCount(deckId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Chargement...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ Erreur affichage compteur: ${snapshot.error}');
          return Text(
            'Erreur de chargement',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 14,
            ),
          );
        }

        final cardCount = snapshot.data ?? 0;
        print('📊 Affichage: $cardCount cartes (deck $deckId)');

        return Text(
          cardCount > 0
              ? '$cardCount carte${cardCount > 1 ? 's' : ''}'
              : 'Aucune carte ajoutée',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        );
      },
    );
  }

  Widget _buildDeckActions(DeckInfo deck, int originalIndex) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red[300],
            size: 20,
          ),
          onPressed: () => _handleDelete(deck, originalIndex),
        ),
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            color: Colors.blue[300],
            size: 20,
          ),
          onPressed: () => _showShareDialog(context, deck),
        ),
        SizedBox(width: 4),
        Image.asset(
          "assets/next.png",
          width: 15,
          height: 15,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  void _navigateToDeckDetails(DeckInfo deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MesPaquets(deck: deck),
      ),
    ).then((_) {
      if (mounted) {
        _loadDecks();
      }
    });
  }

  Future<void> _handleDelete(DeckInfo deck, int originalIndex) async {
    if (isOffline) {
      _showOfflineError();
      return;
    }

    if (await _confirmDelete(deck)) {
      try {
        setState(() => decks.removeAt(originalIndex));
        final response = await deleteDeck(deck.id);

        if (response.statusCode == 503) {
          _handleOfflineDeletion(deck, originalIndex);
        } else {
          _showSuccessMessage('Paquet supprimé avec succès');
        }
      } catch (e) {
        _handleDeletionError(deck, originalIndex);
      }
    }
  }

  Future<bool> _confirmDelete(DeckInfo deck) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF1C3A57),
              title: Text(
                'Confirmer la suppression',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Voulez-vous vraiment supprimer "${deck.name}" ?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showOfflineError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible de supprimer un paquet en mode hors ligne'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleOfflineDeletion(DeckInfo deck, int originalIndex) {
    setState(() => decks.insert(originalIndex, deck));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible de supprimer le paquet en mode hors ligne'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleDeletionError(DeckInfo deck, int originalIndex) {
    setState(() => decks.insert(originalIndex, deck));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de la suppression'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: () => _handleDelete(deck, originalIndex),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showNewPackageDialog(BuildContext context) {
    bool isImportView = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(37)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(),
                    _buildImportToggle(isImportView, (fn) {
                      setModalState(() {
                        fn();
                        isImportView = !isImportView;
                      });
                    }),
                    if (!isImportView) ...[
                      _buildCreatePackageContent(),
                    ] else ...[
                      _buildImportContent(),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      paquetController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Widget _buildNewPackageContent(bool isImportView, StateSetter setModalState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDialogHeader(),
        _buildImportToggle(isImportView, setModalState),
        if (!isImportView) ...[
          _buildCreatePackageContent(),
        ] else ...[
          _buildImportContent(),
        ],
      ],
    );
  }

  Widget _buildDialogHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Nouveau paquet',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {
              paquetController.clear();
              Navigator.pop(context);
            },
            child: Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImportToggle(bool isImportView, StateSetter setModalState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              'Créer',
              !isImportView,
              () => setModalState(() {
                isImportView = false;
              }),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildToggleButton(
              'Importer',
              isImportView,
              () => setModalState(() {
                isImportView = true;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.grey[400] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePackageContent() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Créez votre propre paquet. Vous obtiendrez des meilleurs résultats avec des cartes que vous avez créées vous-même.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: paquetController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nom du paquet',
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _createNewDeck();
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: paquetController.text.isNotEmpty ? _createNewDeck : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF64B5F6),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Créer un nouveau paquet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous pouvez importer des cartes depuis:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close the modal first
              _importCSV(); // Then trigger import
            },
            behavior:
                HitTestBehavior.translucent, // Add this to ensure tap detection
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'CSV',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CSV(Docs, Excel, etc.)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Importez à partir de n\'importe quel document.csv',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Color(0xFF0D243D),
        body: Column(
          children: [
            _buildHeader(),
            if (isSearching) _buildSearchBar(),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            _buildDeckList(),
            _buildAddButton(),
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 50, right: 20, left: 20, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _showStreakInfo(context),
            child: Row(
              children: [
                Image.asset(
                  "assets/fire (2).png",
                  width: 24,
                  height: 24,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  '$streakCount',
                  style: TextStyle(
                    color: Color(0xFFDCDCDC),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
              });
            },
            child: isSearching
                ? Icon(Icons.close, color: Colors.white)
                : Image.asset(
                    "assets/search1.png",
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher des paquets',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20, bottom: 20),
      child: GestureDetector(
        onTap: () => _showNewPackageDialog(context),
        child: Image.asset(
          "assets/plus (2).png",
          width: 41,
          height: 41,
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem("assets/home (2).png", "Mes paquets", 24),
          _buildNavItem("assets/book (3).png", "Statistique", 32),
          _buildNavItem("assets/settings.png", "Paramètres", 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(String imagePath, String label, double size) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case "Mes paquets":
            break;
          case "Statistique":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StatistiquesPage()),
            );
            break;
          case "Paramètres":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ParametresPage()),
            );
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: size,
            height: size,
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFFDCDCDC),
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

// Share Dialog Content Widget
class _ShareDialogContent extends StatefulWidget {
  final DeckInfo deck;
  final VoidCallback onClose;

  const _ShareDialogContent({
    required this.deck,
    required this.onClose,
  });

  @override
  _ShareDialogContentState createState() => _ShareDialogContentState();
}

class _ShareDialogContentState extends State<_ShareDialogContent> {
  late TextEditingController searchController;
  List<User> users = [];
  bool isLoading = false;
  List<int> selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF1C3A57),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Partager avec',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _handleSearch,
              ),
              SizedBox(height: 16),
              _buildUserList(),
              SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (isLoading) return CircularProgressIndicator(color: Colors.white);
    if (users.isEmpty && searchController.text.isNotEmpty) {
      return Text('Aucun utilisateur trouvé',
          style: TextStyle(color: Colors.white70));
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return CheckboxListTile(
            title: Text(
              '${user.email} (${user.username})',
              style: TextStyle(color: Colors.white),
            ),
            value: selectedUserIds.contains(user.id),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedUserIds.add(user.id);
                } else {
                  selectedUserIds.remove(user.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: widget.onClose,
          child: Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _handleShare,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Text('Partager'),
        ),
      ],
    );
  }

  Future<void> _handleSearch(String value) async {
    if (value.isEmpty) {
      setState(() {
        users = [];
        selectedUserIds.clear();
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      final results = await _searchUsers(value);
      if (mounted) {
        setState(() {
          users = results;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche: $e')),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner au moins un utilisateur'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _shareDeck(context, widget.deck.id, selectedUserIds);
      if (mounted) widget.onClose();
    } catch (e) {
      // Error handled in _shareDeck
    }
  }

  Future<List<User>> _searchUsers(String searchTerm) async {
    try {
      final response =
          await ApiService.get('/users/search?searchTerm=$searchTerm');
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = json.decode(response.body);
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Échec de la recherche d\'utilisateurs');
    } catch (e) {
      print('Erreur lors de la recherche des utilisateurs: $e');
      throw e;
    }
  }

  Future<void> _shareDeck(
      BuildContext context, int deckId, List<int> userIds) async {
    if (deckId == 0 || userIds.isEmpty) {
      throw Exception('Deck ID et IDs utilisateurs ne doivent pas être vides');
    }

    try {
      final response = await ApiService.shareDeck(deckId, userIds);
      if (response.statusCode != 200) {
        throw Exception('Échec du partage du paquet: ${response.body}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paquet partagé avec succès')),
        );
      }
    } catch (e) {
      print('Erreur lors du partage du paquet: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage du paquet: $e')),
        );
      }
      rethrow;
    }
  }
}
