import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rulewise/main.dart';
import 'package:rulewise/services/notification_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(RuleWiseApp(notificationService: NotificationService()));

    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
