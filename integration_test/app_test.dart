import 'package:bike_buddy/app/app.dart';
import 'package:bike_buddy/core/services/storage_service.dart';
import 'package:bike_buddy/core/models/user_model.dart';
import 'package:bike_buddy/shared/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockStorageService extends Mock implements StorageService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService mockStorageService;

  setUpAll(() async {
    // Initialize Supabase with dummy values to prevent late initialization errors
    // in the BikeBuddyApp initState.
    try {
      await sb.Supabase.initialize(
        url: 'https://dummy.supabase.co',
        anonKey: 'dummy',
      );
    } catch (_) {
      // Already initialized
    }
  });

  setUp(() {
    mockStorageService = MockStorageService();
    when(() => mockStorageService.hasSeenOnboarding()).thenReturn(true);
  });

  Widget createTestWidget({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorageService),
        ...overrides,
      ],
      child: const BikeBuddyApp(),
    );
  }

  group('End-to-End User Journeys', () {
    testWidgets('Guest to Rider Registration Flow', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Landing on Discovery Home
      expect(find.text('Ready to\nPedal?'), findsOneWidget);

      // 2. Go to Login
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      // 3. Go to Role Selection
      await tester.tap(find.text('Create one'));
      await tester.pumpAndSettle();

      // 4. Select Rider
      expect(find.text('RIDER'), findsOneWidget);
      await tester.tap(find.text('RIDER'));
      await tester.pumpAndSettle();

      // 5. Verify Rider Form
      expect(find.text('Create Rider Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
    });

    testWidgets('Guest to Owner Registration Flow', (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Go to Login -> Role Selection
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create one'));
      await tester.pumpAndSettle();

      // 2. Select Owner
      expect(find.text('STATION OWNER'), findsOneWidget);
      await tester.tap(find.text('STATION OWNER'));
      await tester.pumpAndSettle();

      // 3. Verify Owner Form
      expect(find.text('Join as an Owner'), findsOneWidget);
      expect(find.text('Station Name'), findsOneWidget);
    });

    testWidgets('Interceptor: Logged In Guest is forced to Role Selection',
        (tester) async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            authStateProvider
                .overrideWith((ref) => Stream.value(mocktailUser())),
            currentUserProvider.overrideWith((ref) async => const UserModel(
                  id: 'test-id',
                  email: 'test@example.com',
                  fullName: 'Test User',
                  role: UserRole.pending,
                )),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should be redirected to Role Selection
      expect(find.text('Join the ride'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);
    });
  });
}

// Helper to create a dummy user
sb.User mocktailUser() => sb.User(
      id: 'test-id',
      email: 'test@example.com',
      appMetadata: {},
      userMetadata: {},
      aud: 'aud',
      createdAt: DateTime.now().toIso8601String(),
    );
