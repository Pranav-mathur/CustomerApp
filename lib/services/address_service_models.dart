// // services/address_service_models.dart
// // RENAME THIS FILE OR UPDATE THE IMPORTS
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/address_models.dart';
//
// class AddressService {
//   // Replace with your actual API base URL
//   static const String baseUrl = 'http://100.27.221.127:3000/api/v1';
//
//   Future<List<AddressModel>> getAddresses(String authToken) async {
//     try {
//       final url = Uri.parse('$baseUrl/addresses');
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $authToken',
//         },
//       );
//
//       print(authToken);
//
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         final addressResponse = AddressListResponse.fromJson(jsonData);
//         return addressResponse.addresses;
//       } else {
//         throw Exception('Failed to load addresses: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error fetching addresses: $e');
//     }
//   }
// }