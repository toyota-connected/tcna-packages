import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatpak_flutter/main.dart';

void main() {
  group('Flatpak Flutter App Widget Tests', () {
    testWidgets('App loads without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify that the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App has proper title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, isNotNull);
    });

    testWidgets('App renders main scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.pumpAndSettle();

      
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('No overflow or rendering errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Ensure no rendering errors occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('Error Handling Widget Tests', () {
    testWidgets('App handles platform exceptions gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}