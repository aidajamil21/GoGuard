import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_event.dart';
import '../../blocs/auth_bloc/auth_state.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
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
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text('GOguard',
                    style: GoogleFonts.dmSans(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.5,
                    )),
                  const SizedBox(height: 4),
                  Text('Transfer Guardian — Scam Prevention',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Sign in to your account',
                      style: GoogleFonts.dmSans(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      )),
                    const SizedBox(height: 24),

                    _label('Email / Username'),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _emailCtrl,
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),

                    _label('Password'),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _passCtrl,
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.text3, size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.jade));
                        }
                        return _primaryButton(
                          label: 'Sign In',
                          onTap: () => context.read<AuthBloc>().add(LoginRequested(
                            email: _emailCtrl.text.trim(),
                            password: _passCtrl.text,
                          )),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Sign Up Button
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.jade, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text('Create New Account',
                          style: GoogleFonts.dmSans(
                            fontSize: 16, fontWeight: FontWeight.w700, 
                            color: AppColors.jade
                          )),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Demo Login: demo@goguard.com / demo123',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.jade, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Protected by AWS Cognito + GoGuard AI',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
