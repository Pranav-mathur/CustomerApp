import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = "http://100.27.221.127:3000/api/v1";
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'token';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userIdKey = 'userId';

  // Get token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      // await _secureStorage.delete(key: _tokenKey);
      // await _secureStorage.delete(key: _phoneNumberKey);
      // Add any other keys you store during authentication
      // Example: await _secureStorage.delete(key: 'user_id');
      // Example: await _secureStorage.delete(key: 'refresh_token');

      // Or if you want to clear everything:
      await _secureStorage.deleteAll();

      debugPrint('✅ Session cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  // Save token
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Get phone number
  Future<String?> getPhoneNumber() async {
    try {
      return await _secureStorage.read(key: _phoneNumberKey);
    } catch (e) {
      debugPrint('Error getting phone number: $e');
      return null;
    }
  }

  // Save phone number
  Future<void> savePhoneNumber(String phoneNumber) async {
    try {
      await _secureStorage.write(key: _phoneNumberKey, value: phoneNumber);
    } catch (e) {
      debugPrint('Error saving phone number: $e');
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  // Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _secureStorage.write(key: _userIdKey, value: userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  // Send OTP to mobile number
  Future<Map<String, dynamic>> sendOtp(String mobileNumber) async {
    final url = Uri.parse("$baseUrl/auth/login/send-otp");
    debugPrint("✅ Send OTP API Payload: $mobileNumber");

    // Save phone number for later use
    await savePhoneNumber(mobileNumber);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobileNumber": mobileNumber}),
    );

    debugPrint("✅ Send OTP API Response: ${response.statusCode}");
    debugPrint("✅ Send OTP API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return {
        "message": "OTP sent successfully"
      };
    } else {
      if (response.statusCode == 400) {
        throw Exception("Invalid mobile number format");
      } else if (response.statusCode == 500) {
        throw Exception("Failed to send OTP. Please try again.");
      } else {
        throw Exception("Failed to send OTP: ${response.body}");
      }
    }
    //
    // return {
    //   "message": "OTP sent successfully"
    // };
  }

  // Verify OTP and get JWT token
  Future<Map<String, dynamic>> verifyOtp(String mobileNumber, String otp) async {
    final url = Uri.parse("$baseUrl/auth/login/verify-otp");
    debugPrint("✅ Verify OTP API Payload: mobileNumber=$mobileNumber, otp=$otp");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "mobileNumber": mobileNumber,
        "otp": otp,
      }),
    );

    debugPrint("✅ Verify OTP API Response: ${response.statusCode}");
    debugPrint("✅ Verify OTP API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Save token and phone number to secure storage
      if (result['token'] != null) {
        await saveToken(result['token']);
        await savePhoneNumber(mobileNumber);

        if (result['userId'] != null) {
          await saveUserId(result['userId']);
        }
      }

      return result;
    } else {
      if (response.statusCode == 400) {
        throw Exception("Mobile number and OTP are required");
      } else if (response.statusCode == 401) {
        throw Exception("Invalid OTP. Please try again.");
      } else if (response.statusCode == 500) {
        throw Exception("Server error. Please try again.");
      } else {
        throw Exception("OTP verification failed: ${response.body}");
      }
    }

    // Mock response - save to secure storage
    // await saveToken("NEW-TOKEN");
    // await savePhoneNumber(mobileNumber);
    //
    // return {
    //   "token": "NEW-TOKEN",
    //   "is_new_user": false,
    // };
  }

  // Logout method
  Future<Map<String, dynamic>> logout(String token) async {
    final url = Uri.parse("$baseUrl/auth/logout");
    debugPrint("✅ Logout API called");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("✅ Logout API Response: ${response.statusCode}");
    debugPrint("✅ Logout API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      // Clear secure storage
      await _secureStorage.deleteAll();
      return jsonDecode(response.body);
    } else {
      throw Exception("Logout failed: ${response.body}");
    }
  }

  // Updated login method - now sends OTP instead of direct login
  Future<Map<String, dynamic>> loginWithPhone(String mobileNumber) async {
    return await sendOtp(mobileNumber);
  }

  // Method to make authenticated requests
  Future<http.Response> makeAuthenticatedRequest(
      String endpoint,
      String token, {
        String method = 'GET',
        Map<String, dynamic>? body,
      }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        return await http.get(url, headers: headers);
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all stored data
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }
}