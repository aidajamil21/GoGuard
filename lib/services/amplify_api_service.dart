import 'dart:convert';
import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../models/risk_label.dart';

class AmplifyApiService {
  static const String apiName = 'apigoguard';

  Map<String, dynamic> _decode(AWSHttpResponse response) {
    return Map<String, dynamic>.from(
      jsonDecode(response.decodeBody()) as Map,
    );
  }

  // ── GNN: Recipient Risk Check ──────────────────
  Future<Map<String, dynamic>> checkRecipient({
    required String phone,
    required String userId,
  }) async {
    try {
      final response = await Amplify.API.post(
        '/recipients/check',
        apiName: apiName,
        body: HttpPayload.json({
          'phone': phone,
          'user_id': userId,
          'device_id': 'amplify_device',
        }),
      ).response.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
      );
      return _decode(response);
    } catch (e) {
      safePrint('❌ Error checking recipient: $e');
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
      final response = await Amplify.API.post(
        '/ml/risk-score',
        apiName: apiName,
        body: HttpPayload.json({
          'user_id': userId,
          'phone': phone,
          'amount': amount,
          'hour_of_day': hourOfDay,
          'is_new_recipient': isNewRecipient,
          'velocity': velocity,
          'device_id': 'amplify_device',
        }),
      ).response.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
      );
      return _decode(response);
    } catch (e) {
      safePrint('❌ Error getting risk score: $e');
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
      final response = await Amplify.API.post(
        '/ml/llm-explain',
        apiName: apiName,
        body: HttpPayload.json({
          'risk_label': riskLabel.displayName,
          'graph_features': graphFeatures,
          'shap_values': shapValues,
          'amount': amount,
          'phone': phone,
          'time_of_day': DateTime.now().hour.toString(),
        }),
      ).response;
      final data = _decode(response);
      final bullets = data['llm_bullets'] as List?;
      return bullets?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      safePrint('⚠️ LLM unavailable (non-fatal): $e');
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
      final response = await Amplify.API.post(
        '/transfers/execute',
        apiName: apiName,
        body: HttpPayload.json({
          'user_id': userId,
          'phone': phone,
          'amount': amount,
          'scam_check_id': scamCheckId,
          'ml_score': mlScore,
          'device_id': 'amplify_device',
        }),
      ).response.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
      );
      return _decode(response);
    } catch (e) {
      safePrint('❌ Error executing transfer: $e');
      rethrow;
    }
  }

  // ── Get Current User ID ────────────────────────
  Future<String> getCurrentUserId() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (e) {
      safePrint('⚠️ Could not get user ID: $e');
      return 'unknown';
    }
  }

  // ── Get Cognito ID Token ───────────────────────
  Future<String?> getCurrentUserToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        final tokens = session.userPoolTokensResult.value;
        return tokens.idToken.raw;
      }
      return null;
    } catch (e) {
      safePrint('❌ Error getting user token: $e');
      return null;
    }
  }
}
