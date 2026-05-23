import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/location_service.dart';
import '../../data/datasources/shop_discovery_datasource.dart';
import '../../domain/entities/discovery_shop.dart';

final shopDiscoveryDatasourceProvider =
    Provider<ShopDiscoveryDatasource>((ref) {
  return ShopDiscoveryDatasource(Supabase.instance.client);
});

final currentLocationProvider = StateProvider<UserLocation?>((ref) => null);

final locationNoticeProvider = StateProvider<String?>((ref) => null);

final shopDiscoveryProvider =
    AsyncNotifierProvider<ShopDiscoveryNotifier, List<DiscoveryShop>>(
  ShopDiscoveryNotifier.new,
);

class ShopDiscoveryNotifier extends AsyncNotifier<List<DiscoveryShop>> {
  RealtimeChannel? _channel;

  @override
  Future<List<DiscoveryShop>> build() async {
    _subscribeToRentalChanges();

    ref.onDispose(() {
      final channel = _channel;
      if (channel != null) {
        Supabase.instance.client.removeChannel(channel);
      }
    });

    final shops = await ref.read(shopDiscoveryDatasourceProvider).fetchShops();
    return _sortByDistance(shops);
  }

  Future<void> requestLocation() async {
    final result = await locationService.requestCurrentLocation();
    final location = result.location;

    if (location != null) {
      ref.read(currentLocationProvider.notifier).state = location;
      ref.read(locationNoticeProvider.notifier).state = null;
      final currentShops = state.valueOrNull;
      if (currentShops != null) {
        state = AsyncData(_sortByDistance(currentShops));
      } else {
        ref.invalidateSelf();
      }
      return;
    }

    ref.read(currentLocationProvider.notifier).state = null;
    ref.read(locationNoticeProvider.notifier).state =
        _locationMessage(result.status);
  }

  void showAllShops() {
    ref.read(currentLocationProvider.notifier).state = null;
    ref.read(locationNoticeProvider.notifier).state = null;
    ref.invalidateSelf();
  }

  List<DiscoveryShop> _sortByDistance(List<DiscoveryShop> shops) {
    final location = ref.read(currentLocationProvider);
    if (location == null) return shops;

    final shopsWithDistance =
        shops.map((shop) => shop.withDistanceFrom(location)).toList();
    shopsWithDistance.sort((a, b) {
      final first = a.distanceKm ?? double.maxFinite;
      final second = b.distanceKm ?? double.maxFinite;
      return first.compareTo(second);
    });
    return shopsWithDistance;
  }

  void _subscribeToRentalChanges() {
    if (_channel != null) return;

    _channel = Supabase.instance.client
        .channel('shop-discovery-rentals')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rentals',
          callback: (_) => ref.invalidateSelf(),
        )
        .subscribe();
  }
}

String _locationMessage(LocationRequestStatus status) {
  switch (status) {
    case LocationRequestStatus.serviceDisabled:
      return 'Turn on device location, then tap Use location again.';
    case LocationRequestStatus.permissionDenied:
      return 'Allow location permission to sort shops near you.';
    case LocationRequestStatus.timedOut:
      return 'Location took too long. Try again near a window or outside.';
    case LocationRequestStatus.unavailable:
      return 'Could not get your location. Showing all shops for now.';
    case LocationRequestStatus.ready:
      return '';
  }
}
