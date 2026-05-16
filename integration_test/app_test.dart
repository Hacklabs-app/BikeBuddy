import 'package:bike_buddy/app/app.dart';
import 'package:bike_buddy/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Flow', () {
    testWidgets('Onboarding to Login Flow', (tester) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': false,
      });

      // Start the app with a fresh ProviderScope
      await tester.pumpWidget(
        const ProviderScope(
          child: BikeBuddyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify we are on Onboarding
      expect(find.text('Find Nearest Bikes'), findsOneWidget);

      // 2. Swipe to next page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Seamless Rental'), findsOneWidget);

      // 3. Swipe to last page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Ride Rewards'), findsOneWidget);

      // 4. Tap "Ride Along" (Complete Onboarding)
      final startButton = find.text('Ride Along now');
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // 5. Verify we land on Discovery Home (since hasSeenOnboarding is now true)
      expect(find.text('Ready to\nPedal?'), findsOneWidget);

      // 6. Navigate to Login (e.g. by tapping Profile)
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      // 7. Verify we are on Login Screen
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });
  });
}
