import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/discovery_shop.dart';
import '../../../../core/services/location_service.dart';

enum ShopFilter { stock, price, rating, nearest }

class DiscoveryState {
  final List<DiscoveryShop> allShops;
  final List<DiscoveryShop> filteredShops;
  final ShopFilter filter;
  final String searchQuery;
  final UserLocation? userLocation;

  DiscoveryState({
    required this.allShops,
    required this.filteredShops,
    required this.filter,
    this.searchQuery = '',
    this.userLocation,
  });

  DiscoveryState copyWith({
    List<DiscoveryShop>? allShops,
    List<DiscoveryShop>? filteredShops,
    ShopFilter? filter,
    String? searchQuery,
    UserLocation? userLocation,
  }) {
    return DiscoveryState(
      allShops: allShops ?? this.allShops,
      filteredShops: filteredShops ?? this.filteredShops,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

class DiscoveryNotifier extends AutoDisposeAsyncNotifier<DiscoveryState> {
  @override
  Future<DiscoveryState> build() async {
    final shops = _mockShops;
    final processed = _process(shops, ShopFilter.stock, '');
    
    return DiscoveryState(
      allShops: shops,
      filteredShops: processed,
      filter: ShopFilter.stock,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 800));
    ref.invalidateSelf();
  }

  void updateSearch(String query) {
    state.whenData((current) {
      final processed = _process(
        current.allShops, 
        current.filter, 
        query, 
        userLocation: current.userLocation,
      );
      state = AsyncData(current.copyWith(
        filteredShops: processed,
        searchQuery: query,
      ));
    });
  }

  void updateFilter(ShopFilter filter) {
    state.whenData((current) {
      final processed = _process(
        current.allShops, 
        filter, 
        current.searchQuery, 
        userLocation: current.userLocation,
      );
      state = AsyncData(current.copyWith(
        filteredShops: processed,
        filter: filter,
      ));
    });
  }

  void setFilter(ShopFilter filter) {
    state.whenData((current) {
      state = AsyncData(current.copyWith(filter: filter));
    });
  }

  Future<void> requestLocationAndSort() async {
    // 1. Immediately switch UI to nearest mode
    setFilter(ShopFilter.nearest);

    state.whenData((current) async {
      // 2. Fetch location with optimized speed
      final result = await locationService.requestCurrentLocation();
      
      if (result.hasLocation) {
        final loc = result.location!;
        final processed = _process(
          current.allShops, 
          ShopFilter.nearest, 
          current.searchQuery, 
          userLocation: loc,
        );
        state = AsyncData(current.copyWith(
          filteredShops: processed,
          filter: ShopFilter.nearest,
          userLocation: loc,
        ));
      }
    });
  }

  List<DiscoveryShop> _process(
    List<DiscoveryShop> list, 
    ShopFilter filter, 
    String query, 
    {UserLocation? userLocation}
  ) {
    // 1. Search Filtering
    var result = list;
    if (query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      result = list.where((s) {
        return s.name.toLowerCase().contains(lowercaseQuery) ||
               s.address.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    // 2. Sorting
    final sorted = List<DiscoveryShop>.from(result);
    switch (filter) {
      case ShopFilter.stock:
        sorted.sort((a, b) => b.availableBikes.compareTo(a.availableBikes));
        break;
      case ShopFilter.price:
        sorted.sort((a, b) => a.ratePerHour.compareTo(b.ratePerHour));
        break;
      case ShopFilter.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ShopFilter.nearest:
        if (userLocation != null) {
          final withDistance = sorted.map((s) => s.withDistanceFrom(userLocation)).toList();
          withDistance.sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
          return withDistance;
        }
        break;
    }
    return sorted;
  }

  final List<DiscoveryShop> _mockShops = [
    const DiscoveryShop(
      id: '1',
      name: 'Velvet Velos',
      address: 'Downtown, 5th Ave',
      totalBikes: 20,
      activeRentalQuantity: 5,
      availableBikes: 15,
      ratePerHour: 10,
      rating: 4.8,
      latitude: -1.2833,
      longitude: 36.8167,
    ),
    const DiscoveryShop(
      id: '2',
      name: 'Neon Cycles',
      address: 'Westlands Mall',
      totalBikes: 12,
      activeRentalQuantity: 10,
      availableBikes: 2,
      ratePerHour: 15,
      rating: 4.9,
      latitude: -1.2633,
      longitude: 36.8033,
    ),
    const DiscoveryShop(
      id: '3',
      name: 'Urban Pedal',
      address: 'Kilimani Park',
      totalBikes: 30,
      activeRentalQuantity: 0,
      availableBikes: 30,
      ratePerHour: 8,
      rating: 4.5,
      latitude: -1.2933,
      longitude: 36.7833,
    ),
    const DiscoveryShop(
      id: '4',
      name: 'EcoRide Hub',
      address: 'Riverside Drive',
      totalBikes: 15,
      activeRentalQuantity: 7,
      availableBikes: 8,
      ratePerHour: 12,
      rating: 4.2,
      latitude: -1.2733,
      longitude: 36.7933,
    ),
  ];
}

final discoveryProvider =
    AutoDisposeAsyncNotifierProvider<DiscoveryNotifier, DiscoveryState>(
        DiscoveryNotifier.new);
