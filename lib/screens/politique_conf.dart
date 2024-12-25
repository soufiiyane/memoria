import 'package:flutter/material.dart';

class PolitiqueConfidentialitePage extends StatelessWidget {
  const PolitiqueConfidentialitePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D243D),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Color.fromARGB(
              255, 138, 138, 138), // Change la couleur de la flèche retour
        ),
        title: const Text('',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D243D),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Politique de confidentialité',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _Section(
              titre: '1. Collecte des données',
              contenu: [
                'Nous collectons uniquement les données nécessaires au fonctionnement de l\'application',
                'Les informations personnelles sont stockées de manière sécurisée',
                'Vos cartes et données d\'apprentissage sont chiffrées'
              ],
            ),
            _Section(
              titre: '2. Utilisation des données',
              contenu: [
                'Amélioration de votre expérience d\'apprentissage',
                'Synchronisation de vos progrès entre appareils',
                'Analyse statistique anonyme pour optimiser l\'application'
              ],
            ),
            _Section(
              titre: '3. Protection des données',
              contenu: [
                'Toutes les données sensibles sont chiffrées',
                'Nous ne partageons pas vos informations avec des tiers',
                'Vous pouvez demander la suppression de vos données à tout moment'
              ],
            ),
            _Section(
              titre: '4. Vos droits',
              contenu: [
                'Accès à vos données personnelles',
                'Modification de vos informations',
                'Suppression de votre compte et des données associées'
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String titre;
  final List<String> contenu;

  const _Section({
    Key? key,
    required this.titre,
    required this.contenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...contenu.map((texte) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    Expanded(
                      child: Text(
                        texte,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
