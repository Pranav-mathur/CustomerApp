import 'dart:convert';
import 'dart:io';  // Add this import for File
import 'dart:math';  // Add this import for min
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';  // Add this import for MediaType
import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../models/family_profile_model.dart';
import '../models/user_profile_model.dart';
import 'auth_service.dart';

class ProfileService {
  final String baseUrl = "http://100.27.221.127:3000/api/v1";
  final AuthService _authService = AuthService();

  Future<String> uploadProfileImage(File file) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse("$baseUrl/images/upload");
      var request = http.MultipartRequest('POST', uri);

      // Set Authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Get the file bytes and create multipart file with explicit content type
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file', // Field name must match API expectation
        fileBytes,
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'), // Explicitly set content type
      );

      request.files.add(multipartFile);

      debugPrint("📤 Uploading profile image to: $uri");
      debugPrint("📎 File: ${file.path.split('/').last}");
      debugPrint("📦 File size: ${fileBytes.length} bytes");
      debugPrint("🔑 Token: ${token.substring(0, min(10, token.length))}...");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("✅ Upload Response Status: ${response.statusCode}");
      debugPrint("📋 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'] ?? '';
        debugPrint("🖼️ Uploaded image URL: $imageUrl");
        return imageUrl;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid token');
      } else if (response.statusCode == 400) {
        throw Exception('Bad Request: ${response.body}');
      } else {
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ ProfileService upload error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createProfile({
    required String profileName,
    required String gender,
    required String email,
    required String? imageUrl,
    required List<MeasurementModel> measurements,
    required AddressModel? address,
    String? relationship,
    double? latitude,  // Add this
    double? longitude, // Add this
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final phoneNumber = await _authService.getPhoneNumber();

      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number not found. Please login again.');
      }

      // Build measurements array
      final measurementsArray = measurements.map((m) {
        return {
          "type": m.name.toLowerCase(),
          "value": m.value
        };
      }).toList();

      // Build request payload with location
      final payload = {
        "profileName": profileName,
        "mobileNumber": phoneNumber,
        "gender": gender,
        "email": email,
        "imageUrl": imageUrl ?? '',
        "measurements": measurementsArray,
        "relationship" : relationship ?? '',
        // "address": {
        //   "houseFlatBlock": address?.houseFlatBlock ?? '',
        //   "apartmentRoadArea": address?.apartmentRoadArea ?? '',
        //   "streetAndCity": address?.streetAndCity ?? '',
        //   "addressType": address?.addressType ?? ''
        // },
        // Add location data if available
        if (latitude != null && longitude != null)
          "location": {
            "latitude": latitude,
            "longitude": longitude,
          }
      };

      debugPrint('✅ Creating profile with payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/profiles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('✅ Profile creation response: ${response.statusCode}');
      debugPrint('✅ Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to create profile');
        } catch (e) {
          throw Exception('Failed to create profile: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating profile: $e');
      rethrow;
    }
  }


  Future<Map<String, dynamic>?> updateProfile({
    required String profileId,
    required String profileName,
    required String gender,
    required String email,
    required String? imageUrl,
    required List<MeasurementModel> measurements,
    required AddressModel? address,
    String? relationship,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final phoneNumber = await _authService.getPhoneNumber();

      final measurementsArray = measurements.map((m) {
        return {
          "type": m.name.toLowerCase(),
          "value": "${m.value} ${m.unit}"
        };
      }).toList();

      final payload = {
        "profileName": profileName,
        "mobileNumber": phoneNumber,
        "gender": gender,
        "email": email,
        "imageUrl": imageUrl ?? '',
        "measurements": measurementsArray,
        "relationship": relationship,
        // "address": {
        //   "houseFlatBlock": address?.houseFlatBlock ?? '',
        //   "apartmentRoadArea": address?.apartmentRoadArea ?? '',
        //   "streetAndCity": address?.streetAndCity ?? '',
        //   "addressType": address?.addressType ?? ''
        // }
      };

      debugPrint('✅ Updating profile with payload: ${jsonEncode(payload)}');

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/$profileId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('✅ Profile update response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String profileId) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/$profileId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ Get profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to get profile');
      }
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      rethrow;
    }
  }

  Future<List<dynamic>?> getAllProfiles() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profiles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ Get all profiles response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['profiles'] ?? [];
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to get profiles');
      }
    } catch (e) {
      debugPrint('❌ Error getting profiles: $e');
      rethrow;
    }
  }

  // In services/profile_service.dart

// Update the getAllProfiles method:
  Future<List<UserProfileModel>?> getAllUserProfiles() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profiles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ Get all profiles response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profilesList = (data['profiles'] as List?)
            ?.map((json) => UserProfileModel.fromJson(json))
            .toList() ?? [];

        debugPrint('✅ Fetched ${profilesList.length} profiles');
        return profilesList;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to get profiles');
      }
    } catch (e) {
      debugPrint('❌ Error getting profiles: $e');
      rethrow;
    }
  }

  Future<bool> deleteProfile(String profileId) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/profiles/$profileId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ Delete profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to delete profile');
      }
    } catch (e) {
      debugPrint('❌ Error deleting profile: $e');
      return false;
    }
  }
}