import 'package:bike_buddy/app/app.dart';
import 'package:bike_buddy/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() {
  final Binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Supabase with the real configuration if it is not already initialized.
    try {
      await sb.Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
        realtimeClientOptions: const sb.RealtimeClientOptions(
          logLevel: sb.RealtimeLogLevel.info,
        ),
      );
    } catch (_) {
      // Already initialized
    }
  });

  Widget createRealTestWidget(SharedPreferences prefs) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: const BikeBuddyApp(),
    );
  }

  group('Live UI & Authentication Testing', () {
    testWidgets('Owner Sign-in, Profile Edit, Save, and Sign-out Flow',
        (tester) async {
      // Ensure local state starts clean but has seen onboarding to land directly on Login/Home
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('has_seen_onboarding', true);

      await tester.pumpWidget(createRealTestWidget(prefs));
      await tester.pumpAndSettle();

      // 1. Landing on Discovery Home
      expect(find.text('Ready to\nPedal?'), findsOneWidget);

      // 2. Click the Profile Icon to go to Login Screen (since we are signed out)
      final profileIconFinder = find.byIcon(Icons.person_outline_rounded);
      expect(profileIconFinder, findsOneWidget);
      await tester.tap(profileIconFinder);
      await tester.pumpAndSettle();

      // 3. Verify Login Screen
      expect(find.text('Welcome back'), findsOneWidget);

      // 4. Fill in Owner credentials
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Password');

      await tester.enterText(
          find.descendant(of: emailField, matching: find.byType(EditableText)),
          'owner@bikebuddy.com');
      await tester.enterText(
          find.descendant(
              of: passwordField, matching: find.byType(EditableText)),
          'Owner@123');
      await tester.pumpAndSettle();

      // 5. Click Sign In
      final signInButton = find.widgetWithText(FilledButton, 'Sign In');
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);

      // Wait for login request and navigation redirect (takes some time due to network call)
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 6. Should land on Admin Dashboard (Station name or inventory will be loaded)
      expect(find.text('Active Rentals'), findsOneWidget);
      expect(find.text('Total Inventory'), findsOneWidget);

      // 7. Click on the profile avatar/icon to go to Profile Settings
      final dashboardProfileButton = find
              .descendant(
                of: find.byType(AppBar),
                matching: find.byIcon(Icons.person_outline_rounded),
              )
              .evaluate()
              .isNotEmpty
          ? find.descendant(
              of: find.byType(AppBar),
              matching: find.byIcon(Icons.person_outline_rounded))
          : find.byIcon(Icons.person_outline_rounded);

      await tester.tap(dashboardProfileButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 8. Verify we are on Profile Screen
      expect(find.text('Profile Settings'), findsOneWidget);
      expect(find.text('Amount Per Hour'), findsOneWidget);

      // 9. Perform a test Profile save (e.g. changing phone number or full name)
      final phoneField = find.widgetWithText(TextFormField, 'Phone Number');
      if (phoneField.evaluate().isNotEmpty) {
        await tester.enterText(
            find.descendant(
                of: phoneField, matching: find.byType(EditableText)),
            '254700112233');
        await tester.pumpAndSettle();

        final saveButton = find
                .widgetWithText(ElevatedButton, 'Save Settings')
                .evaluate()
                .isNotEmpty
            ? find.widgetWithText(ElevatedButton, 'Save Settings')
            : find.widgetWithText(FilledButton, 'Save Settings');

        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // 10. Click Sign Out
      final signOutButton = find.widgetWithText(OutlinedButton, 'Sign Out');
      expect(signOutButton, findsOneWidget);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      // Confirm sign out in the dialog
      final confirmSignOutButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Sign Out'),
      );
      expect(confirmSignOutButton, findsOneWidget);
      await tester.tap(confirmSignOutButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 11. Verify we are back on Discovery Home
      expect(find.text('Ready to\nPedal?'), findsOneWidget);
    });

    testWidgets('Rider Sign-in and Sign-out Flow', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('has_seen_onboarding', true);

      await tester.pumpWidget(createRealTestWidget(prefs));
      await tester.pumpAndSettle();

      // 1. Click Profile Icon to Login
      final profileIconFinder = find.byIcon(Icons.person_outline_rounded);
      await tester.tap(profileIconFinder);
      await tester.pumpAndSettle();

      // 2. Fill in Rider credentials
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Password');

      await tester.enterText(
          find.descendant(of: emailField, matching: find.byType(EditableText)),
          'rider@bikebuddy.com');
      await tester.enterText(
          find.descendant(
              of: passwordField, matching: find.byType(EditableText)),
          'Rider@123');
      await tester.pumpAndSettle();

      // 3. Sign In
      final signInButton = find.widgetWithText(FilledButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 4. Verify Rider Home
      expect(find.text('Ready to\nPedal?'), findsOneWidget);

      // 5. Navigate to Profile
      final profileTabButton =
          find.byIcon(Icons.person_rounded).evaluate().isNotEmpty
              ? find.byIcon(Icons.person_rounded)
              : find.byIcon(Icons.person_outline_rounded);
      await tester.tap(profileTabButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 6. Sign Out
      final signOutButton = find.widgetWithText(OutlinedButton, 'Sign Out');
      expect(signOutButton, findsOneWidget);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      // Confirm
      final confirmSignOutButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Sign Out'),
      );
      await tester.tap(confirmSignOutButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 7. Verify we are back on Discovery Home
      expect(find.text('Ready to\nPedal?'), findsOneWidget);
    });
  });
}
