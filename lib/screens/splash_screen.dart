import 'package:flutter/material.dart';
import 'dart:async';

import 'package:memoria/services/network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'page_garde.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final connectionStatus = await NetworkService.checkConnection();
      final storedToken = prefs.getString(ApiService.TOKEN_KEY);

      if (!mounted) return;

      if (storedToken == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => PageGarde()),
        );
      }

      if (connectionStatus != ConnectionStatus.online) {
        _showConnectionMessage(connectionStatus);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PageGarde()),
      );
    }
  }

  void _showConnectionMessage(ConnectionStatus status) {
    if (!mounted) return;
    final message = status == ConnectionStatus.noInternet
        ? "Vérifiez votre connexion Internet"
        : "Le serveur est actuellement indisponible";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            status == ConnectionStatus.noInternet ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF2),
      body: Center(
        child: SizedBox(
          width: 262,
          height: 257.77,
          child: Image.asset(
            'assets/memoria_logo.png',
            width: 262,
            height: 257.77,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
