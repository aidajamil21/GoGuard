import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_event.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../models/risk_label.dart';
import '../../theme/app_colors.dart';
import '../../utils/phone_masker.dart';

class ScamCheckScreen extends StatelessWidget {
  const ScamCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listenWhen: (_, s) => s is AmountEntryState || s is TransferIdle,
      listener: (context, state) {
        if (state is AmountEntryState) {
          Navigator.pushReplacementNamed(context, '/transfer/amount');
        }
        if (state is TransferIdle) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      },
      child: BlocBuilder<TransferBloc, TransferState>(
        builder: (context, state) {
          final data     = state.data;
          final phone    = data.recipientPhone ?? '';
          final gnn      = data.gnnRiskScore ?? 0.0;
          final label    = data.riskLabel ?? RiskLabel.low;
          final features = data.graphFeatures ?? {};

          final (headerColor, headerBg, icon, iconBg, labelText) = switch (label) {
            RiskLabel.low    => (const Color(0xFF065F46), const Color(0xFFECFDF5),
                                  Icons.verified_rounded, const Color(0xFF10B981), 'LOW RISK'),
            RiskLabel.medium => (const Color(0xFF92400E), const Color(0xFFFFFBEB),
                                  Icons.warning_rounded, AppColors.warn, 'MEDIUM RISK'),
            RiskLabel.high   => (const Color(0xFF991B1B), AppColors.dangerLight,
                                  Icons.block_rounded, AppColors.danger, 'HIGH RISK'),
          };

          final reports = (features['num_reported_connections'] as num?)?.toInt() ?? 0;
          final isIsolated = features['is_isolated_node'] as bool? ?? false;

          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Column(
              children: [
                // ── Jade header ─────────────────────────────
                Container(
                  decoration: BoxDecoration(gradient: AppColors.jadeGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          GestureDetector(
                            onTap: () {
                              context.read<TransferBloc>().add(RecipientCheckCancelled());
                            },
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Recipient Check',
                            style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                        const SizedBox(height: 8),
                        Text('Verifying ${maskPhone(phone)}',
                          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                        Text('Checked against NSRC, BNM NFP & community reports',
                          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                      ]),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      // ── Risk card ──────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 24, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Column(children: [
                            // Risk header
                            Container(
                              padding: const EdgeInsets.all(18),
                              color: headerBg,
                              child: Row(children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                                  child: Icon(icon, color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(labelText,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16, fontWeight: FontWeight.w700, color: headerColor)),
                                    const SizedBox(height: 2),
                                    Text(maskPhone(phone),
                                      style: GoogleFonts.dmMono(fontSize: 13, color: headerColor.withOpacity(0.7))),
                                  ],
                                )),
                              ]),
                            ),
                            // Risk details
                            Container(
                              color: AppColors.card,
                              padding: const EdgeInsets.all(16),
                              child: Column(children: [
                                _riskRow('GNN Risk Score', '${(gnn * 100).toStringAsFixed(0)}%',
                                  badge: _scoreBadge(gnn)),
                                _riskRow('Scam Reports', '$reports linked connection${reports == 1 ? '' : 's'}',
                                  badge: _countBadge(reports)),
                                _riskRow('Network Profile',
                                  isIsolated ? 'Isolated node (suspicious)' : 'Connected network',
                                  badge: _networkBadge(isIsolated)),
                                _riskRow('Phone Number', maskPhone(phone)),
                              ]),
                            ),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Source attribution
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          const Icon(Icons.hub_rounded, color: AppColors.jade, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Powered by Graph Neural Network (GNN) — community report graph',
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3)),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // High risk extra warning
                      if (label == RiskLabel.high) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              'This number has a high scam risk. Proceeding is strongly discouraged.',
                              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.danger),
                            )),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Buttons
                      _primaryButton('Proceed to Amount Entry', () {
                        context.read<TransferBloc>().add(RecipientCheckConfirmed());
                      }),
                      const SizedBox(height: 10),
                      _cancelButton('Cancel Transfer', () {
                        context.read<TransferBloc>().add(RecipientCheckCancelled());
                      }),
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

  Widget _riskRow(String label, String value, {Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(label,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2))),
        badge ?? Text(value,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
      ]),
    );
  }

  Widget _scoreBadge(double score) {
    final (bg, fg) = score < 0.4
        ? (const Color(0xFFD1FAE5), const Color(0xFF065F46))
        : score < 0.7
            ? (const Color(0xFFFEF3C7), const Color(0xFF92400E))
            : (AppColors.dangerLight, AppColors.danger);
    return _badge('${(score * 100).toStringAsFixed(0)}%', bg, fg);
  }

  Widget _countBadge(int count) {
    if (count == 0) return _badge('None', const Color(0xFFD1FAE5), const Color(0xFF065F46));
    if (count <= 2) return _badge('$count reports', const Color(0xFFFEF3C7), const Color(0xFF92400E));
    return _badge('$count reports', AppColors.dangerLight, AppColors.danger);
  }

  Widget _networkBadge(bool isolated) {
    return isolated
        ? _badge('Suspicious', AppColors.dangerLight, AppColors.danger)
        : _badge('Normal', const Color(0xFFE0F2FE), const Color(0xFF0369A1));
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.jadeGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _cancelButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.danger)),
      ),
    );
  }
}
