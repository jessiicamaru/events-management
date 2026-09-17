import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('RegisterScreen renders and checks password requirements in real-time', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShadApp(
          home: RegisterScreen(),
        ),
      ),
    );

    // Verify title and basic fields render
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.byType(ShadInput), findsNWidgets(3)); // Email, Password, Confirm Password
    expect(find.text('Password Requirements:'), findsOneWidget);

    // Initially, all checkmarks should show "not met" (which is LucideIcons.circle)
    // There are 5 password requirements, so there should be 5 circle icons
    expect(find.byIcon(LucideIcons.circle), findsNWidgets(5));
    expect(find.byIcon(LucideIcons.check), findsNothing);

    // Enter a password that meets some conditions, e.g. "a1"
    // a1 meets lowercase (a) and digit (1) but not minLength (2 < 6), uppercase, or special character.
    final passwordInput = find.byWidgetPredicate(
      (widget) => widget is ShadInput && widget.placeholder is Text && (widget.placeholder as Text).data == 'Password',
    );
    expect(passwordInput, findsOneWidget);

    await tester.enterText(passwordInput, 'a1');
    await tester.pump(); // trigger listeners

    // Now, lowercase and digit should be met (LucideIcons.check)
    // The remaining 3 should be LucideIcons.circle
    expect(find.byIcon(LucideIcons.check), findsNWidgets(2));
    expect(find.byIcon(LucideIcons.circle), findsNWidgets(3));

    // Enter a password that meets all conditions, e.g. "Ab1@cd"
    // Length: 6 >= 6 (Met)
    // Lowercase: b, c, d (Met)
    // Uppercase: A (Met)
    // Digit: 1 (Met)
    // Special: @ (Met)
    await tester.enterText(passwordInput, 'Ab1@cd');
    await tester.pump();

    // Now all 5 requirements should be met
    expect(find.byIcon(LucideIcons.check), findsNWidgets(5));
    expect(find.byIcon(LucideIcons.circle), findsNothing);

    // Verify that Confirm Password initially has NO check icon
    final confirmPasswordInput = find.byWidgetPredicate(
      (widget) => widget is ShadInput && widget.placeholder is Text && (widget.placeholder as Text).data == 'Confirm Password',
    );
    expect(confirmPasswordInput, findsOneWidget);

    // Enter a non-matching confirm password
    await tester.enterText(confirmPasswordInput, 'different');
    await tester.pump();
    
    // There are 5 checks for requirements, none from Confirm Password (since it doesn't match yet)
    expect(find.byIcon(LucideIcons.check), findsNWidgets(5));

    // Enter matching password
    await tester.enterText(confirmPasswordInput, 'Ab1@cd');
    await tester.pump();

    // Now all 5 requirements are met, and the confirm password field matches.
    // Total check icons should be 6 (5 requirements + 1 confirm password)!
    expect(find.byIcon(LucideIcons.check), findsNWidgets(6));
  });
}
