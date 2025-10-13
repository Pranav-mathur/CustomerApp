// models/user_profile_model.dart

class UserProfileModel {
  final String profileId;
  final String profileName;
  final String mobileNumber;
  final String gender;
  final String? imageUrl;
  final List<ProfileMeasurement> measurements;

  UserProfileModel({
    required this.profileId,
    required this.profileName,
    required this.mobileNumber,
    required this.gender,
    this.imageUrl,
    required this.measurements,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      profileId: json['profileId'] ?? '',
      profileName: json['profileName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      gender: json['gender'] ?? '',
      imageUrl: json['imageUrl'],
      measurements: (json['measurements'] as List?)
          ?.map((m) => ProfileMeasurement.fromJson(m))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'profileName': profileName,
      'mobileNumber': mobileNumber,
      'gender': gender,
      'imageUrl': imageUrl,
      'measurements': measurements.map((m) => m.toJson()).toList(),
    };
  }
}

class ProfileMeasurement {
  final String type;
  final String value;
  final String? addedBy;
  final String? addedAt;
  final String? lastUpdated;

  ProfileMeasurement({
    required this.type,
    required this.value,
    this.addedBy,
    this.addedAt,
    this.lastUpdated,
  });

  factory ProfileMeasurement.fromJson(Map<String, dynamic> json) {
    return ProfileMeasurement(
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      addedBy: json['added_by'],
      addedAt: json['added_at'],
      lastUpdated: json['last_updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'added_by': addedBy,
      'added_at': addedAt,
      'last_updated': lastUpdated,
    };
  }
}