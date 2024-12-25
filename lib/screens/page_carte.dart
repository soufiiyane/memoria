import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:memoria/config/apiconfig.dart';
import 'package:memoria/screens/ImagePickerService.dart';
import 'package:memoria/screens/cloudinary_service.dart';
import 'package:memoria/services/api_service.dart';
import 'mes_paquets.dart';
import 'package:memoria/models/card_data.dart';
import 'package:memoria/models/deck_info.dart';

class PageCarte extends StatefulWidget {
  final DeckInfo deck;
  final CardData? card; // Add this to receive card data if editing

  const PageCarte({Key? key, required this.deck, this.card}) : super(key: key);

  @override
  _PageCarteState createState() => _PageCarteState();
}

class _PageCarteState extends State<PageCarte> {
  final Color primaryColor = Color(0xFF0D243D);
  final Color secondaryColor = Color(0xFF183048);
  final Color textColor = Color(0xFFEBEBEB);
  final Color placeholderColor = Color(0xFF8F8F8F);
  final TextEditingController _rectoTextController = TextEditingController();
  final TextEditingController _versoTextController = TextEditingController();

  final ImagePickerService _imagePickerService = ImagePickerService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  File? _selectedImageRecto;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    // Initialize with existing card data if available
    if (widget.card != null) {
      _rectoTextController.text = widget.card!.rectoText;
      _versoTextController.text = widget.card!.versoText;
      _uploadedImageUrl = widget.card!.rectoImage;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePickerService.pickImage();
    if (pickedFile != null) {
      setState(() {
        _selectedImageRecto = pickedFile;
      });
    }
  }

  void _saveAndNavigate() async {
    String rectoText = _rectoTextController.text;
    String versoText = _versoTextController.text;

    // Vérification de la longueur minimale
    const minLength = 5;
    String? validationError;

    if (rectoText.isEmpty || versoText.isEmpty) {
      validationError = 'Veuillez remplir les champs recto et verso.';
    } else if (rectoText.length < minLength && versoText.length < minLength) {
      validationError =
          'Les textes du recto et du verso doivent contenir au moins $minLength caractères.';
    } else if (rectoText.length < minLength) {
      validationError =
          'Le texte du recto doit contenir au moins $minLength caractères.';
    } else if (versoText.length < minLength) {
      validationError =
          'Le texte du verso doit contenir au moins $minLength caractères.';
    }

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Vérifier d'abord si on est en ligne
      final isServerAvailable = await ApiService.isServerAvailable();
      if (!isServerAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de créer une carte en mode hors ligne'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Si on est en ligne, continuer avec le processus normal
      if (_selectedImageRecto != null) {
        String? rectoImageUrl =
            await _cloudinaryService.uploadImage(_selectedImageRecto!);
        if (rectoImageUrl != null) {
          setState(() {
            _uploadedImageUrl = rectoImageUrl;
          });
        } else {
          _showErrorDialog('Erreur',
              'Le chargement de l\'image a échoué. Veuillez réessayer.');
          return;
        }
      }

      Map<String, dynamic> flashcardData = {
        'question': rectoText,
        'answer': versoText,
        'deckId': widget.deck.id,
        'imageUrl': _uploadedImageUrl,
        'difficultyLevel': 0,
      };

      final url = ApiConfig.createFlashcardEndpoint(widget.deck.id.toString());
      final response = await ApiService.post(
        url,
        flashcardData,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 503) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de créer une carte en mode hors ligne'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MesPaquets(deck: widget.deck),
          ),
        );
      } else {
        final responseBody = jsonDecode(response.body);
        String errorMessage = responseBody['error'] ?? 'Erreur inconnue';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la requête : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Une erreur est survenue lors de la création de la carte'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorDialog(String title, String message, [int? statusCode]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (statusCode != null) Text('Statut HTTP : $statusCode'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: primaryColor),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 40,
              child: Text(
                'Ajouter des cartes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 40,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.chevron_left,
                  color: Color(0xFF8F8F8F),
                  size: 30,
                ),
              ),
            ),
            Positioned.fill(
              top: 80,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRectoSection(),
                    SizedBox(height: 20),
                    _buildVersoSection(),
                    SizedBox(height: 40),
                    _buildAddCardButton(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRectoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recto',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: secondaryColor,
              boxShadow: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _rectoTextController,
                  maxLength: 50,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Saisissez le texte ici',
                    hintStyle: TextStyle(
                      color: placeholderColor,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                // Display the image from URL if available
                if (_uploadedImageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      _uploadedImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            'Erreur de chargement de l\'image',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: _selectedImageRecto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        _selectedImageRecto!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.add_a_photo, color: placeholderColor),
            ),
          ),
          Divider(color: Colors.grey, height: 24),
        ],
      ),
    );
  }

  Widget _buildVersoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verso',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: secondaryColor,
              boxShadow: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _versoTextController,
              maxLength: 50,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Saisissez le texte ici',
                hintStyle: TextStyle(
                  color: placeholderColor,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          Divider(color: Colors.grey, height: 24),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return GestureDetector(
      onTap: _saveAndNavigate,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Ajouter la carte',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
