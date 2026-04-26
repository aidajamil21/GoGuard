import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_event.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../theme/app_colors.dart';

// ── Shared error screen shell ──────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final Color bgStart;
  final Color bgEnd;
  final String iconEmoji;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String body;
  final bool canRetry;

  const _ErrorScreen({
    required this.bgStart,
    required this.bgEnd,
    required this.iconEmoji,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.body,
    this.canRetry = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd, const Color(0xFFFFF8F8)],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Pulsing rings effect (simplified)
              Stack(alignment: Alignment.center, children: [
                Container(width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconBg.withOpacity(0.15), width: 2),
                  )),
                Container(width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconBg.withOpacity(0.25), width: 2),
                  )),
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconBg.withOpacity(0.7), iconBg],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: iconBg.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 12))],
                  ),
                  child: Center(child: Text(iconEmoji, style: const TextStyle(fontSize: 40))),
                ),
              ]),

              const SizedBox(height: 32),

              Text(title, textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700,
                  color: AppColors.text, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(subtitle, textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text2, height: 1.5)),
              ),

              const SizedBox(height: 24),

              // Detail card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: iconBg.withOpacity(0.2)),
                  ),
                  child: Text(body, textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2, height: 1.5)),
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(children: [
                  if (canRetry) ...[
                    BlocBuilder<TransferBloc, TransferState>(
                      builder: (context, state) => GestureDetector(
                        onTap: () {
                          context.read<TransferBloc>().add(TransferRetried());
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.jadeGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          alignment: Alignment.center,
                          child: Text('Try Again',
                            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  GestureDetector(
                    onTap: () {
                      context.read<TransferBloc>().add(TransferCancelled());
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                    },
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text('Back to Home',
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text2)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scam Blocked ───────────────────────────────────────────
class ScamBlockedScreen extends StatelessWidget {
  const ScamBlockedScreen({super.key});
  @override
  Widget build(BuildContext context) => const _ErrorScreen(
    bgStart: Color(0xFFFFE4E4),
    bgEnd: Color(0xFFFFF0F0),
    iconEmoji: '🛡️',
    iconBg: AppColors.danger,
    title: 'Transfer Blocked',
    subtitle: 'GoGuard AI has stopped this transfer to protect you.',
    body: 'Our AI detected an extremely high scam risk and blocked the transfer before any funds were moved. Your money is safe.',
    canRetry: false,
  );
}

// ── Insufficient Funds ─────────────────────────────────────
class InsufficientFundsScreen extends StatelessWidget {
  const InsufficientFundsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _ErrorScreen(
    bgStart: Color(0xFFFFF9E6),
    bgEnd: Color(0xFFFFFBEB),
    iconEmoji: '💸',
    iconBg: AppColors.gold,
    title: 'Insufficient Funds',
    subtitle: 'You do not have enough balance to complete this transfer.',
    body: 'Please reduce the transfer amount or top up your wallet before trying again.',
    canRetry: true,
  );
}

// ── Network Timeout ────────────────────────────────────────
class TimeoutScreen extends StatelessWidget {
  const TimeoutScreen({super.key});
  @override
  Widget build(BuildContext context) => const _ErrorScreen(
    bgStart: Color(0xFFEFF6FF),
    bgEnd: Color(0xFFF0F9FF),
    iconEmoji: '⏱️',
    iconBg: Color(0xFF3B82F6),
    title: 'Connection Timeout',
    subtitle: 'The request took too long. Please check your connection.',
    body: 'No funds have been transferred. You can safely retry the transfer.',
    canRetry: true,
  );
}
