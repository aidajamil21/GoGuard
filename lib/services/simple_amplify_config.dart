import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// Simplified Amplify config that only sets up Auth (not API)
/// API calls go directly to Alibaba Cloud via HTTP
class SimpleAmplifyConfig {
  static bool _isConfigured = false;

  static Future<void> configure() async {
    if (_isConfigured) return;

    try {
      // Only add Auth plugin (no API plugin needed for Alibaba backend)
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);

      // Configure only Auth
      await Amplify.configure('''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "ap-southeast-1:6f92fa94-b158-46b2-8b11-289e99b01e7c",
              "Region": "ap-southeast-1"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "ap-southeast-1_jp9MDSOW6",
            "AppClientId": "4skospts8415apn8b92oov8bpn",
            "Region": "ap-southeast-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": [],
            "usernameAttributes": [],
            "signupAttributes": ["EMAIL"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            },
            "mfaConfiguration": "OFF",
            "verificationMechanisms": ["EMAIL"]
          }
        }
      }
    }
  }
}
''');

      _isConfigured = true;
      safePrint('✅ Amplify Auth configured successfully');
      safePrint('🔗 API: Direct HTTP to Alibaba Cloud (http://47.236.67.60:8000)');
    } on AmplifyAlreadyConfiguredException {
      safePrint('⚠️ Amplify was already configured');
      _isConfigured = true;
    } catch (e) {
      safePrint('❌ Error configuring Amplify: $e');
      rethrow;
    }
  }

  static bool get isConfigured => _isConfigured;
}
