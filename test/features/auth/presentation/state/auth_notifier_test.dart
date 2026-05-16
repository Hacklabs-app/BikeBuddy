import 'package:bike_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bike_buddy/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthNotifier', () {
    test('signIn success updates state', () async {
      when(() =>
              mockRepo.signIn(email: 'test@example.com', password: 'password'))
          .thenAnswer((_) async => {});
      final container = makeContainer();

      final result = await container
          .read(authNotifierProvider.notifier)
          .signIn('test@example.com', 'password');

      expect(result, true);
      expect(container.read(authNotifierProvider).isLoading, false);
      expect(container.read(authNotifierProvider).error, null);
    });

    test('signIn failure updates state with error', () async {
      when(() =>
              mockRepo.signIn(email: 'test@example.com', password: 'password'))
          .thenThrow(const AuthException('Invalid login credentials'));
      final container = makeContainer();

      final result = await container
          .read(authNotifierProvider.notifier)
          .signIn('test@example.com', 'password');

      expect(result, false);
      expect(container.read(authNotifierProvider).isEmailLoading, false);
      expect(container.read(authNotifierProvider).error,
          contains('Incorrect email/password'));
    });

    test('sendPasswordReset calls repository', () async {
      when(() => mockRepo.sendPasswordReset('test@example.com'))
          .thenAnswer((_) async => {});
      final container = makeContainer();

      final result = await container
          .read(authNotifierProvider.notifier)
          .sendPasswordReset('test@example.com');

      expect(result, true);
      verify(() => mockRepo.sendPasswordReset('test@example.com')).called(1);
    });
  });
}
