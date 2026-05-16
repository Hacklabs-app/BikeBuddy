import 'package:bike_buddy/features/auth/presentation/screens/owner_signup_screen.dart';
import 'package:bike_buddy/features/auth/presentation/state/auth_state.dart';
import 'package:bike_buddy/shared/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockAuthNotifier extends StateNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState());
}

void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
  });

  Widget createTestWidget({bool isLoggedIn = false}) {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
        authStateProvider.overrideWith(
            (ref) => Stream.value(isLoggedIn ? mocktailUser() : null)),
      ],
      child: const MaterialApp(
        home: OwnerSignUpScreen(),
      ),
    );
  }

  group('OwnerSignUpScreen Widget Tests', () {
    testWidgets('renders station registration fields', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoggedIn: false));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Station Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('validation prevents submission when empty', (tester) async {
      // Set larger surface size to ensure button is on screen
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(isLoggedIn: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Station'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Station name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
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
