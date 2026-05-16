import 'dart:math';
import '../services/location_service.dart';

class DiscoveryShop {
  final String id;
  final String name;
  final String address;
  final int totalBikes;
  final int activeRentalQuantity;
  final int availableBikes;
  final int ratePerHour;
  final double rating;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasAvailableBikes => availableBikes > 0;

  const DiscoveryShop({
    required this.id,
    required this.name,
    required this.address,
    required this.totalBikes,
    required this.activeRentalQuantity,
    required this.availableBikes,
    required this.ratePerHour,
    required this.rating,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  DiscoveryShop withDistanceFrom(UserLocation location) {
    if (!hasLocation) return this;

    return DiscoveryShop(
      id: id,
      name: name,
      address: address,
      totalBikes: totalBikes,
      activeRentalQuantity: activeRentalQuantity,
      availableBikes: availableBikes,
      ratePerHour: ratePerHour,
      rating: rating,
      latitude: latitude,
      longitude: longitude,
      distanceKm: _distanceKm(
        location.latitude,
        location.longitude,
        latitude!,
        longitude!,
      ),
    );
  }

  factory DiscoveryShop.fromMap(Map<String, dynamic> map) {
    return DiscoveryShop(
      id: map['shop_id'] as String? ?? map['id'] as String,
      name: map['name'] as String? ?? 'Bike station',
      address: map['address'] as String? ?? '',
      totalBikes: map['total_bikes'] as int? ?? 0,
      activeRentalQuantity: map['active_rental_quantity'] as int? ?? 0,
      availableBikes: map['available_bikes'] as int? ?? 0,
      ratePerHour: map['rate_per_hour'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
    );
  }
}

double _distanceKm(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  const earthRadiusKm = 6371.0;
  final latitudeDelta = _degreesToRadians(endLatitude - startLatitude);
  final longitudeDelta = _degreesToRadians(endLongitude - startLongitude);
  final startLatitudeRadians = _degreesToRadians(startLatitude);
  final endLatitudeRadians = _degreesToRadians(endLatitude);

  final haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2) +
      cos(startLatitudeRadians) *
          cos(endLatitudeRadians) *
          sin(longitudeDelta / 2) *
          sin(longitudeDelta / 2);
  final centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
  return earthRadiusKm * centralAngle;
}

double _degreesToRadians(double degrees) => degrees * pi / 180;
