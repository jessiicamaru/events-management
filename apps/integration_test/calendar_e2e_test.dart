import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Register, Login, and verify Calendar filters & settings', (tester) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle();

    // Generate a random email to avoid conflicts
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'user_$timestamp@test.com';
    final testPassword = 'Password123!';

    // 1. Check if we are on Login Screen (or somewhere else). We need to click "Create an account"
    expect(find.text('Create an account'), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    // 2. Register Screen
    expect(find.text('Create Account'), findsOneWidget);
    
    // Enter details
    await tester.enterText(find.byType(ShadInput).at(0), testEmail);
    await tester.enterText(find.byType(ShadInput).at(1), testPassword);
    await tester.enterText(find.byType(ShadInput).at(2), testPassword);
    
    // Tap Register
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Should be back on Login Screen after successful registration
    // If not, might already be on login.
    expect(find.text('Welcome Back'), findsOneWidget);
    
    // Enter login details
    await tester.enterText(find.byType(ShadInput).at(0), testEmail);
    await tester.enterText(find.byType(ShadInput).at(1), testPassword);
    
    // Tap Login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Then wait for the app shell rather than trusting a fixed delay: login, the splash
    // redirect and the first home fetch took longer than the three seconds this used to
    // sleep for.
    for (var i = 0; i < 30 && find.text('Calendar').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

    // 4. Go to the calendar. Login lands on the home page, which did not exist when this
    // test was written.
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();

    // The calendar toolbar should have filter pills "All", "Personal", "Squads"
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Squads'), findsOneWidget);

    // 5. Test Filter Tap
    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Squads'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    // 6. Test Calendar Settings. The toolbar no longer has a settings button: the sheet
    // is opened from a row on the Settings tab, so the only settings icon is the nav one.
    await tester.tap(find.byIcon(LucideIcons.settings).last);
    await tester.pumpAndSettle();

    expect(find.text('Calendar Settings'), findsWidgets);
    await tester.tap(find.text('Calendar Settings').first);
    await tester.pumpAndSettle();

    // Verify settings sheet appears
    expect(find.text('Start Hour'), findsOneWidget);

    // Close the bottom sheet by tapping the scrim above it; dragging it down trips
    // '_pendingFrame == null' in the test binding.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Back to the calendar
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    expect(find.text('Personal'), findsOneWidget);
  });
}
