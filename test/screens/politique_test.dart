import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/politique_conf.dart';

// Recreate the _Section widget for testing
class TestSection extends StatelessWidget {
  final String titre;
  final List<String> contenu;
  const TestSection({
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

void main() {
  group('PolitiqueConfidentialitePage Widget Tests', () {
    testWidgets('Renders PolitiqueConfidentialitePage with correct structure',
        (WidgetTester tester) async {
      // Pump the PolitiqueConfidentialitePage widget
      await tester
          .pumpWidget(MaterialApp(home: PolitiqueConfidentialitePage()));

      // Verify Scaffold exists
      expect(find.byType(Scaffold), findsOneWidget);

      // Check background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0D243D));
    });

    testWidgets('Verifies AppBar properties', (WidgetTester tester) async {
      await tester
          .pumpWidget(MaterialApp(home: PolitiqueConfidentialitePage()));

      // Check AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFF0D243D));
      expect(appBar.elevation, 0);
    });

    testWidgets('Checks main title', (WidgetTester tester) async {
      await tester
          .pumpWidget(MaterialApp(home: PolitiqueConfidentialitePage()));

      // Verify main title
      expect(find.text('Politique de confidentialité'), findsOneWidget);
    });

    testWidgets('Verifies section titles', (WidgetTester tester) async {
      await tester
          .pumpWidget(MaterialApp(home: PolitiqueConfidentialitePage()));

      // Check section titles
      final expectedTitles = [
        '1. Collecte des données',
        '2. Utilisation des données',
        '3. Protection des données',
        '4. Vos droits'
      ];

      for (var title in expectedTitles) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('Checks section content', (WidgetTester tester) async {
      await tester
          .pumpWidget(MaterialApp(home: PolitiqueConfidentialitePage()));

      // Verify content for each section
      final expectedContents = [
        // Section 1 contents
        [
          'Nous collectons uniquement les données nécessaires au fonctionnement de l\'application',
          'Les informations personnelles sont stockées de manière sécurisée',
          'Vos cartes et données d\'apprentissage sont chiffrées'
        ],
        // Section 2 contents
        [
          'Amélioration de votre expérience d\'apprentissage',
          'Synchronisation de vos progrès entre appareils',
          'Analyse statistique anonyme pour optimiser l\'application'
        ],
        // Section 3 contents
        [
          'Toutes les données sensibles sont chiffrées',
          'Nous ne partageons pas vos informations avec des tiers',
          'Vous pouvez demander la suppression de vos données à tout moment'
        ],
        // Section 4 contents
        [
          'Accès à vos données personnelles',
          'Modification de vos informations',
          'Suppression de votre compte et des données associées'
        ]
      ];

      for (var contents in expectedContents) {
        for (var content in contents) {
          expect(find.text(content), findsOneWidget);
        }
      }
    });

    testWidgets('Verifies Section widget rendering',
        (WidgetTester tester) async {
      // Create a test Section widget
      final testSection = TestSection(
          titre: 'Test Section', contenu: ['Test Content 1', 'Test Content 2']);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: testSection)));

      // Check section title
      expect(find.text('Test Section'), findsOneWidget);

      // Check section contents
      expect(find.text('Test Content 1'), findsOneWidget);
      expect(find.text('Test Content 2'), findsOneWidget);

      // Verify bullet points
      final bulletPoints = find.text('• ');
      expect(bulletPoints, findsNWidgets(2));
    });
  });
}
