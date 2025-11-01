// services/home_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HomeService {
  // Replace with your actual API base URL
  static const String baseUrl = 'http://100.27.221.127:3000/api/v1';
  // final String baseUrl = "http://100.27.221.127:3000/api/v1";

  // Singleton pattern
  static final HomeService _instance = HomeService._internal();
  factory HomeService() => _instance;
  HomeService._internal();

  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/homepage'),
        headers: {
          'Content-Type': 'application/json',
          // Add authentication token if needed
          // 'Authorization': 'Bearer $token',
        },
      );
      debugPrint("✅ URL: ${Uri.parse('$baseUrl/homepage')}");

      debugPrint("✅ Send getHomeData Response code: ${response.statusCode}");
      debugPrint("✅ Send getHomeData Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}