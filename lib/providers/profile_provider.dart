// providers/profile_provider.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/family_profile_model.dart';
import '../models/profile_model.dart';
import '../models/address_model.dart';
import '../models/user_profile_model.dart'; // Add this import
import '../services/profile_service.dart';
import '../services/location_service.dart';
import '../services/address_service.dart'; // Add this import

class ProfileProvider extends ChangeNotifier {
  ProfileModel _profile = ProfileModel();
  final ProfileService _profileService = ProfileService();
  final LocationService _locationService = LocationService();
  final AddressService _addressService = AddressService();

  String? _error;
  String? _profileId;
  bool _isLoading = false;

  // ============ NEW: GLOBAL ACTIVE USER PROFILE ============
  UserProfileModel? _activeUserProfile;
  AddressModel? _activeDefaultAddress;
  bool _isLoadingActiveProfile = false;

  // Getters for active profile
  UserProfileModel? get activeUserProfile => _activeUserProfile;
  AddressModel? get activeDefaultAddress => _activeDefaultAddress;
  bool get isLoadingActiveProfile => _isLoadingActiveProfile;
  bool get hasActiveProfile => _activeUserProfile != null;

  ProfileModel get profile => _profile;
  String? get error => _error;
  String? get profileId => _profileId;
  bool get isLoading => _isLoading;

  // ============ NEW: LOAD ACTIVE USER PROFILE ============
  /// Load the active user profile globally (call this once at app start)
  Future<void> loadActiveUserProfile() async {
    _isLoadingActiveProfile = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _profileService.getAllUserProfiles(),
        _addressService.getAllAddresses(),
      ]);

      final profiles = results[0] as List<UserProfileModel>?;
      final addresses = results[1] as List<AddressModel>?;

      if (profiles != null && profiles.isNotEmpty) {
        _activeUserProfile = profiles.first;
      }

      if (addresses != null && addresses.isNotEmpty) {
        _activeDefaultAddress = addresses.firstWhere(
              (addr) => addr.isDefault == true,
          orElse: () => addresses.first,
        );
      }

      _isLoadingActiveProfile = false;
      debugPrint('✅ Active User Profile Loaded: ${_activeUserProfile?.profileId}');
      debugPrint('✅ Default Address: ${_activeDefaultAddress?.addressType}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading active profile: $e');
      _isLoadingActiveProfile = false;
      notifyListeners();
    }
  }

  /// Update the active user profile
  void updateActiveUserProfile(UserProfileModel profile) {
    _activeUserProfile = profile;
    notifyListeners();
  }

  /// Update the active default address
  void updateActiveDefaultAddress(AddressModel address) {
    _activeDefaultAddress = address;
    notifyListeners();
  }

  /// Get active user data as JSON for API calls
  Map<String, dynamic> getActiveUserJson() {
    return {
      'profileId': _activeUserProfile?.profileId,
      'profileName': _activeUserProfile?.profileName,
      'mobileNumber': _activeUserProfile?.mobileNumber,
      // 'email': _activeUserProfile?.email,
      'gender': _activeUserProfile?.gender,
      'imageUrl': _activeUserProfile?.imageUrl,
      // 'addressId': _activeDefaultAddress?.addressId,
      'addressType': _activeDefaultAddress?.addressType,
      // 'fullAddress': _activeDefaultAddress?.fullAddress,
      'pincode': _activeDefaultAddress?.pincode,
      'city': _activeDefaultAddress?.city,
      'state': _activeDefaultAddress?.state,
      // 'latitude': _activeDefaultAddress?.latitude,
      // 'longitude': _activeDefaultAddress?.longitude,
    };
  }

  /// Clear active user data (useful for logout)
  void clearActiveUserProfile() {
    _activeUserProfile = null;
    _activeDefaultAddress = null;
    notifyListeners();
  }
  // ============ END OF NEW SECTION ============

  // Update name
  void updateName(String name) {
    if (_profile.name != name) {
      _profile.name = name.trim();
      notifyListeners();
    }
  }

  // Update gender
  void updateGender(String gender) {
    if (_profile.gender != gender) {
      _profile.gender = gender;
      notifyListeners();
    }
  }

  // Update email
  void updateEmail(String email) {
    if (_profile.email != email) {
      _profile.email = email.trim().toLowerCase();
      notifyListeners();
    }
  }

  // Update profile image
  void updateProfileImage(String path) {
    if (_profile.profileImagePath != path) {
      _profile.profileImagePath = path;
      notifyListeners();
    }
  }

  // Measurements methods
  void addMeasurement(MeasurementModel measurement) {
    _profile = _profile.copyWith(
      measurements: [..._profile.measurements, measurement],
    );
    notifyListeners();
  }

  void updateMeasurement(int index, MeasurementModel measurement) {
    if (index >= 0 && index < _profile.measurements.length) {
      final measurements = List<MeasurementModel>.from(_profile.measurements);
      measurements[index] = measurement;
      _profile = _profile.copyWith(measurements: measurements);
      notifyListeners();
    }
  }

  void updateMeasurementName(int index, String name) {
    if (index >= 0 && index < _profile.measurements.length) {
      final measurements = List<MeasurementModel>.from(_profile.measurements);
      measurements[index] = measurements[index].copyWith(name: name);
      _profile = _profile.copyWith(measurements: measurements);
      notifyListeners();
    }
  }

  void updateMeasurementUnit(int index, String unit) {
    if (index >= 0 && index < _profile.measurements.length) {
      final measurements = List<MeasurementModel>.from(_profile.measurements);
      measurements[index] = measurements[index].copyWith(unit: unit);
      _profile = _profile.copyWith(measurements: measurements);
      notifyListeners();
    }
  }

  // NEW: Update measurement value
  void updateMeasurementValue(int index, String value) {
    if (index >= 0 && index < _profile.measurements.length) {
      final measurements = List<MeasurementModel>.from(_profile.measurements);
      measurements[index] = measurements[index].copyWith(value: value);
      _profile = _profile.copyWith(measurements: measurements);
      notifyListeners();
    }
  }

  void removeMeasurement(int index) {
    if (index >= 0 && index < _profile.measurements.length) {
      final measurements = List<MeasurementModel>.from(_profile.measurements);
      measurements.removeAt(index);
      _profile = _profile.copyWith(measurements: measurements);
      notifyListeners();
    }
  }

  void updateMeasurements(List<MeasurementModel> measurements) {
    _profile = _profile.copyWith(measurements: measurements);
    notifyListeners();
  }

  // Initialize address if null




  // Update entire address
  void updateAddress(AddressModel address) {
    _profile.address = address;
    notifyListeners();
  }

  // Update entire profile
  void updateProfile(ProfileModel profile) {
    _profile = profile;
    notifyListeners();
  }

  // Reset profile
  void resetProfile() {
    _profile = ProfileModel();
    _error = null;
    _profileId = null;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Validate basic profile (without address)
  bool validateBasicProfile() {
    return _profile.isBasicProfileComplete;
  }

  // Validate complete profile (including address)
  bool validateProfile() {
    return _profile.isComplete;
  }

  // Validate address
  bool validateAddress() {
    return _profile.address != null && _profile.address!.isComplete;
  }

  // Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validate name
  bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  // Check if profile has any unsaved changes
  bool hasUnsavedChanges() {
    return _profile.hasData;
  }

  // Get profile completion percentage (including address)
  double getCompletionPercentage() {
    int completed = 0;
    int total = 8; // name, gender, email, image, 4 address fields

    if (_profile.name != null && _profile.name!.isNotEmpty) completed++;
    if (_profile.gender != null) completed++;
    if (_profile.email != null && _profile.email!.isNotEmpty) completed++;
    if (_profile.profileImagePath != null) completed++;

    return (completed / total) * 100;
  }

  // Get basic profile completion percentage (without address)
  double getBasicProfileCompletionPercentage() {
    int completed = 0;
    int total = 4;

    if (_profile.name != null && _profile.name!.isNotEmpty) completed++;
    if (_profile.gender != null) completed++;
    if (_profile.email != null && _profile.email!.isNotEmpty) completed++;
    if (_profile.profileImagePath != null) completed++;

    return (completed / total) * 100;
  }

  // ==================== API METHODS ====================

  // Create profile via API
  Future<bool> createProfile() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      debugPrint('📤 Starting profile creation...');

      // Fetch location silently in the background
      Map<String, double>? location;
      try {
        debugPrint('📍 Fetching location...');
        location = await _locationService.getCurrentLocation();
        if (location != null) {
          debugPrint('✅ Location fetched: ${location['latitude']}, ${location['longitude']}');
        } else {
          debugPrint('⚠️ Location not available, continuing without it');
        }
      } catch (e) {
        debugPrint('⚠️ Location fetch failed, continuing without it: $e');
        location = null;
      }

      String? uploadedImageUrl;

      // Upload profile image first if it exists
      if (_profile.profileImagePath != null && _profile.profileImagePath!.isNotEmpty) {
        debugPrint('📸 Uploading profile image...');

        try {
          final file = File(_profile.profileImagePath!);
          uploadedImageUrl = await _profileService.uploadProfileImage(file);
          debugPrint('✅ Image uploaded successfully: $uploadedImageUrl');
        } catch (e) {
          debugPrint('❌ Image upload failed: $e');
          _error = 'Failed to upload profile image: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      debugPrint('📤 Creating profile with data...');
      debugPrint('Profile Name: ${_profile.name}');
      debugPrint('Gender: ${_profile.gender}');
      debugPrint('Email: ${_profile.email}');
      debugPrint('Image URL: $uploadedImageUrl');
      debugPrint('Measurements: ${_profile.measurements.length}');
      debugPrint('Location: ${location?['latitude']}, ${location?['longitude']}');

      final result = await _profileService.createProfile(
        profileName: _profile.name ?? '',
        gender: _profile.gender ?? '',
        email: _profile.email ?? '',
        imageUrl: uploadedImageUrl,
        measurements: _profile.measurements,
        address: _profile.address,
        latitude: location?['latitude'],   // Send location if available
        longitude: location?['longitude'], // Send location if available
      );

      _isLoading = false;

      if (result != null) {
        if (result['profileId'] != null) {
          _profileId = result['profileId'];
          debugPrint('✅ Profile created with ID: $_profileId');
        }

        if (uploadedImageUrl != null) {
          _profile.profileImagePath = uploadedImageUrl;
        }

        // ============ NEW: Reload active profile after creation ============
        await loadActiveUserProfile();

        notifyListeners();
        return true;
      }

      _error = 'Failed to create profile';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error creating profile: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing profile via API
  Future<bool> updateExistingProfile() async {
    try {
      if (_profileId == null) {
        _error = 'Profile ID not found';
        notifyListeners();
        return false;
      }

      _error = null;
      _isLoading = true;
      notifyListeners();

      debugPrint('📤 Updating profile with ID: $_profileId');

      final result = await _profileService.updateProfile(
        profileId: _profileId!,
        profileName: _profile.name ?? '',
        gender: _profile.gender ?? '',
        email: _profile.email ?? '',
        imageUrl: _profile.profileImagePath,
        measurements: _profile.measurements,
        address: _profile.address,
      );

      _isLoading = false;

      if (result != null) {
        debugPrint('✅ Profile updated successfully');

        // ============ NEW: Reload active profile after update ============
        await loadActiveUserProfile();

        notifyListeners();
        return true;
      }

      _error = 'Failed to update profile';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load profile by ID from API
  Future<bool> loadProfile(String profileId) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      debugPrint('📥 Loading profile with ID: $profileId');

      final result = await _profileService.getProfile(profileId);

      _isLoading = false;

      if (result != null) {
        _profileId = profileId;
        // Parse and update the profile from result
        // You'll need to implement parsing logic based on your API response
        debugPrint('✅ Profile loaded successfully');
        notifyListeners();
        return true;
      }

      _error = 'Failed to load profile';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get all profiles from API
  Future<List<dynamic>?> getAllProfiles() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      debugPrint('📥 Fetching all profiles...');

      final profiles = await _profileService.getAllProfiles();

      _isLoading = false;
      notifyListeners();

      if (profiles != null) {
        debugPrint('✅ Fetched ${profiles.length} profiles');
        return profiles;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching profiles: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Delete profile by ID
  Future<bool> deleteProfile(String profileId) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      debugPrint('🗑️ Deleting profile with ID: $profileId');

      final success = await _profileService.deleteProfile(profileId);

      _isLoading = false;

      if (success) {
        debugPrint('✅ Profile deleted successfully');
        // If deleting current profile, reset
        if (_profileId == profileId) {
          resetProfile();
        }
        notifyListeners();
        return true;
      }

      _error = 'Failed to delete profile';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting profile: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearProfileData() {
    _profile = ProfileModel();
    _error = null;
    _profileId = null;
    _isLoading = false;
    notifyListeners();
    debugPrint('✅ Profile data cleared to initial state');
  }
}