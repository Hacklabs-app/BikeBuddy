import 'package:bike_buddy/core/services/storage_service.dart';
import 'package:bike_buddy/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
  });

  ProviderContainer makeContainer(MockStorageService storage) {
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        // We need to override hasSeenOnboardingProvider as it's a StateProvider
        hasSeenOnboardingProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('OnboardingNotifier', () {
    test('initial state contains expected pages', () async {
      final container = makeContainer(mockStorageService);
      final listener = Listener<AsyncValue<List<Object>>>();

      container.listen(
        onboardingProvider,
        listener.call,
        fireImmediately: true,
      );

      await container.read(onboardingProvider.future);
      final state = container.read(onboardingProvider);
      expect(state.value?.length, 3);
      expect(state.value?[0].title, contains('Find Nearest Bikes'));
    });

    test('completeOnboarding updates storage and state', () async {
      final container = makeContainer(mockStorageService);
      when(() => mockStorageService.setHasSeenOnboarding())
          .thenAnswer((_) async => true);

      expect(container.read(hasSeenOnboardingProvider), false);

      await container.read(onboardingProvider.notifier).completeOnboarding();

      verify(() => mockStorageService.setHasSeenOnboarding()).called(1);
      expect(container.read(hasSeenOnboardingProvider), true);
    });
  });
}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}
