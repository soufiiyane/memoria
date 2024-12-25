import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memoria/models/card_data.dart';
import 'package:memoria/screens/recto.dart';
import 'page_carte.dart';
import 'package:memoria/models/deck_info.dart';
import 'dart:convert';
import 'package:memoria/config/apiconfig.dart';
import 'package:memoria/services/api_service.dart';

class MesPaquets extends StatefulWidget {
  final DeckInfo deck;

  const MesPaquets({Key? key, required this.deck}) : super(key: key);

  @override
  _MesPaquetsState createState() => _MesPaquetsState();
}

class _MesPaquetsState extends State<MesPaquets>
    with SingleTickerProviderStateMixin {
  List<CardData> flashcards = [];
  List<CardData> filteredCards = [];
  bool isLoading = true;
  String? error;
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool hasMoreCards = true;
  int currentPage = 0;
  final int cardsPerPage = 20;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
    _setupScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    searchController.addListener(_onSearchChanged);
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (!mounted) return;

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !isLoadingMore &&
          hasMoreCards) {
        _loadFlashcards();
      }
    });
  }

  void _onSearchChanged() {
    _filterCards(searchController.text);
  }

  void _filterCards(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCards = List.from(flashcards);
      } else {
        filteredCards = flashcards
            .where((card) =>
                card.rectoText.toLowerCase().contains(query.toLowerCase()) ||
                card.versoText.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadFlashcards({bool reset = false}) async {
    if (reset) {
      currentPage = 0;
      hasMoreCards = true;
    }

    if (isLoadingMore || !hasMoreCards) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      //final url = ApiConfig.getFlashcardsEndpoint(widget.deck.id.toString(),
      //page: currentPage);
      final url = ApiConfig.getFlashcardsEndpoint(widget.deck.id.toString(),
          page: currentPage, size: cardsPerPage);
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> newData = jsonResponse['content'] as List<dynamic>;
        final bool isLastPage = jsonResponse['last'] ?? true;

        setState(() {
          if (reset) {
            flashcards =
                newData.map((json) => CardData.fromApiResponse(json)).toList();
          } else {
            flashcards.addAll(
                newData.map((json) => CardData.fromApiResponse(json)).toList());
          }
          filteredCards = List.from(flashcards);
          currentPage++;
          hasMoreCards = !isLastPage;
          isLoading = false;
          error = null;
          print("Cartes chargées: ${flashcards.length}");
        });
      } else {
        // Gérez les erreurs
        setState(() {
          error = 'Erreur lors du chargement des cartes';
          isLoading = false;
        });
      }
    } catch (e) {
      // Gérez les erreurs
      setState(() {
        error = 'Erreur de connexion';
        isLoading = false;
      });
      print('Erreur lors du chargement des flashcards: $e');
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (isSearching) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        searchController.clear();
        _filterCards('');
      }
    });
  }

  Future<void> _deleteFlashcard(int index) async {
    try {
      final cardId = filteredCards[index].id;
      final url = ApiConfig.buildUrl('/flashcards/$cardId');

      final response = await ApiService.delete(url);

      if (response.statusCode == 503) {
        // Gérer le mode hors ligne
        final responseData = json.decode(response.body);
        if (responseData['offline'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Impossible de supprimer une carte en mode hors ligne'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          final deletedCard = filteredCards[index];
          filteredCards.removeAt(index);
          flashcards.remove(deletedCard);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carte supprimée avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur lors de la suppression (${response.statusCode})'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Erreur de suppression: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de connexion'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
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
                  'Supprimer la carte ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Cette action est irréversible.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteFlashcard(index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Supprimer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D243D),
      body: Stack(
        children: [
          // Header with search bar
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: 50),
              color: Color(0xFF0D243D),
              child: Column(
                children: [
                  if (isSearching)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                hintStyle: TextStyle(color: Colors.white60),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Color(0xFF8CB7D6)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: _toggleSearch,
                          ),
                        ],
                      ),
                    ),
                  if (!isSearching)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            widget.deck.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.search, color: Colors.white),
                              onPressed: _toggleSearch,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 30,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Transform.rotate(
                angle: 3.14,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/next.png"),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Liste des cartes
          Positioned.fill(
            top: 100,
            bottom: 100,
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : error != null
                    ? Center(
                        child: Text(
                          error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : filteredCards.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/empty-state-icon.png",
                                  width: 33,
                                  height: 37,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  isSearching &&
                                          searchController.text.isNotEmpty
                                      ? 'Aucune carte trouvée'
                                      : 'Ce paquet n\'a pas de cartes',
                                  style: TextStyle(
                                    color: Color(0xFF8F8F8F),
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            itemCount:
                                filteredCards.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredCards.length) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF8CB7D6),
                                    ),
                                  ),
                                );
                              }

                              return Dismissible(
                                key: Key(filteredCards[index].id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  final bool confirm = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      backgroundColor: Color(0xFF183048),
                                      title: Text(
                                        'Supprimer la carte',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: Text(
                                        'Êtes-vous sûr de vouloir supprimer cette carte ?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: Text(
                                            'Annuler',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: Text(
                                            'Supprimer',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 16,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _deleteFlashcard(index);
                                  }
                                  return confirm;
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Recto(
                                          cards: filteredCards,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF183048),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Carte ${index + 1}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showDeleteDialog(index),
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red[300],
                                                    size: 24,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Question:",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          filteredCards[index].rectoText,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          "Réponse:",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          filteredCards[index].versoText,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // Add cards button
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PageCarte(deck: widget.deck),
                    ),
                  );
                  if (result == true) {
                    _loadFlashcards(reset: true);
                  }
                },
                child: Container(
                  width: 217,
                  height: 56,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(37),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Ajouter des cartes',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
