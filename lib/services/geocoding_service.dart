// lib/services/geocoding_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  // Important: Add a user agent as per Nominatim usage policy
  static const Map<String, String> _headers = {
    'User-Agent': 'FlutterLocationApp/1.0',
  };

  // Reverse geocoding - Get address from coordinates
  Future<LocationData?> reverseGeocode(LatLng coordinates) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?lat=${coordinates.latitude}&lon=${coordinates.longitude}&format=json&addressdetails=1',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseLocationData(coordinates, data);
      }
      return null;
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return null;
    }
  }

  // Forward geocoding - Search for places
  Future<List<LocationData>> searchLocation(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final lat = double.parse(item['lat']);
          final lon = double.parse(item['lon']);
          return _parseLocationData(LatLng(lat, lon), item);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error in search: $e');
      return [];
    }
  }

  // Parse API response to LocationData
  LocationData _parseLocationData(LatLng coordinates, Map<String, dynamic> data) {
    final address = data['address'] ?? {};

    return LocationData(
      coordinates: coordinates,
      displayName: data['display_name'],
      address: address['road'] ?? address['suburb'] ?? address['neighbourhood'],
      city: address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'],
      state: address['state'],
      country: address['country'],
      postalCode: address['postcode'],
    );
  }
}