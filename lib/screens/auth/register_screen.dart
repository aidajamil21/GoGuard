import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/amplify_auth_service.dart';
import '../../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _auth = AmplifyAuthService();
  
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _needsConfirmation = false;
  String _registeredEmail = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_passCtrl.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (result.isSignUpComplete) {
        _showSuccess('Account created successfully!');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          _needsConfirmation = true;
          _registeredEmail = _emailCtrl.text.trim();
        });
        _showSuccess('Please check your email for verification code');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmSignUp() async {
    if (_codeCtrl.text.trim().isEmpty) {
      _showError('Please enter verification code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _auth.confirmSignUp(
        email: _registeredEmail,
        confirmationCode: _codeCtrl.text.trim(),
      );

      if (result.isSignUpComplete) {
        _showSuccess('Account verified successfully!');
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── Jade header ─────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: AppColors.jadeGradient),
            padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 48, 24, 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(_needsConfirmation ? 'Verify Account' : 'Create Account',
                  style: GoogleFonts.dmSans(
                    fontSize: 32, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -0.5,
                  )),
                const SizedBox(height: 4),
                Text(_needsConfirmation 
                  ? 'Enter the verification code sent to your email'
                  : 'Join GOguard - Transfer Guardian',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.white.withOpacity(0.8),
                  )),
              ],
            ),
          ),

          // ── Form ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _needsConfirmation ? _buildConfirmationForm() : _buildRegistrationForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Create your GOguard account',
          style: GoogleFonts.dmSans(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.text,
          )),
        const SizedBox(height: 24),

        _label('Email'),
        const SizedBox(height: 6),
        _inputField(
          controller: _emailCtrl,
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),

        _label('Password'),
        const SizedBox(height: 6),
        _inputField(
          controller: _passCtrl,
          hint: 'Create a strong password (min 8 chars)',
          icon: Icons.lock_outline,
          obscure: _obscurePass,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePass = !_obscurePass),
            child: Icon(
              _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.text3, size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _label('Confirm Password'),
        const SizedBox(height: 6),
        _inputField(
          controller: _confirmPassCtrl,
          hint: 'Confirm your password',
          icon: Icons.lock_outline,
          obscure: _obscureConfirm,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            child: Icon(
              _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.text3, size: 20,
            ),
          ),
        ),
        const SizedBox(height: 32),

        _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.jade))
          : _primaryButton(
              label: 'Create Account',
              onTap: _signUp,
            ),
        const SizedBox(height: 20),

        Center(
          child: Text(
            'Password must contain: 8+ chars, uppercase, lowercase, number, symbol',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Check your email',
          style: GoogleFonts.dmSans(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.text,
          )),
        const SizedBox(height: 8),
        Text('We sent a verification code to $_registeredEmail',
          style: GoogleFonts.dmSans(
            fontSize: 14, color: AppColors.text2,
          )),
        const SizedBox(height: 24),

        _label('Verification Code'),
        const SizedBox(height: 6),
        _inputField(
          controller: _codeCtrl,
          hint: 'Enter 6-digit code',
          icon: Icons.verified_user_outlined,
        ),
        const SizedBox(height: 32),

        _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.jade))
          : _primaryButton(
              label: 'Verify Account',
              onTap: _confirmSignUp,
            ),
        const SizedBox(height: 20),

        Center(
          child: GestureDetector(
            onTap: () => setState(() => _needsConfirmation = false),
            child: Text(
              'Back to registration',
              style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.jade,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: AppColors.text3, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.jade, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.jadeGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(label,
          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}