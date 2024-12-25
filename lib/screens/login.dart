import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memoria/screens/page_garde.dart';
import 'package:memoria/screens/password_reset.dart';
import 'package:memoria/screens/registre.dart';
import 'package:memoria/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  final String? username; // Ajout des paramètres optionnels
  final String? email;
  final String? token;

  RegistrationScreen({
    Key? key,
    this.username,
    this.email,
    this.token,
  }) : super(key: key);
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  Future<void> _validateAndLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Veuillez entrer votre email');
      return;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Veuillez entrer votre mot de passe');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E82DB),
            ),
          );
        },
      );

      final response = await ApiService.post(
        '/auth/authenticate',
        {
          'email': email,
          'password': password,
        },
        headers: {},
      );

      // Fermer l'indicateur de chargement
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();

        // Vérifier la présence des tokens
        if (data['token'] == null || data['refreshToken'] == null) {
          throw Exception('Tokens manquants dans la réponse');
        }

        // Utiliser la nouvelle méthode saveTokens de ApiService
        await ApiService.saveTokens(
          token: data['token'],
          refreshToken: data['refreshToken'],
        );
        await ApiService.saveUserInfo(
          email: email, // l'email du TextEditingController
          username: '',
        );
        // Vous pouvez aussi sauvegarder d'autres informations utilisateur si nécessaire

        if (data['user'] != null) {
          await prefs.setString('user_data', jsonEncode(data['user']));
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF0D243D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Succès',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Connexion réussie !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Vérifier l'authentification avant la navigation
                    if (await ApiService.isAuthenticated()) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => PageGarde()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur d\'authentification'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFF2E82DB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else if (response.statusCode == 401) {
        setState(() {
          _emailError = 'Email ou mot de passe incorrect';
          _passwordError = 'Email ou mot de passe incorrect';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Identifiants invalides'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur de connexion: $e');

      // En cas d'erreur, effacer les tokens existants
      await ApiService.clearTokens();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D243D),
      body: Center(
        child: Container(
          width: 360,
          height: 640,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Color(0xFF0D243D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              // Texte en haut aligné à gauche
              Positioned(
                left: 30,
                top: 50,
                child: SizedBox(
                  width: 300,
                  child: Text(
                    'Inscrivez-vous et\ncommencez\napprentissage',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 32,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // Champ de saisie e-mail avec message d'erreur
              Positioned(
                left: 30,
                top: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 300,
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: _emailError != null
                            ? Border.all(color: Colors.red, width: 1)
                            : null,
                      ),
                      child: TextField(
                        controller: _emailController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'E-mail:',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (_emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 5),
                        child: Text(
                          _emailError!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Champ de saisie mot de passe avec message d'erreur
              Positioned(
                left: 30,
                top: 330,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 300,
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: _passwordError != null
                            ? Border.all(color: Colors.red, width: 1)
                            : null,
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Mot de passe',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 5),
                        child: Text(
                          _passwordError!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 110,
                bottom: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PasswordResetPage()),
                    );
                  },
                  child: Text(
                    '',
                    style: TextStyle(
                      color: Color(0xFF2E82DB),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              // Bouton de connexion
              Positioned(
                left: 80,
                top: 500,
                child: GestureDetector(
                  onTap: _validateAndLogin,
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF2E82DB),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Texte pour inscription
              Positioned(
                left: 30,
                bottom: 40,
                child: SizedBox(
                  width: 300,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => registre()),
                      ); // Ajouter une navigation vers la page d'inscription
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Vous n\'êtes pas encore inscrit ?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          TextSpan(
                            text: ' Registre',
                            style: TextStyle(
                              color: Color(0xFF2E82DB),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
