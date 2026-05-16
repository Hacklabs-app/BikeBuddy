import 'package:bike_buddy/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:bike_buddy/features/auth/presentation/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bike_buddy/shared/providers/auth_provider.dart';
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
        home: RoleSelectionScreen(),
      ),
    );
  }

  group('RoleSelectionScreen Widget Tests', () {
    testWidgets('renders Rider and Owner cards', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('RIDER'), findsOneWidget);
      expect(find.text('STATION OWNER'), findsOneWidget);
      expect(find.text('Join the ride'), findsOneWidget);
    });

    testWidgets('Sign Out button is hidden for guests', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoggedIn: false));
      await tester.pumpAndSettle();

      expect(find.text('SIGN OUT'), findsNothing);
    });

    testWidgets('Sign Out button is visible for logged in users',
        (tester) async {
      await tester.pumpWidget(createTestWidget(isLoggedIn: true));
      await tester.pumpAndSettle();

      expect(find.text('SIGN OUT'), findsOneWidget);
    });
  });
}

// Helper to create a dummy user
sb.User mocktailUser() => sb.User(
      id: 'test-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'aud',
      createdAt: DateTime.now().toIso8601String(),
    );
