import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AmplifyConfig {
  static bool _isConfigured = false;

  // 🔧 BACKEND MODE: Set to true to use Alibaba Cloud backend
  static const bool USE_ALIBABA_BACKEND = true;

  // Get the correct API endpoint based on mode and platform
  static String get apiEndpoint {
    if (USE_ALIBABA_BACKEND) {
      // Alibaba Cloud backend (deployed by your friend)
      return 'http://47.236.67.60:8000';
    } else if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';  // Android emulator special IP
    } else {
      return 'http://localhost:8000';
    }
  }

  static Future<void> configure() async {
    if (_isConfigured) return;

    try {
      // Add Cognito Auth plugin
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);

      // Add API plugin
      final api = AmplifyAPI();
      await Amplify.addPlugin(api);

      // Configure Amplify
      // Note: amplify_outputs.json will be auto-loaded
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
  },
  "api": {
    "plugins": {
      "awsAPIPlugin": {
        "apigoguard": {
          "endpointType": "REST",
          "endpoint": "${apiEndpoint}",
          "region": "ap-southeast-1",
          "authorizationType": "AWS_IAM"
        }
      }
    }
  }
}
''');

      _isConfigured = true;
      safePrint('✅ Amplify configured successfully');
      safePrint('🔗 API Endpoint: $apiEndpoint');
      safePrint('🔧 Mode: ${USE_ALIBABA_BACKEND ? "ALIBABA CLOUD" : "LOCAL DEVELOPMENT"}');
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
