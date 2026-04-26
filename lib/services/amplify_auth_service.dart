import 'package:amplify_flutter/amplify_flutter.dart';

class AmplifyAuthService {
  // ── Sign Up ────────────────────────────────────
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      // First try with minimal attributes
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
      );

      safePrint('✅ Sign up result: ${result.isSignUpComplete}');
      return result;
    } on AuthException catch (e) {
      safePrint('❌ Sign up error: ${e.message}');
      
      // If that fails, try with email attribute
      if (e.message.contains('email')) {
        try {
          final userAttributes = <AuthUserAttributeKey, String>{
            AuthUserAttributeKey.email: email,
          };
          
          final result = await Amplify.Auth.signUp(
            username: email,
            password: password,
            options: SignUpOptions(userAttributes: userAttributes),
          );
          
          safePrint('✅ Sign up result (with email): ${result.isSignUpComplete}');
          return result;
        } catch (retryError) {
          safePrint('❌ Sign up retry error: $retryError');
        }
      }
      
      rethrow;
    }
  }

  // ── Confirm Sign Up ────────────────────────────
  Future<SignUpResult> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );

      safePrint('✅ Confirm sign up result: ${result.isSignUpComplete}');
      return result;
    } on AuthException catch (e) {
      safePrint('❌ Confirm sign up error: ${e.message}');
      rethrow;
    }
  }

  // ── Sign In ────────────────────────────────────
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      safePrint('✅ Sign in result: ${result.isSignedIn}');
      return result;
    } on AuthException catch (e) {
      safePrint('❌ Sign in error: ${e.message}');
      rethrow;
    }
  }

  // ── Sign Out ───────────────────────────────────
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      safePrint('✅ Signed out successfully');
    } on AuthException catch (e) {
      safePrint('❌ Sign out error: ${e.message}');
      rethrow;
    }
  }

  // ── Get Current User ───────────────────────────
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      safePrint('✅ Current user: ${user.username}');
      return user;
    } on AuthException catch (e) {
      safePrint('⚠️ No current user: ${e.message}');
      return null;
    }
  }

  // ── Check Auth Status ──────────────────────────
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } on AuthException catch (e) {
      safePrint('❌ Error checking auth status: ${e.message}');
      return false;
    }
  }

  // ── Get User Attributes ────────────────────────
  Future<List<AuthUserAttribute>> getUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      safePrint('✅ User attributes fetched: ${attributes.length}');
      return attributes;
    } on AuthException catch (e) {
      safePrint('❌ Error fetching attributes: ${e.message}');
      rethrow;
    }
  }

  // ── Reset Password ─────────────────────────────
  Future<ResetPasswordResult> resetPassword({
    required String email,
  }) async {
    try {
      final result = await Amplify.Auth.resetPassword(username: email);
      safePrint('✅ Password reset initiated');
      return result;
    } on AuthException catch (e) {
      safePrint('❌ Password reset error: ${e.message}');
      rethrow;
    }
  }

  // ── Confirm Reset Password ─────────────────────
  Future<void> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      safePrint('✅ Password reset confirmed');
    } on AuthException catch (e) {
      safePrint('❌ Confirm password reset error: ${e.message}');
      rethrow;
    }
  }
}
