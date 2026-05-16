import 'package:bike_buddy/features/auth/presentation/screens/login_screen.dart';
import 'package:bike_buddy/features/auth/presentation/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all initial UI elements', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows loading state when auth is in progress', (tester) async {
      // Mock loading state
      mockAuthNotifier.state = const AuthState(isEmailLoading: true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Button should be disabled (onPressed is null)
      final signInButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(signInButton.onPressed, isNull);
    });

    testWidgets('shows error message when auth fails', (tester) async {
      // Mock error state
      mockAuthNotifier.state = const AuthState(error: 'Invalid credentials');

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
