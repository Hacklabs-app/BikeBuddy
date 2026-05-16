import 'package:bike_buddy/core/models/discovery_shop.dart';
import 'package:bike_buddy/core/services/location_service.dart';
import 'package:bike_buddy/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:bike_buddy/features/discovery/presentation/state/discovery_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockDiscoveryRepository mockRepo;

  final testShops = [
    const DiscoveryShop(
      id: '1',
      name: 'Shop A',
      address: 'Address A',
      totalBikes: 10,
      activeRentalQuantity: 0,
      availableBikes: 10,
      ratePerHour: 10,
      rating: 4.5,
      latitude: 0,
      longitude: 0,
    ),
    const DiscoveryShop(
      id: '2',
      name: 'Shop B',
      address: 'Address B',
      totalBikes: 10,
      activeRentalQuantity: 0,
      availableBikes: 5,
      ratePerHour: 5,
      rating: 4.9,
      latitude: 1,
      longitude: 1,
    ),
  ];

  setUp(() {
    mockRepo = MockDiscoveryRepository();
    registerFallbackValue(const UserLocation(latitude: 0, longitude: 0));
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(mockRepo),
        // locationService is a global variable in location_service.dart,
        // we might need to change how it's accessed if we want to mock it properly.
        // For now, let's see if we can use it as is or if we need to wrap it.
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('DiscoveryNotifier', () {
    test('initial build loads shops and sorts by stock', () async {
      when(() => mockRepo.getShops()).thenAnswer((_) async => testShops);
      final container = makeContainer();

      await container.read(discoveryProvider.future);
      final state = container.read(discoveryProvider).value!;

      expect(state.allShops.length, 2);
      expect(state.filter, ShopFilter.stock);
      // Shop A has 10 bikes, Shop B has 5. Stock sort is descending.
      expect(state.filteredShops[0].id, '1');
    });

    test('updateFilter changes sorting', () async {
      when(() => mockRepo.getShops()).thenAnswer((_) async => testShops);
      final container = makeContainer();
      await container.read(discoveryProvider.future);

      container.read(discoveryProvider.notifier).updateFilter(ShopFilter.price);
      final state = container.read(discoveryProvider).value!;

      expect(state.filter, ShopFilter.price);
      // Shop B is cheaper ($5) than Shop A ($10)
      expect(state.filteredShops[0].id, '2');
    });

    test('updateSearch filters shops', () async {
      when(() => mockRepo.getShops()).thenAnswer((_) async => testShops);
      final container = makeContainer();
      await container.read(discoveryProvider.future);

      container.read(discoveryProvider.notifier).updateSearch('Shop B');
      final state = container.read(discoveryProvider).value!;

      expect(state.filteredShops.length, 1);
      expect(state.filteredShops[0].name, 'Shop B');
    });
    group('Sorting Logic', () {
      test('rating sort is descending', () async {
        when(() => mockRepo.getShops()).thenAnswer((_) async => testShops);
        final container = makeContainer();
        await container.read(discoveryProvider.future);

        container
            .read(discoveryProvider.notifier)
            .updateFilter(ShopFilter.rating);
        final state = container.read(discoveryProvider).value!;

        // Shop B has 4.9, Shop A has 4.5
        expect(state.filteredShops[0].id, '2');
      });
    });
  });
}
