import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'trip_service.dart';

class LocationService {
  final TripService _tripService = TripService();
  StreamSubscription<Position>? _positionSub;

  bool get isTracking => _positionSub != null;

  /// Call this right after a trip is created.
  /// Requests permission, then starts streaming GPS and writing to Firestore.
  Future<void> startTracking(String tripId) async {
    // 1. Ensure permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return; // Cannot track without permission
    }

    // 2. Check location services
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // 3. Start streaming every 5 seconds or 10 metres
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // metres
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      _tripService.updateLocation(tripId, pos.latitude, pos.longitude);
    });
  }

  /// Call when the trip ends.
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// One-shot current position (for centering map).
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
