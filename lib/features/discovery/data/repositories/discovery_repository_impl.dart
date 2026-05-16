import '../../../../core/models/discovery_shop.dart';
import '../../domain/repositories/discovery_repository.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  @override
  Future<List<DiscoveryShop>> getShops() async {
    // Simulating a network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockShops;
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
