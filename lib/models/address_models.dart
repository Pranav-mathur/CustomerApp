// // models/address_models.dart
//
// class AddressModel {
//   final String id;
//   final String street;
//   final String city;
//   final String state;
//   final String pincode;
//   final String mobile;
//   final String addressType;
//   final String label;
//   final bool isDefault;
//
//   AddressModel({
//     required this.id,
//     required this.street,
//     required this.city,
//     required this.state,
//     required this.pincode,
//     required this.mobile,
//     required this.addressType,
//     required this.label,
//     required this.isDefault,
//   });
//
//   factory AddressModel.fromJson(Map<String, dynamic> json) {
//     return AddressModel(
//       id: json['id'] ?? '',
//       street: json['street'] ?? '',
//       city: json['city'] ?? '',
//       state: json['state'] ?? '',
//       pincode: json['pincode'] ?? '',
//       mobile: json['mobile'] ?? '',
//       addressType: json['address_type'] ?? 'home',
//       label: json['label'] ?? '',
//       isDefault: json['is_default'] ?? false,
//     );
//   }
//
//   String get fullAddress => '$street, $city, $state - $pincode';
//
//   String get shortAddress => '$label - $street, $city';
// }
//
// class AddressListResponse {
//   final List<AddressModel> addresses;
//
//   AddressListResponse({required this.addresses});
//
//   factory AddressListResponse.fromJson(Map<String, dynamic> json) {
//     final addressList = json['addresses'] as List<dynamic>? ?? [];
//     return AddressListResponse(
//       addresses: addressList.map((addr) => AddressModel.fromJson(addr)).toList(),
//     );
//   }
// }