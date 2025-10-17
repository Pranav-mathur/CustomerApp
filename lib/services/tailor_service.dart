// services/tailor_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tailor_detail_models.dart';
import 'package:flutter/foundation.dart';

class TailorService {
  // Replace with your actual API base URL
  static const String baseUrl = 'http://100.27.221.127:3000/api/v1';

  Future<TailorDetail> getTailorDetail(String tailorId) async {
    try {
      final url = Uri.parse('$baseUrl/tailor/details/$tailorId');

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