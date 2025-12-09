// lib/providers/location_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import '../services/location_service_v2.dart';
import '../services/geocoding_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();

  // Selected location data
  LocationData? _selectedLocation;
  LocationData? get selectedLocation => _selectedLocation;

  // Map camera position
  LatLng _currentMapCenter = LatLng(12.9716, 77.5946); // Default: Bangalore
  LatLng get currentMapCenter => _currentMapCenter;

  // Loading states
  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  bool _isGeocodingAddress = false;
  bool get isGeocodingAddress => _isGeocodingAddress;

  // Search results
  List<LocationData> _searchResults = [];
  List<LocationData> get searchResults => _searchResults;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _debounceTimer;

  // Update map center position (called when map moves)
  void updateMapCenter(LatLng position) {
    _currentMapCenter = position;

    // Debounce geocoding to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocodeCurrentPosition();
    });
  }

  // Get address for current map center
  Future<void> _reverseGeocodeCurrentPosition() async {
    _isGeocodingAddress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final locationData = await _geocodingService.reverseGeocode(_currentMapCenter);

      if (locationData != null) {
        _selectedLocation = locationData;
        _errorMessage = null;
      } else {
        _errorMessage = 'Unable to get address for this location';
      }
    } catch (e) {
      _errorMessage = 'Error getting address: $e';
    } finally {
      _isGeocodingAddress = false;
      notifyListeners();
    }
  }

  // Get current device location
  Future<bool> getCurrentLocation() async {
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        _currentMapCenter = position;
        await _reverseGeocodeCurrentPosition();
        _isLoadingLocation = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Unable to get your current location';
        _isLoadingLocation = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoadingLocation = false;
      notifyListeners();
      return false;
    }
  }

  // Search for location
  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _geocodingService.searchLocation(query);
      notifyListeners();
    } catch (e) {
      print('Error searching location: $e');
      _searchResults = [];
      notifyListeners();
    }
  }

  // Select location from search results
  void selectSearchResult(LocationData location) {
    _currentMapCenter = location.coordinates;
    _selectedLocation = location;
    _searchResults = [];
    notifyListeners();
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}