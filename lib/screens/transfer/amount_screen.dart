import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_state.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_event.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/phone_masker.dart';

class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});
  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final _amountCtrl = TextEditingController();
  String? _selectedPurpose;

  final _purposes = ['Family', 'Business', 'Rent', 'Food', 'Loan', 'Other'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit(double balance) {
    final raw = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), behavior: SnackBarBehavior.floating));
      return;
    }
    context.read<TransferBloc>().add(AmountSubmitted(amount: raw, balance: balance));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listenWhen: (_, s) => s is BehaviouralAnalysingState || s is TransferErrorState,
      listener: (context, state) {
        if (state is BehaviouralAnalysingState) {
          Navigator.pushNamed(context, '/transfer/analysing');
        }
        if (state is TransferErrorState) {
          Navigator.pushReplacementNamed(context, '/error/insufficient-funds');
        }
      },
      child: BlocBuilder<TransferBloc, TransferState>(
        builder: (context, transferState) {
          final data = transferState.data;
          final phone = data.recipientPhone ?? '';
          final isWhitelisted = data.isWhitelisted;
          final nickname = data.recipientNickname;
          final authState = context.read<AuthBloc>().state;
          final balance = authState is AuthSuccess ? authState.session.balance : 5000.0;

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
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Transfer Money',
                            style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: List.generate(5, (i) => Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: i < 2 ? Colors.white : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ))),
                        const SizedBox(height: 4),
                        Text('Step 2 of 5 · Enter amount',
                          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
                      ]),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      // ── Recipient card ─────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: AppColors.jadeLight, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                nickname?.isNotEmpty == true ? nickname![0].toUpperCase() : phone.isNotEmpty ? phone[phone.length - 1] : '?',
                                style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.jade),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(nickname ?? 'Recipient',
                                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                                if (isWhitelisted) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.jadeLight, borderRadius: BorderRadius.circular(20)),
                                    child: Row(children: [
                                      const Icon(Icons.verified_rounded, color: AppColors.jade, size: 11),
                                      const SizedBox(width: 3),
                                      Text('Trusted', style: GoogleFonts.dmSans(
                                        fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.jade)),
                                    ]),
                                  ),
                                ],
                              ]),
                              Text(maskPhone(phone),
                                style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.text3)),
                            ],
                          )),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      // ── Tip ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.jadeLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: AppColors.jade, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            isWhitelisted
                                ? 'This is a trusted contact. Behavioural analysis will still run.'
                                : 'AI will analyse your transfer pattern before processing.',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.jadeDark),
                          )),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ── Amount input ───────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.jade, width: 1.5),
                          boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('AMOUNT (RM)',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.jade)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Text('RM ', style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text3)),
                            Expanded(
                              child: TextField(
                                controller: _amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w700,
                                  color: AppColors.text, letterSpacing: -1),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w700,
                                    color: AppColors.text3, letterSpacing: -1),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ]),
                          Text('Daily limit: RM 5,000.00',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text3)),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ── Purpose chips ──────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Purpose (optional)',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _purposes.map((p) {
                          final selected = _selectedPurpose == p;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPurpose = selected ? null : p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.jade : AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selected ? AppColors.jade : AppColors.border, width: 1.5),
                              ),
                              child: Text(p, style: GoogleFonts.dmSans(
                                fontSize: 12, fontWeight: FontWeight.w500,
                                color: selected ? Colors.white : AppColors.text2)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Balance display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.jadeLight, borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('Balance: ', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2)),
                          Text('RM ${balance.toStringAsFixed(2)}',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.jade)),
                        ]),
                      ),
                      const SizedBox(height: 24),

                      // Continue button
                      GestureDetector(
                        onTap: () => _submit(balance),
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.jadeGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          alignment: Alignment.center,
                          child: Text('Continue — Run AI Analysis',
                            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
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
}
