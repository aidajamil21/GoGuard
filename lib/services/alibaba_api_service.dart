import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/risk_label.dart';

/// API service for Alibaba Cloud backend
/// Base URL: http://47.236.67.60:8000
/// Health: http://47.236.67.60:8800/health
class AlibabaApiService {
  static const String baseUrl = 'http://47.236.67.60:8000';
  static const String healthUrl = 'http://47.236.67.60:8800/health';
  static const Duration timeout = Duration(seconds: 30);

  // Set to true to use mock data when backend is unreachable (demo mode)
  static const bool USE_MOCK_FALLBACK = true;

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse(healthUrl)).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Health check failed: $e');
      return false;
    }
  }

  /// POST /predict — returns gnn_risk_score, xgboost_risk_score, summary
  Future<Map<String, dynamic>> predictRisk({
    required String phoneNumber,
    required double amount,
  }) async {
    // On web the backend is HTTP — browsers block mixed-content from HTTPS pages.
    // Skip the request entirely and use mock so no CORS errors appear in console.
    if (kIsWeb) {
      return _generateMockPrediction(phoneNumber, amount);
    }
    try {
      final cleanedPhone = phoneNumber
          .replaceAll('+', '')
          .replaceAll(' ', '')
          .replaceAll('-', '');

      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone_number': cleanedPhone, 'amount': amount}),
          )
          .timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Predict risk failed: $e');
      if (USE_MOCK_FALLBACK) {
        debugPrint('🔄 Using mock data (backend unreachable)');
        return _generateMockPrediction(phoneNumber, amount);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _generateMockPrediction(String phoneNumber, double amount) {
    final phoneHash = phoneNumber.hashCode.abs();
    final gnnScore = (phoneHash % 100) / 100.0;
    final xgbScore = ((phoneHash ~/ 100) % 100) / 100.0;

    final amountFactor = amount > 1000 ? 0.2 : 0.0;
    final finalGnn = (gnnScore + amountFactor).clamp(0.0, 1.0);
    final finalXgb = (xgbScore + amountFactor).clamp(0.0, 1.0);

    final avgRisk = (finalGnn + finalXgb) / 2;
    String summary;
    if (avgRisk < 0.4) {
      summary = 'Low risk transaction detected. Recipient appears legitimate with normal transaction patterns. Standard security checks passed successfully.';
    } else if (avgRisk < 0.7) {
      summary = 'Moderate risk detected. Transaction amount of RM ${amount.toStringAsFixed(2)} requires additional verification. Consider confirming recipient identity before proceeding.';
    } else {
      summary = 'High risk transaction identified. Suspicious patterns detected in network analysis. This number has been flagged in multiple scam reports. Strongly recommend verifying recipient identity.';
    }

    return {
      'summary': summary,
      'gnn_risk_score': finalGnn,
      'xgboost_risk_score': finalXgb,
      '_mock': true,
    };
  }

  Future<Map<String, dynamic>> checkRecipient({
    required String phone,
    required String userId,
  }) async {
    try {
      final result = await predictRisk(phoneNumber: phone, amount: 100.0);
      final gnnScore = (result['gnn_risk_score'] as num).toDouble();
      final isMock = result['_mock'] == true;

      return {
        'gnn_risk_score': gnnScore,
        'graph_features': {
          'num_reported_connections': gnnScore > 0.7 ? 5 : (gnnScore > 0.4 ? 2 : 0),
          'is_isolated_node': gnnScore > 0.7,
        },
        'scam_check_id': isMock
            ? 'mock_${DateTime.now().millisecondsSinceEpoch}'
            : 'alibaba_${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e) {
      debugPrint('❌ Check recipient failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRiskScore({
    required String userId,
    required String phone,
    required double amount,
    required int hourOfDay,
    required bool isNewRecipient,
    required int velocity,
  }) async {
    try {
      final result = await predictRisk(phoneNumber: phone, amount: amount);
      final xgbScore = (result['xgboost_risk_score'] as num).toDouble();
      final summary = result['summary'] as String? ?? '';

      return {
        'xgb_risk_score': xgbScore,
        'shap_values': {
          'amount': amount > 1000 ? 0.3 : -0.1,
          'hour_of_day': hourOfDay,
          'is_new_recipient': isNewRecipient ? 0.2 : -0.2,
          'velocity': velocity * 0.1,
        },
        'summary': summary,
      };
    } catch (e) {
      debugPrint('❌ Get risk score failed: $e');
      rethrow;
    }
  }

  Future<List<String>> getLLMBullets({
    required RiskLabel riskLabel,
    required Map<String, dynamic> graphFeatures,
    required Map<String, dynamic> shapValues,
    required double amount,
    required String phone,
  }) async {
    try {
      final result = await predictRisk(phoneNumber: phone, amount: amount);
      final summary = result['summary'] as String? ?? '';

      if (summary.isNotEmpty) {
        return summary
            .split('.')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .take(3)
            .toList();
      }
      return _getDefaultBullets(riskLabel, amount);
    } catch (e) {
      debugPrint('⚠️ LLM bullets unavailable: $e');
      return _getDefaultBullets(riskLabel, amount);
    }
  }

  List<String> _getDefaultBullets(RiskLabel riskLabel, double amount) {
    switch (riskLabel) {
      case RiskLabel.high:
        return [
          'High risk detected based on network analysis',
          'This number has suspicious patterns',
          'Consider verifying recipient identity before proceeding',
        ];
      case RiskLabel.medium:
        return [
          'Moderate risk detected',
          'Amount of RM ${amount.toStringAsFixed(2)} requires caution',
          'Verify recipient details before confirming',
        ];
      case RiskLabel.low:
        return [
          'Low risk transaction',
          'Recipient appears legitimate',
          'Standard security checks passed',
        ];
    }
  }

  Future<Map<String, dynamic>> executeTransfer({
    required String userId,
    required String phone,
    required double amount,
    required String scamCheckId,
    required double mlScore,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'txn_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'success',
    };
  }

  Future<String> getCurrentUserId() async => 'demo-user-123';
}
