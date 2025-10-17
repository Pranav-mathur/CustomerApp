// models/address_model.dart

class AddressModel {
  String? id;
  String street;
  String city;
  String state;
  String pincode;
  String mobile;
  String addressType;
  String label;
  bool isDefault;

  AddressModel({
    this.id,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.mobile,
    required this.addressType,
    this.label = '',
    this.isDefault = false,
  });

  // Check if address is complete
  bool get isComplete =>
      street.isNotEmpty &&
          city.isNotEmpty &&
          state.isNotEmpty &&
          pincode.isNotEmpty &&
          mobile.isNotEmpty &&
          addressType.isNotEmpty;

  // Get formatted address string
  String get formattedAddress {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'street': street,
    'city': city,
    'state': state,
    'pincode': pincode,
    'mobile': mobile,
    'address_type': addressType,
    'label': label,
    'is_default': isDefault,
  };

  // Create from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? json['_id'],
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      mobile: json['mobile'] ?? '',
      addressType: json['address_type'] ?? '',
      label: json['label'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  // Copy with method
  AddressModel copyWith({
    String? id,
    String? street,
    String? city,
    String? state,
    String? pincode,
    String? mobile,
    String? addressType,
    String? label,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      mobile: mobile ?? this.mobile,
      addressType: addressType ?? this.addressType,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}