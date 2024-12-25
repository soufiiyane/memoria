import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/main.dart';
import 'package:memoria/screens/splash_screen.dart';

void main() {
  group('MemoriaApp Widget Tests', () {
    testWidgets('MemoriaApp creates MaterialApp with correct properties',
        (WidgetTester tester) async {
      // Pump the MemoriaApp
      await tester.pumpWidget(const MemoriaApp());

      // Find the MaterialApp widget
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(materialAppFinder);

      // Test MaterialApp properties
      expect(materialApp.debugShowCheckedModeBanner, false);
      expect(materialApp.title, 'Memoria');

      // Test theme
      expect(materialApp.theme, isNotNull);

      // Check primary color exists and is not null
      expect(materialApp.theme?.colorScheme.primary, isNotNull);
    });

    testWidgets('MemoriaApp is a StatelessWidget', (WidgetTester tester) async {
      // Verify that MemoriaApp is a StatelessWidget
      expect(const MemoriaApp() is StatelessWidget, isTrue);
    });

    testWidgets('MemoriaApp constructor works with optional key',
        (WidgetTester tester) async {
      // Test constructor with different key scenarios
      const key1 = Key('test-key');
      const key2 = Key('another-key');

      final app1 = const MemoriaApp();
      final app2 = const MemoriaApp(key: key1);
      final app3 = const MemoriaApp(key: key2);

      // Verify different key scenarios
      expect(app1.key, isNull);
      expect(app2.key, key1);
      expect(app3.key, key2);
    });

    testWidgets('SplashScreen is the initial home screen',
        (WidgetTester tester) async {
      // Pump the MemoriaApp
      await tester.pumpWidget(const MemoriaApp());

      // Verify SplashScreen is the initial screen
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
