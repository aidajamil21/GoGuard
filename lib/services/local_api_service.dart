import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/risk_label.dart';

class LocalApiService {
  // Automatically use correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web (Chrome) - use localhost
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Android emulator - use special IP
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS simulator - use localhost
      return 'http://localhost:8000';
    } else {
      // Desktop or other - use localhost
      return 'http://localhost:8000';
    }
  }

  // ── GNN: Recipient Risk Check ──────────────────
  Future<Map<String, dynamic>> checkRecipient({
    required String phone,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipients/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'user_id': userId,
          'device_id': 'local_device',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to check recipient: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error checking recipient: $e');
      rethrow;
    }
  }

  // ── XGBoost: Behavioural Risk Score ────────────
  Future<Map<String, dynamic>> getRiskScore({
    required String userId,
    required String phone,
    required double amount,
    required int hourOfDay,
    required bool isNewRecipient,
    required int velocity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ml/risk-score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'phone': phone,
          'amount': amount,
          'hour_of_day': hourOfDay,
          'is_new_recipient': isNewRecipient,
          'velocity': velocity,
          'device_id': 'local_device',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get risk score: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting risk score: $e');
      rethrow;
    }
  }

  // ── LLM: Explanation Generation (non-fatal) ────
  Future<List<String>> getLLMBullets({
    required RiskLabel riskLabel,
    required Map<String, dynamic> graphFeatures,
    required Map<String, dynamic> shapValues,
    required double amount,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ml/llm-explain'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'risk_label': riskLabel.displayName,
          'graph_features': graphFeatures,
          'shap_values': shapValues,
          'amount': amount,
          'phone': phone,
          'time_of_day': DateTime.now().hour.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bullets = data['llm_bullets'] as List?;
        return bullets?.map((e) => e.toString()).toList() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ LLM unavailable (non-fatal): $e');
      return [];
    }
  }

  // ── Transfer: Execute ──────────────────────────
  Future<Map<String, dynamic>> executeTransfer({
    required String userId,
    required String phone,
    required double amount,
    required String scamCheckId,
    required double mlScore,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transfers/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'phone': phone,
          'amount': amount,
          'scam_check_id': scamCheckId,
          'ml_score': mlScore,
          'device_id': 'local_device',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to execute transfer: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error executing transfer: $e');
      rethrow;
    }
  }

  // ── Health Check ───────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Backend health check failed: $e');
      return false;
    }
  }
}
