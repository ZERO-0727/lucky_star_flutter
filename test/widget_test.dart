import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo_flutter/main.dart';

void main() {
  testWidgets('Lucky Star app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LuckyStarApp());

    // Verify that the main navigation is present
    expect(find.byType(MainNavigation), findsOneWidget);

    // Verify that the bottom navigation bar has 4 items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget); // Plaza
    expect(find.byIcon(Icons.star), findsOneWidget); // Wish Wall
    expect(find.byIcon(Icons.people), findsOneWidget); // User Plaza
    expect(find.byIcon(Icons.home), findsOneWidget); // Home
  });
}
