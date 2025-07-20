import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmosoul/main.dart';

void main() {
  testWidgets('CosmoSoul app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CosmoSoulApp());

    // Verify that the main navigation is present
    expect(find.byType(MainNavigation), findsOneWidget);

    // Verify that the bottom navigation bar has 4 items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget); // Space Station
    expect(find.byIcon(Icons.person), findsOneWidget); // Soul Plaza
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget); // Soul Talk
    expect(find.byIcon(Icons.home), findsOneWidget); // Home
  });
}
