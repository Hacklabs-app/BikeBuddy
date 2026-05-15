import 'dart:async';

import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
  });

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
  const LocationRequestResult._({
    required this.status,
    this.location,
  });

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
        await Geolocator.openLocationSettings();
        return LocationRequestResult.failed(
          LocationRequestStatus.serviceDisabled,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 12),
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
