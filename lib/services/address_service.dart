// services/address_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import 'auth_service.dart';

class AddressService {
  final String baseUrl = "http://100.27.221.127:3000/api/v1";
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    print(token);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all addresses
  Future<List<AddressModel>?> getAllAddresses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/addresses'),
        headers: headers,
      );
      print(response.body);

      debugPrint('📍 Get Addresses Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addressList = data['addresses'] as List;
        return addressList.map((json) => AddressModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else {
        throw Exception('Failed to load addresses');
      }
    } catch (e) {
      debugPrint('❌ Error in getAllAddresses: $e');
      rethrow;
    }
  }

  // Add new address
  Future<AddressModel?> addAddress({
    required String street,
    required String city,
    required String state,
    required String pincode,
    required String mobile,
    required String addressType,
    required String label,
    required bool isDefault,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = {
        'street': street,
        'city': city,
        'state': state,
        'pincode': pincode,
        'mobile': mobile,
        'address_type': addressType,
        'label': label,
        'is_default': isDefault,
      };

      debugPrint('📤 Adding address with body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/addresses'),
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('📍 Add Address Response: ${response.statusCode}');
      debugPrint('📍 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return AddressModel.fromJson(data['address']);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      debugPrint('❌ Error in addAddress: $e');
      rethrow;
    }
  }

  // Update existing address
  Future<AddressModel?> updateAddress({
    required String addressId,
    String? street,
    String? city,
    String? state,
    String? pincode,
    String? mobile,
    String? addressType,
    String? label,
    bool? isDefault,
  }) async {
    try {
      final headers = await _getHeaders();

      // Build body with only provided fields
      final Map<String, dynamic> body = {};
      if (street != null) body['street'] = street;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (pincode != null) body['pincode'] = pincode;
      if (mobile != null) body['mobile'] = mobile;
      if (addressType != null) body['address_type'] = addressType;
      if (label != null) body['label'] = label;
      if (isDefault != null) body['is_default'] = isDefault;

      debugPrint('📤 Updating address $addressId with body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/addresses/$addressId'),
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('📍 Update Address Response: ${response.statusCode}');
      debugPrint('📍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AddressModel.fromJson(data['address']);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update address');
      }
    } catch (e) {
      debugPrint('❌ Error in updateAddress: $e');
      rethrow;
    }
  }

  // Delete address (if needed in future)
  Future<bool> deleteAddress(String addressId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$addressId'),
        headers: headers,
      );

      debugPrint('📍 Delete Address Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else {
        throw Exception('Failed to delete address');
      }
    } catch (e) {
      debugPrint('❌ Error in deleteAddress: $e');
      rethrow;
    }
  }
}