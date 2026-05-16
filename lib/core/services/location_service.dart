import 'dart:async';

import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationRequestStatus {
  ready,
  permissionDenied,
  serviceDisabled,
  timedOut,
  unavailable,
}

class LocationRequestResult {
  const LocationRequestResult._({required this.status, this.location});

  final LocationRequestStatus status;
  final UserLocation? location;

  bool get hasLocation => location != null;

  factory LocationRequestResult.ready(UserLocation location) {
    return LocationRequestResult._(
      status: LocationRequestStatus.ready,
      location: location,
    );
  }

  factory LocationRequestResult.failed(LocationRequestStatus status) {
    return LocationRequestResult._(status: status);
  }
}

class LocationService {
  Future<LocationRequestResult> requestCurrentLocation() async {
    try {
      final permission = await _ensurePermission();
      if (!permission) {
        return LocationRequestResult.failed(
          LocationRequestStatus.permissionDenied,
        );
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        // Only open settings if not enabled
        await Geolocator.openLocationSettings();
        return LocationRequestResult.failed(
          LocationRequestStatus.serviceDisabled,
        );
      }

      // 1. Try last known position first (Instant)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationRequestResult.ready(
          UserLocation(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          ),
        );
      }

      // 2. Fallback to current position (Slight delay)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy:
              LocationAccuracy.medium, // Lower accuracy is faster for discovery
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationRequestResult.ready(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on TimeoutException {
      return LocationRequestResult.failed(LocationRequestStatus.timedOut);
    } catch (_) {
      return LocationRequestResult.failed(LocationRequestStatus.unavailable);
    }
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> canUseLocationWithoutPrompt() async {
    final permission = await Geolocator.checkPermission();
    final hasPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!hasPermission) return false;

    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

final locationService = LocationService();
