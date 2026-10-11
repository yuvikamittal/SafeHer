// Smoke test for SafeHer.
//
// Verifies the app boots into the animated splash screen showing the brand,
// then completes its intro sequence and lands on the login screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:safeher/main.dart';

void main() {
  testWidgets('Boots to splash and navigates to login', (tester) async {
    await tester.pumpWidget(const SafeHerApp());

    // Splash screen renders the brand immediately.
    expect(find.text('SafeHer'), findsWidgets);

    // Let the splash intro sequence + page transition run to completion.
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // The login screen is reached with its sign-in call to action.
    expect(find.text('Sign in to your account'), findsOneWidget);
  });
}
