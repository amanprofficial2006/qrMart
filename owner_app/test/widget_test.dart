import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrmart_owner/src/app_theme.dart';
import 'package:qrmart_owner/src/features/auth/start_screen.dart';

void main() {
  testWidgets('start screen renders qrMart branding and actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: StartScreen(
          onStart: () {},
          onLogin: () {},
        ),
      ),
    );

    expect(find.text('qrMart'), findsNothing);
    expect(find.text('QR ordering for local shops'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
