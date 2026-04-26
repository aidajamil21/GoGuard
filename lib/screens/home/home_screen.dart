import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_event.dart';
import '../../blocs/auth_bloc/auth_state.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceHidden = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, s) => s is AuthInitial,
      listener: (context, _) =>
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
        final balance = authState is AuthSuccess ? authState.session.balance : 0.0;
        final userId  = authState is AuthSuccess ? authState.session.userId  : 'U';
        final initial = userId.isNotEmpty ? userId[0].toUpperCase() : 'U';

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Column(
            children: [
              // ── Jade gradient header ──────────────────────────────
              Container(
                decoration: BoxDecoration(gradient: AppColors.jadeGradient),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Status / top row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(children: [
                          // Location pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text('Street Parking',
                                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                          const Spacer(),
                          // Avatar (display only)
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Center(
                              child: Text(initial,
                                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ),
                        ]),
                      ),

                      // Balance
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('eWallet Balance',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Row(children: [
                          Text(
                            _balanceHidden ? 'RM ●●●●' : 'RM ${balance.toStringAsFixed(2)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 32, fontWeight: FontWeight.w700,
                              color: Colors.white, letterSpacing: -0.5),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                            child: Icon(
                              _balanceHidden ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withValues(alpha: 0.7), size: 20),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('View detailed history',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.65), fontSize: 12,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.65))),
                        ),
                      ),

                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Row(children: [
                          Expanded(child: _headerBtn(Icons.add_circle_outline, '+ Add money', () {})),
                          const SizedBox(width: 8),
                          Expanded(child: _headerBtn(Icons.history, 'Transactions ›', () {})),
                        ]),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Scrollable body ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    // Quick actions card (overlaps header slightly)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 12, offset: const Offset(0, 2))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _quickItem(Icons.assignment_outlined, 'Apply',     AppColors.jade,                 () {}),
                            _quickItem(Icons.bar_chart_rounded,   'Cash flow', AppColors.jade,                 () {}),
                            _quickItem(Icons.send_rounded,        'Transfer',  AppColors.jade,                 () => Navigator.pushNamed(context, '/transfer/recipient')),
                            _quickItem(Icons.credit_card,         'Cards',     const Color(0xFFD4A017), () {}),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── GoGuard banner ────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/scam-db'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF0E6), Color(0xFFFFF8F0)],
                            ),
                            border: Border.all(color: const Color(0xFFFFB380)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GoGuard Active',
                                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF7A2E0E))),
                                Text('AI scam check for all transfers · Tap to view reports',
                                  style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFA85032))),
                              ],
                            )),
                            const Icon(Icons.chevron_right, color: Color(0xFFA85032), size: 18),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Trusted contacts card ─────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/whitelist'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.jadeLight,
                            border: Border.all(color: AppColors.jade.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.jade,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Trusted Contacts',
                                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.jadeDark)),
                                Text('Manage your whitelist · Skip scam check for trusted people',
                                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.jadeDark.withValues(alpha: 0.75))),
                              ],
                            )),
                            Icon(Icons.chevron_right, color: AppColors.jadeDark, size: 18),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recommended
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recommended',
                            style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: _miniCard('🌱', 'Grow your money', 'Invest with BIMB')),
                            const SizedBox(width: 10),
                            Expanded(child: _miniCard('⛽', 'BIMB5', 'BIMB in 5 steps')),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Sign Out ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => context.read<AuthBloc>().add(LogoutRequested()),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.logout_rounded, color: AppColors.text3, size: 18),
                            const SizedBox(width: 8),
                            Text('Sign Out',
                              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text2)),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),

          // Bottom navigation
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(Icons.home, 'Home', true),
                    _navItem(Icons.shopping_cart_outlined, 'eShop', false),
                    // Centre QR button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.jadeGradient,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                      ),
                    ),
                    _navItem(Icons.access_time_rounded, 'GOfinance', false),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/whitelist'),
                      child: _navItem(Icons.verified_user_outlined, 'Whitelist', false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _headerBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _quickItem(IconData icon, String label, Color color, VoidCallback onTap) {
    final isGold = color == const Color(0xFFD4A017);
    final bgColor = isGold ? const Color(0xFFFFF9E6) : AppColors.jadeLight;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 7),
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
        ]),
      ),
    );
  }

  Widget _miniCard(String emoji, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        Text(sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text2)),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: active ? AppColors.jade : AppColors.text3, size: 22),
      const SizedBox(height: 3),
      Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? AppColors.jade : AppColors.text3)),
    ]);
  }
}
