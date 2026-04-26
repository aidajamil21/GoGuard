import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_event.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_event.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/phone_masker.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});
  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  bool _deducted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _deducted) return;
      final amount = context.read<TransferBloc>().state.data.amount ?? 0.0;
      if (amount > 0) {
        context.read<AuthBloc>().add(BalanceDeducted(amount));
        _deducted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferBloc, TransferState>(
      builder: (context, state) {
        final txnId = state is TransferSuccessState ? state.txnId : 'txn_unknown';
        final timestamp = state is TransferSuccessState ? state.timestamp : DateTime.now();
        final data = state.data;
        final amount = data.amount ?? 0.0;
        final phone  = data.recipientPhone ?? '';

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── Green gradient header ──────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(gradient: AppColors.jadeGradient),
                child: SafeArea(
                  bottom: false,
                  child: Stack(children: [
                    // Curved white bottom
                    Positioned(
                      bottom: -30, left: -40, right: -40,
                      child: Container(height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(100)),
                        )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
                      child: Column(children: [
                        // Animated checkmark
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                          child: Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 32, offset: const Offset(0, 8))],
                            ),
                            child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('RM ${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(fontSize: 40, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text('Transfer Successful',
                          style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                      ]),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── Receipt card ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 24, offset: const Offset(0, 4))],
                      ),
                      child: Column(children: [
                        _receiptRow('To', maskPhone(phone)),
                        _receiptRow('Amount', 'RM ${amount.toStringAsFixed(2)}'),
                        _receiptRow('Transaction ID', txnId),
                        _receiptRow('Date & Time',
                          '${timestamp.day}/${timestamp.month}/${timestamp.year}  ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'),
                        _receiptRow('Status', '✅ Completed'),
                        _receiptRow('GoGuard', '✓ Verified Safe'),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // GoGuard badge
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.jadeLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        const Icon(Icons.shield_rounded, color: AppColors.jade, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Transfer was verified by GoGuard AI and cleared.',
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.jadeDark))),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // Done button
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(child: Icon(Icons.share_outlined, color: AppColors.text2, size: 20)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.read<TransferBloc>().add(TransferCancelled());
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppColors.jadeGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            alignment: Alignment.center,
                            child: Text('Done', style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1000A878))),
      ),
      child: Row(children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text3)),
        const Spacer(),
        Flexible(child: Text(value, textAlign: TextAlign.right,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text))),
      ]),
    );
  }
}
