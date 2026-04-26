import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_event.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../models/risk_label.dart';
import '../../theme/app_colors.dart';
import '../../utils/phone_masker.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});
  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final state = context.read<TransferBloc>().state;
    if (state.data.riskLabel == RiskLabel.high) {
      _seconds = 60;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        if (_seconds <= 0) { t.cancel(); return; }
        setState(() => _seconds--);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listenWhen: (_, s) => s is TransferIdle,
      listener: (context, state) {
        if (state is TransferIdle) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      },
      child: BlocBuilder<TransferBloc, TransferState>(
        builder: (context, state) {
          final data = state.data;
          final risk = data.riskLabel ?? RiskLabel.low;
          final score = data.finalScore ?? 0.0;
          final bullets = data.llmBullets ?? [];
          final amount = data.amount ?? 0.0;
          final phone = data.recipientPhone ?? '';
          final velocity = data.velocity;

          final (headerColor, headerBg, title, subtitle) = switch (risk) {
            RiskLabel.high   => (Colors.white, AppColors.warn,
                'Pause and Verify', 'High risk detected — take 60 seconds'),
            RiskLabel.medium => (Colors.white, const Color(0xFFF97316),
                'Proceed with Caution', 'Medium risk detected'),
            RiskLabel.low    => (Colors.white, AppColors.jade,
                'Transfer Looks Safe', 'Low risk — review before confirming'),
          };

          final proceedBlocked = risk == RiskLabel.high && _seconds > 0;

          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // ── Coloured header ──────────────────────────
                Container(
                  width: double.infinity,
                  color: headerBg,
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        // Curved white bottom
                        Positioned(
                          bottom: -30, left: -40,
                          right: -40,
                          child: Container(height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(100)),
                            )),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          child: Column(children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                              child: Icon(
                                risk == RiskLabel.low ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(title,
                              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: headerColor)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                              style: GoogleFonts.dmSans(fontSize: 13, color: headerColor.withOpacity(0.85))),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(children: [
                      // ── Countdown timer for HIGH ───────────
                      if (risk == RiskLabel.high) ...[
                        _timerRing(_seconds),
                        const SizedBox(height: 20),
                      ] else ...[
                        // Score pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _riskBg(risk),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Risk Score: ${(score * 100).toStringAsFixed(0)}%  •  ${risk.displayName}',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: _riskFg(risk)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Transfer summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(children: [
                          _summaryRow('To', maskPhone(phone)),
                          _summaryRow('Amount', 'RM ${amount.toStringAsFixed(2)}'),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Velocity warning
                      if (velocity >= 3) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warn.withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.speed_rounded, color: AppColors.warn, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              '$velocity transfers in the last hour — frequent small transfers are a common scam tactic.',
                              style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF92400E)),
                            )),
                          ]),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // LLM bullets / checklist
                      if (bullets.isNotEmpty) ...[
                        Align(alignment: Alignment.centerLeft,
                          child: Text('Why AI flagged this:',
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text))),
                        const SizedBox(height: 10),
                        ...bullets.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 20, height: 20,
                              decoration: BoxDecoration(color: AppColors.jadeLight, shape: BoxShape.circle),
                              child: const Center(child: Icon(Icons.check, color: AppColors.jade, size: 11)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(b,
                              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2, height: 1.4))),
                          ]),
                        )),
                        const SizedBox(height: 16),
                      ] else if (risk != RiskLabel.low) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warnLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.info_outline, color: AppColors.warn),
                            const SizedBox(width: 8),
                            Expanded(child: Text('AI explanation unavailable — proceed with caution.',
                              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Timer countdown label for HIGH risk
                      if (risk == RiskLabel.high && _seconds > 0) ...[
                        Text('Please wait $_seconds second${_seconds == 1 ? '' : 's'} before proceeding',
                          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text3, height: 1.4),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                      ],

                      // Proceed button
                      GestureDetector(
                        onTap: proceedBlocked ? null : () {
                          context.read<TransferBloc>().add(WarningAcknowledged());
                          context.read<TransferBloc>().add(TransferConfirmed());
                          Navigator.pushReplacementNamed(context, '/transfer/loading');
                        },
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: proceedBlocked ? Colors.grey.shade300 : null,
                            gradient: proceedBlocked ? null : AppColors.jadeGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: proceedBlocked ? [] : [
                              BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            proceedBlocked
                                ? 'Wait ${_seconds}s to Proceed'
                                : risk == RiskLabel.high
                                    ? "I've verified — Proceed Anyway"
                                    : 'Confirm Transfer',
                            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700,
                              color: proceedBlocked ? AppColors.text3 : Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            border: Border.all(color: AppColors.danger, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text('Cancel Transfer',
                            style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.danger)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timerRing(int seconds) {
    final progress = seconds / 60.0;
    return Column(children: [
      SizedBox(
        width: 140, height: 140,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: const Color(0xFFF0F0F0),
            color: AppColors.warn,
            strokeCap: StrokeCap.round,
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$seconds',
              style: GoogleFonts.dmMono(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.text)),
            Text('seconds', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3)),
          ]),
        ]),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2)),
        const Spacer(),
        Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
      ]),
    );
  }

  Color _riskBg(RiskLabel r) => switch (r) {
    RiskLabel.low    => AppColors.jadeLight,
    RiskLabel.medium => AppColors.warnLight,
    RiskLabel.high   => AppColors.dangerLight,
  };

  Color _riskFg(RiskLabel r) => switch (r) {
    RiskLabel.low    => AppColors.jadeDark,
    RiskLabel.medium => const Color(0xFF92400E),
    RiskLabel.high   => AppColors.danger,
  };
}
