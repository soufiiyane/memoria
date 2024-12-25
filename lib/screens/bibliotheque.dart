import 'package:flutter/material.dart';

class Bibliotheque extends StatelessWidget {
  const Bibliotheque({Key? key})
      : super(key: key); // Const pour le constructeur

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen 2'),
      ),
      body: Center(
        child: const Text(
          'Bienvenue sur la page 2!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
