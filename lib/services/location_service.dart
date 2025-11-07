// services/location_service.dart

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Default location coordinates (28.2708° N, 77.0713° E)
  static const double _defaultLatitude = 28.2708;
  static const double _defaultLongitude = 77.0713;

  // Get current location with permission handling
  Future<Map<String, double>> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled - using default location');
        return {
          'latitude': _defaultLatitude,
          'longitude': _defaultLongitude,
        };
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied - using default location');
          return {
            'latitude': _defaultLatitude,
            'longitude': _defaultLongitude,
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever - using default location');
        return {
          'latitude': _defaultLatitude,
          'longitude': _defaultLongitude,
        };
      }

      debugPrint('📍 Getting current location...');

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('✅ Location obtained: ${position.latitude}, ${position.longitude}');

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

    } catch (e) {
      debugPrint('❌ Error getting location: $e - using default location');
      return {
        'latitude': _defaultLatitude,
        'longitude': _defaultLongitude,
      };
    }
  }
}