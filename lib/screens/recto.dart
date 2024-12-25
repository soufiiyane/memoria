import 'package:flutter/material.dart';
import 'package:memoria/models/card_data.dart';

import 'dart:convert';
import 'dart:math' as math;

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

  Map<String, dynamic> toJson() => {
        'date': date,
        'cardIds': cardIds,
        // Convert int keys to strings for JSON serialization
        'cardDifficulties': cardDifficulties
            .map((key, value) => MapEntry(key.toString(), value)),
      };

  factory StudySession.fromJson(Map<String, dynamic> json) {
    // Convert string keys back to integers when deserializing
    final difficultiesMap =
        (json['cardDifficulties'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(int.parse(key), value as String),
    );

    return StudySession(
      date: json['date'],
      cardIds: List<int>.from(json['cardIds']),
      cardDifficulties: difficultiesMap,
    );
  }
}

class Recto extends StatefulWidget {
  final List<CardData> cards;
  final int initialIndex;

  const Recto({
    Key? key,
    required this.cards,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _FlipCardPageState createState() => _FlipCardPageState();
}

class _FlipCardPageState extends State<Recto>
    with SingleTickerProviderStateMixin {
  bool isFlipped = false;
  bool isAnswerVisible = false;
  late int currentIndex;
  final TextEditingController _answerController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _animation;
  late StudySession currentSession;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {});
      });
    _initializeStudySession();
  }

  Future<void> _initializeStudySession() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final sessionJson = prefs.getString('current_study_session');

    if (sessionJson != null) {
      final sessionData = json.decode(sessionJson);
      final session = StudySession.fromJson(sessionData);

      if (session.date == today) {
        currentSession = session;
      } else {
        currentSession = StudySession(
          date: today,
          cardIds: [],
          cardDifficulties: {},
        );
      }
    } else {
      currentSession = StudySession(
        date: today,
        cardIds: [],
        cardDifficulties: {},
      );
    }
    await _saveStudySession();
  }

  Future<void> _saveStudySession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = json.encode(currentSession.toJson());
    await prefs.setString('current_study_session', sessionJson);
  }

  void _nextCard() {
    if (currentIndex < widget.cards.length - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
        _controller.reset();
        _answerController.clear();
      });
    } else {
      _showDifficultyDialog();
    }
  }

  void _handleDifficultySelection(String difficulty) async {
    // Update current card's difficulty
    final currentCard = widget.cards[currentIndex];
    if (!currentSession.cardIds.contains(currentCard.id)) {
      currentSession.cardIds.add(currentCard.id);
    }
    currentSession.cardDifficulties[currentCard.id] = difficulty;

    // Save session to SharedPreferences
    await _saveStudySession();

    // Update state
    setState(() {
      widget.cards[currentIndex].difficulty = difficulty;
    });

    // Close dialog
    Navigator.of(context).pop();

    // If last card, go to statistics page
    if (currentIndex == widget.cards.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StatistiquesPage(studySession: currentSession),
        ),
      );
    } else {
      _nextCard();
    }
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color(0xFF183048),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quel est le niveau de difficulté de cette question ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                _buildDifficultyButton('Facile', Color(0xFF4CAF50), 'easy'),
                SizedBox(height: 12),
                _buildDifficultyButton('Medium', Color(0xFFFFA726), 'medium'),
                SizedBox(height: 12),
                _buildDifficultyButton('Difficile', Color(0xFFE53935), 'hard'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyButton(String text, Color color, String difficulty) {
    return GestureDetector(
      onTap: () => _handleDifficultySelection(difficulty),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showAnswerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color(0xFF183048),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _answerController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre réponse',
                    hintStyle: TextStyle(color: Color(0xFF8F8F8F)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF8F8F8F)),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _flipCard();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Valider',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _flipCard() {
    setState(() {
      isFlipped = !isFlipped;
      if (isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D243D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Color(0xFF8F8F8F),
                      size: 24,
                    ),
                  ),
                  Text(
                    '${currentIndex + 1}/${widget.cards.length}',
                    style: TextStyle(
                      color: Color(0xFF8F8F8F),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(_animation.value * math.pi),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        color: Color(0xFF183048),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateX(_animation.value > 0.5 ? math.pi : 0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _animation.value > 0.5
                                      ? widget.cards[currentIndex].versoText
                                      : widget.cards[currentIndex].rectoText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                if (_animation.value <= 0.5 &&
                                    widget.cards[currentIndex].rectoImage !=
                                        null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.cards[currentIndex].rectoImage!,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.3,
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.3,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.3,
                                          color: Colors.grey[800],
                                          child: Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                      loadingBuilder: (BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.3,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.3,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xFF0D243D),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(0xFF183048),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: _showAnswerDialog,
                      child: Icon(
                        Icons.keyboard,
                        color: Color(0xFF8F8F8F),
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(0xFF183048),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: _flipCard,
                        child: Center(
                          child: Text(
                            'Afficher la réponse',
                            style: TextStyle(
                              color: Color(0xFF8F8F8F),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(0xFF183048),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: _nextCard,
                      child: Icon(
                        Icons.chevron_right,
                        color: Color(0xFF8F8F8F),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _answerController.dispose();
    super.dispose();
  }
}

class StatistiquesPage extends StatefulWidget {
  final StudySession studySession;

  const StatistiquesPage({
    Key? key,
    required this.studySession,
  }) : super(key: key);

  @override
  _StatistiquesPageState createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D243D),
      appBar: AppBar(
        title: Text(
          'Statistiques',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF183048),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session d\'aujourd\'hui',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF183048),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatisticRow(
                      'Cartes étudiées',
                      widget.studySession.cardIds.length.toString(),
                      Icons.credit_card,
                    ),
                    SizedBox(height: 16),
                    _buildDifficultyBreakdown(),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Répartition par difficulté',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildDifficultyCharts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBreakdown() {
    final difficultyCounts = _getDifficultyCounts();
    final total = widget.studySession.cardIds.length;

    return Column(
      children: [
        _buildDifficultyBar(
            'Facile', difficultyCounts['easy'] ?? 0, total, Color(0xFF4CAF50)),
        SizedBox(height: 8),
        _buildDifficultyBar(
            'Moyen', difficultyCounts['medium'] ?? 0, total, Color(0xFFFFA726)),
        SizedBox(height: 8),
        _buildDifficultyBar('Difficile', difficultyCounts['hard'] ?? 0, total,
            Color(0xFFE53935)),
      ],
    );
  }

  Widget _buildDifficultyBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF0D243D),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: count / (total > 0 ? total : 1),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCharts() {
    final difficultyCounts = _getDifficultyCounts();
    final total = widget.studySession.cardIds.length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF183048),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildCircularProgress(
            'Faciles',
            difficultyCounts['easy'] ?? 0,
            total,
            Color(0xFF4CAF50),
          ),
          SizedBox(height: 16),
          _buildCircularProgress(
            'Moyennes',
            difficultyCounts['medium'] ?? 0,
            total,
            Color(0xFFFFA726),
          ),
          SizedBox(height: 16),
          _buildCircularProgress(
            'Difficiles',
            difficultyCounts['hard'] ?? 0,
            total,
            Color(0xFFE53935),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(
      String label, int count, int total, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        Spacer(),
        Text(
          '$count cartes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Map<String, int> _getDifficultyCounts() {
    Map<String, int> counts = {
      'easy': 0,
      'medium': 0,
      'hard': 0,
    };

    widget.studySession.cardDifficulties.forEach((_, difficulty) {
      counts[difficulty] = (counts[difficulty] ?? 0) + 1;
    });

    return counts;
  }
}
