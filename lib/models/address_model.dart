// models/address_model.dart

class AddressModel {
  String? houseFlatBlock;
  String? apartmentRoadArea;
  String? streetAndCity;
  String? addressType; // 'Home', 'Office', 'Other'

  AddressModel({
    this.houseFlatBlock,
    this.apartmentRoadArea,
    this.streetAndCity,
    this.addressType,
  });

  // Check if address is complete
  bool get isComplete =>
      houseFlatBlock != null &&
          houseFlatBlock!.isNotEmpty &&
          apartmentRoadArea != null &&
          apartmentRoadArea!.isNotEmpty &&
          streetAndCity != null &&
          streetAndCity!.isNotEmpty &&
          addressType != null;

  // Check if address has any data
  bool get hasData =>
      (houseFlatBlock != null && houseFlatBlock!.isNotEmpty) ||
          (apartmentRoadArea != null && apartmentRoadArea!.isNotEmpty) ||
          (streetAndCity != null && streetAndCity!.isNotEmpty) ||
          addressType != null;

  // Get formatted address string
  String get formattedAddress {
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

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'houseFlatBlock': houseFlatBlock,
    'apartmentRoadArea': apartmentRoadArea,
    'streetAndCity': streetAndCity,
    'addressType': addressType,
  };

  // Create from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      houseFlatBlock: json['houseFlatBlock'],
      apartmentRoadArea: json['apartmentRoadArea'],
      streetAndCity: json['streetAndCity'],
      addressType: json['addressType'],
    );
  }

  // Copy with method
  AddressModel copyWith({
    String? houseFlatBlock,
    String? apartmentRoadArea,
    String? streetAndCity,
    String? addressType,
  }) {
    return AddressModel(
      houseFlatBlock: houseFlatBlock ?? this.houseFlatBlock,
      apartmentRoadArea: apartmentRoadArea ?? this.apartmentRoadArea,
      streetAndCity: streetAndCity ?? this.streetAndCity,
      addressType: addressType ?? this.addressType,
    );
  }

  // Reset address
  void reset() {
    houseFlatBlock = null;
    apartmentRoadArea = null;
    streetAndCity = null;
    addressType = null;
  }
}