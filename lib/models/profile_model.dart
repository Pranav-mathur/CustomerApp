// models/profile_model.dart

import 'address_model.dart';
import 'family_profile_model.dart'; // Import for MeasurementModel

class ProfileModel {
  String? name;
  String? gender;
  String? email;
  String? profileImagePath;
  AddressModel? address;
  List<MeasurementModel> measurements;

  ProfileModel({
    this.name,
    this.gender,
    this.email,
    this.profileImagePath,
    this.address,
    List<MeasurementModel>? measurements, // Make it nullable in constructor
  }) : measurements = measurements ?? []; // Initialize in initializer list

  // Check if profile is complete (including address)
  bool get isComplete =>
      name != null &&
          name!.isNotEmpty &&
          gender != null &&
          email != null &&
          email!.isNotEmpty &&
          address != null &&
          address!.isComplete;

  // Check if basic profile (without address) is complete
  bool get isBasicProfileComplete =>
      name != null &&
          name!.isNotEmpty &&
          gender != null &&
          email != null &&
          email!.isNotEmpty;

  // Check if profile has any data
  bool get hasData =>
      (name != null && name!.isNotEmpty) ||
          (email != null && email!.isNotEmpty) ||
          gender != null ||
          profileImagePath != null ||
          measurements.isNotEmpty;

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender,
    'email': email,
    'profileImagePath': profileImagePath,
    'address': address?.toJson(),
    'measurements': measurements.map((m) => m.toJson()).toList(),
  };

  // Create from JSON
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    List<MeasurementModel> parsedMeasurements = [];

    try {
      if (json['measurements'] != null) {
        parsedMeasurements = (json['measurements'] as List)
            .map((m) => MeasurementModel.fromJson(m as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing measurements: $e');
      parsedMeasurements = [];
    }

    return ProfileModel(
      name: json['name'],
      gender: json['gender'],
      email: json['email'],
      profileImagePath: json['profileImagePath'],
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : null,
      measurements: parsedMeasurements,
    );
  }

  // Copy with method
  ProfileModel copyWith({
    String? name,
    String? gender,
    String? email,
    String? profileImagePath,
    AddressModel? address,
    List<MeasurementModel>? measurements,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      address: address ?? this.address,
      measurements: measurements ?? List<MeasurementModel>.from(this.measurements),
    );
  }

  // Reset profile
  void reset() {
    name = null;
    gender = null;
    email = null;
    profileImagePath = null;
    address = null;
    measurements.clear();
  }
}