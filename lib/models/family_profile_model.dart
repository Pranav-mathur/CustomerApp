// models/family_profile_model.dart

class FamilyProfileModel {
  String? id;
  String? name;
  String? mobile;
  String? relationship;
  String? profileImagePath;
  FamilyAddressModel? address;
  List<MeasurementModel> measurements;
  DateTime? createdAt;

  FamilyProfileModel({
    this.id,
    this.name,
    this.mobile,
    this.relationship,
    this.profileImagePath,
    this.address,
    List<MeasurementModel>? measurements,
    this.createdAt,
  }) : measurements = measurements ?? [];

  bool get isComplete =>
      name != null &&
          name!.isNotEmpty &&
          mobile != null &&
          mobile!.isNotEmpty &&
          relationship != null;

  bool get hasData =>
      (name != null && name!.isNotEmpty) ||
          (mobile != null && mobile!.isNotEmpty) ||
          relationship != null ||
          profileImagePath != null ||
          (address != null && address!.hasData) ||
          measurements.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobile': mobile,
    'relationship': relationship,
    'profileImagePath': profileImagePath,
    'address': address?.toJson(),
    'measurements': measurements.map((m) => m.toJson()).toList(),
    'createdAt': createdAt?.toIso8601String(),
  };

  factory FamilyProfileModel.fromJson(Map<String, dynamic> json) {
    return FamilyProfileModel(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      relationship: json['relationship'],
      profileImagePath: json['profileImagePath'],
      address: json['address'] != null
          ? FamilyAddressModel.fromJson(json['address'])
          : null,
      measurements: json['measurements'] != null
          ? (json['measurements'] as List)
          .map((m) => MeasurementModel.fromJson(m))
          .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

class FamilyAddressModel {
  String? houseFlatBlock;
  String? apartmentRoadArea;
  String? streetAndCity;

  FamilyAddressModel({
    this.houseFlatBlock,
    this.apartmentRoadArea,
    this.streetAndCity,
  });

  bool get hasData =>
      (houseFlatBlock != null && houseFlatBlock!.isNotEmpty) ||
          (apartmentRoadArea != null && apartmentRoadArea!.isNotEmpty) ||
          (streetAndCity != null && streetAndCity!.isNotEmpty);

  bool get isComplete =>
      houseFlatBlock != null &&
          houseFlatBlock!.isNotEmpty &&
          apartmentRoadArea != null &&
          apartmentRoadArea!.isNotEmpty &&
          streetAndCity != null &&
          streetAndCity!.isNotEmpty;

  String get fullAddress {
    List<String> parts = [];
    if (houseFlatBlock != null && houseFlatBlock!.isNotEmpty) {
      parts.add(houseFlatBlock!);
    }
    if (apartmentRoadArea != null && apartmentRoadArea!.isNotEmpty) {
      parts.add(apartmentRoadArea!);
    }
    if (streetAndCity != null && streetAndCity!.isNotEmpty) {
      parts.add(streetAndCity!);
    }
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'houseFlatBlock': houseFlatBlock,
    'apartmentRoadArea': apartmentRoadArea,
    'streetAndCity': streetAndCity,
  };

  factory FamilyAddressModel.fromJson(Map<String, dynamic> json) {
    return FamilyAddressModel(
      houseFlatBlock: json['houseFlatBlock'],
      apartmentRoadArea: json['apartmentRoadArea'],
      streetAndCity: json['streetAndCity'],
    );
  }
}

class MeasurementModel {
  final String id;
  final String name;
  final String unit;
  final String value; // Add this field

  MeasurementModel({
    required this.id,
    required this.name,
    required this.unit,
    this.value = '', // Add default value
  });

  MeasurementModel copyWith({
    String? id,
    String? name,
    String? unit,
    String? value,
  }) {
    return MeasurementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'value': value,
    };
  }

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'cm',
      value: json['value'] ?? '',
    );
  }
}