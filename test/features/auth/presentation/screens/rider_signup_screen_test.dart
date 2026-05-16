import 'package:bike_buddy/features/auth/presentation/screens/rider_signup_screen.dart';
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
        home: RiderSignUpScreen(),
      ),
    );
  }

  group('RiderSignUpScreen Widget Tests', () {
    testWidgets('renders manual signup fields for guests', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoggedIn: false));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('ID / Admission Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('renders completion fields for social users', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoggedIn: true));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.text('ID / Admission Number'), findsOneWidget);
      expect(find.text('Phone (Optional)'), findsOneWidget);
      expect(find.text('Password'), findsNothing);
    });

    testWidgets('validation prevents submission when empty', (tester) async {
      // Set larger surface size to ensure button is on screen
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(isLoggedIn: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Registration'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('ID is required'), findsOneWidget);
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
