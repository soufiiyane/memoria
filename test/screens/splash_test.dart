import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memoria/services/api_service.dart';

void main() {
  group('SplashScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('affiche le logo Memoria', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Vérifie que le logo est présent
      expect(find.byType(Image), findsOneWidget);

      // Vérifie les dimensions du conteneur
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 262);
      expect(sizedBox.height, 257.77);
    });

    testWidgets('vérifie la couleur de fond', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFE8EDF2));
    });

    testWidgets('vérifie le centrage du logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Vérifie que le logo est centré
      expect(find.byType(Center), findsOneWidget);

      // Vérifie les propriétés de l'image
      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('vérifie la présence du SizedBox', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Vérifie la présence et les dimensions du SizedBox
      final sizedBox = find.byType(SizedBox);
      expect(sizedBox, findsOneWidget);

      final SizedBox sizedBoxWidget = tester.widget(sizedBox);
      expect(sizedBoxWidget.width, 262);
      expect(sizedBoxWidget.height, 257.77);
    });
  });
}
