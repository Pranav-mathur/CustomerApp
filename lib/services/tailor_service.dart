// services/tailor_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tailor_detail_models.dart';
import 'package:flutter/foundation.dart';

class TailorService {
  // Replace with your actual API base URL
  static const String baseUrl = 'http://ec2-3-236-219-163.compute-1.amazonaws.com:3000/api/v1';

  Future<Map<String, dynamic>> getTailorAvailability(String tailorId) async {
    try {
      final url = Uri.parse('http://ec2-3-236-219-163.compute-1.amazonaws.com:3000/api/v1/tailor/$tailorId/availability');
      debugPrint('📅 Fetching availability: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📅 Availability Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load availability: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching tailor availability: $e');
      rethrow;
    }
  }

  Future<TailorDetail> getTailorDetail(String tailorId) async {
    try {
      final url = Uri.parse('$baseUrl/tailor/details/$tailorId');
      debugPrint("📎 url: ${url}");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer YOUR_TOKEN',
        },
      );


      debugPrint("📎 File: ${response}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TailorDetail.fromApiResponse(jsonData);
      } else {
        throw Exception('Failed to load tailor details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tailor details: $e');
    }
  }
}