import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/page_garde.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'streak_count': 0,
    });
  });

  group('PageGarde Tests', () {
    testWidgets('affiche les éléments de navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PageGarde()));
      await tester.pumpAndSettle();

      // Vérifie la présence des boutons de navigation
      expect(find.text('Mes paquets'), findsOneWidget);
      expect(find.text('Statistique'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgets('affiche l\'icône de streak', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PageGarde()));
      await tester.pumpAndSettle();

      // Vérifie uniquement la présence de l'icône de streak
      expect(find.image(AssetImage("assets/fire (2).png")), findsOneWidget);
    });

    testWidgets('affiche et cache la barre de recherche',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PageGarde()));
      await tester.pumpAndSettle();

      // Vérifie que la barre de recherche n'est pas visible initialement
      expect(find.byType(TextField), findsNothing);

      // Cherche l'icône de recherche et tap dessus
      final searchIcon = find.image(AssetImage("assets/search1.png"));
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Vérifie que la barre de recherche est maintenant visible
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('affiche le bouton d\'ajout', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PageGarde()));
      await tester.pumpAndSettle();

      // Vérifie la présence du bouton d'ajout
      expect(find.image(AssetImage("assets/plus (2).png")), findsOneWidget);
    });
  });
}
