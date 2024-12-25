import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:memoria/config/apiconfig.dart';
import 'package:memoria/models/card_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudySession {
  final String date;
  final List<int> cardIds;
  final Map<int, String> cardDifficulties;

  StudySession({
    required this.date,
    required this.cardIds,
    required this.cardDifficulties,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      date: json['date'],
      cardIds:
          List<int>.from(json['cardIds'].map((id) => int.parse(id.toString()))),
      cardDifficulties: Map<int, String>.from(
        json['cardDifficulties'].map((key, value) =>
            MapEntry(int.parse(key.toString()), value.toString())),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'cardIds': cardIds.map((id) => id.toString()).toList(),
        'cardDifficulties': cardDifficulties
            .map((key, value) => MapEntry(key.toString(), value)),
      };
}

class StatistiquesPage extends StatefulWidget {
  final StudySession? studySession;
  final http.Client? httpClient;

  const StatistiquesPage({
    Key? key,
    this.studySession,
    this.httpClient,
  }) : super(key: key);

  @override
  _StatistiquesPageState createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  List<CardData> studiedCards = [];
  bool isLoading = true;
  String error = '';
  StudySession? currentSession;
  late final http.Client _client;

  @override
  void initState() {
    super.initState();
    _client = widget.httpClient ?? http.Client();
    _loadStudiedCards();
  }

  @override
  void dispose() {
    if (widget.httpClient == null) {
      _client.close();
    }
    super.dispose();
  }

  Map<String, int> _getDifficultyCounts() {
    Map<String, int> counts = {
      'easy': 0,
      'medium': 0,
      'hard': 0,
    };

    if (currentSession != null) {
      currentSession!.cardDifficulties.values.forEach((difficulty) {
        counts[difficulty] = (counts[difficulty] ?? 0) + 1;
      });
    }

    return counts;
  }

  Future<void> _loadStudiedCards() async {
    try {
      if (widget.studySession != null) {
        currentSession = widget.studySession;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final sessionJson = prefs.getString('current_study_session');

        if (sessionJson == null) {
          setState(() {
            isLoading = false;
            error = 'Aucune session d\'étude trouvée';
          });
          return;
        }

        final sessionData = json.decode(sessionJson);
        currentSession = StudySession.fromJson(sessionData);
      }

      List<CardData> cards = [];
      for (int cardId in currentSession!.cardIds) {
        try {
          final response = await _client.get(
            Uri.parse(ApiConfig.buildUrl('/flashcards/$cardId')),
            headers: {
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final cardData = json.decode(response.body);
            final card = CardData.fromApiResponse(cardData);
            card.difficulty = currentSession!.cardDifficulties[cardId];
            cards.add(card);
          }
        } catch (e) {
          print('Erreur lors de la récupération de la carte $cardId: $e');
        }
      }

      setState(() {
        studiedCards = cards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Erreur lors du chargement de la session: $e';
      });
    }
  }

  Widget _buildDifficultyRow(
      String label, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: MediaQuery.of(context).size.width * 0.85 * percentage,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final difficultyCounts = _getDifficultyCounts();
    final total = currentSession?.cardIds.length ?? 0;

    return Scaffold(
      backgroundColor: Color(0xFF0D243D),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session d\'étude',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Nombre de cartes étudiées aujourd\'hui',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16.0,
                ),
              ),
              SizedBox(height: 32.0),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120.0,
                      height: 120.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              total.toString(),
                              style: TextStyle(
                                color: Color(0xFF0D243D),
                                fontSize: 48.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'cartes',
                              style: TextStyle(
                                color: Color(0xFF0D243D),
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Color(0xFF8CB7D6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 32.0,
                        ),
                      ),
                      child: Text(
                        'Etudier des cartes',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.0),
              Text(
                'Répartition par difficulté',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Votre performance sur les cartes étudiées',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.0,
                ),
              ),
              SizedBox(height: 24.0),
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else if (error.isNotEmpty)
                Center(
                  child: Text(
                    error,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else ...[
                _buildDifficultyRow(
                  'Facile',
                  difficultyCounts['easy']!,
                  total,
                  Colors.green,
                  Icons.check_circle_outline,
                ),
                SizedBox(height: 16),
                _buildDifficultyRow(
                  'Moyen',
                  difficultyCounts['medium']!,
                  total,
                  Colors.orange,
                  Icons.radio_button_unchecked,
                ),
                SizedBox(height: 16),
                _buildDifficultyRow(
                  'Difficile',
                  difficultyCounts['hard']!,
                  total,
                  Colors.red,
                  Icons.warning_outlined,
                ),
              ],
              Spacer(),
              Center(
                child: Text(
                  'Continuez à étudier régulièrement\npour améliorer vos résultats !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.0,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
