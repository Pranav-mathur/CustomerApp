import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _token;
  String? _userId;
  String? _error;

  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get error => _error;
  bool get isAuthenticated => _token != null;

  // Load token from storage on app start
  Future<void> loadToken() async {
    _token = await _storage.read(key: 'token');
    _userId = await _storage.read(key: 'userId');
    notifyListeners();
  }

  // Get phone number
  Future<String?> getPhoneNumber() async {
    return await _authService.getPhoneNumber();
  }

  // Send OTP to mobile number (same as login)
  Future<bool> login(String mobileNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.sendOtp(mobileNumber);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String mobileNumber) async {
    return await login(mobileNumber);
  }

  // Verify OTP and save token
  Future<Map<String, dynamic>?> verifyOtp(String mobileNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOtp(mobileNumber, otp);

      _token = result["token"];
      _userId = result["userId"];

      if (_token == null) {
        throw Exception("Token not found in response");
      }

      // Token is already persisted in AuthService
      // But we'll persist userId here
      if (_userId != null) {
        await _storage.write(key: 'userId', value: _userId);
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }

  // Logout
  Future<void> logout() async {
    if (_token != null) {
      try {
        await _authService.logout(_token!);
      } catch (e) {
        debugPrint("Logout API error: $e");
      }
    }

    _token = null;
    _userId = null;
    _error = null;

    // Clear all secure storage
    await _authService.clearAll();

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}