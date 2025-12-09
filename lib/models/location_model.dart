// lib/models/location_model.dart

import 'package:latlong2/latlong.dart';

class LocationData {
  final LatLng coordinates;
  final String? displayName;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  LocationData({
    required this.coordinates,
    this.displayName,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  String get fullAddress {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    List<String> parts = [];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  String get shortAddress {
    List<String> parts = [];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'displayName': displayName,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      coordinates: LatLng(json['latitude'], json['longitude']),
      displayName: json['displayName'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
    );
  }
}