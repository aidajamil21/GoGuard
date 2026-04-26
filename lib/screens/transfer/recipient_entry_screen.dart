import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_event.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../blocs/whitelist_cubit/whitelist_cubit.dart';
import '../../blocs/whitelist_cubit/whitelist_state.dart';
import '../../models/whitelist_entry.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';

class RecipientEntryScreen extends StatefulWidget {
  const RecipientEntryScreen({super.key});
  @override
  State<RecipientEntryScreen> createState() => _RecipientEntryScreenState();
}

class _RecipientEntryScreenState extends State<RecipientEntryScreen> {
  final _phoneCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit({bool isWhitelisted = false, String? nickname}) {
    var raw = _phoneCtrl.text.trim();
    // UI shows +60 prefix — strip any duplicate prefix the user may have typed
    if (raw.startsWith('+60')) {
      raw = raw.substring(3);
    } else if (raw.startsWith('60')) {
      raw = raw.substring(2);
    } else if (raw.startsWith('0')) {
      raw = raw.substring(1);
    }
    final phone = '+60$raw';
    if (!validateMalaysianPhone(phone)) {
      setState(() => _error = 'Enter a valid number (e.g. 1234567890)');
      return;
    }
    setState(() => _error = null);
    context.read<TransferBloc>().add(
      RecipientSubmitted(phone, isWhitelisted: isWhitelisted, nickname: nickname),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listenWhen: (_, s) =>
          s is RecipientCheckedState ||
          s is WhitelistedRecipientState ||
          s is TransferErrorState,
      listener: (context, state) {
        if (state is RecipientCheckedState) {
          Navigator.pushNamed(context, '/transfer/recipient-check');
        }
        if (state is WhitelistedRecipientState) {
          Navigator.pushNamed(context, '/transfer/amount');
        }
        if (state is TransferErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error. Please try again.'),
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
              decoration: BoxDecoration(gradient: AppColors.jadeGradient),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Transfer',
                          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                    // Phone input row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: _error != null
                              ? Border.all(color: AppColors.danger, width: 1.5)
                              : Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: AppColors.border)),
                            ),
                            child: Text('+60',
                              style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.jade)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
                              decoration: InputDecoration(
                                hintText: '1X-XXXXXXXX',
                                hintStyle: GoogleFonts.dmSans(color: AppColors.text3),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          BlocBuilder<TransferBloc, TransferState>(
                            builder: (context, state) {
                              if (state is RecipientCheckingState) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: AppColors.jade, strokeWidth: 2)),
                                );
                              }
                              return GestureDetector(
                                onTap: () => _submit(),
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.jade,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Check',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              );
                            },
                          ),
                        ]),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(_error!,
                          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),

            // ── Whitelist contacts ───────────────────────
            Expanded(
              child: BlocBuilder<WhitelistCubit, WhitelistState>(
                builder: (context, wState) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (wState.entries.isNotEmpty) ...[
                        _sectionHeader('Trusted Contacts', Icons.verified_user_rounded, AppColors.jade),
                        ...wState.entries.map((e) => _contactTile(
                          entry: e,
                          isTrusted: true,
                          onTap: () {
                            _phoneCtrl.text = e.phone;
                            _submit(isWhitelisted: true, nickname: e.nickname);
                          },
                        )),
                        const Divider(color: AppColors.border, height: 1),
                      ],
                      _sectionHeader('Recent Contacts', Icons.history_rounded, AppColors.text3),
                      _emptyRecentHint(),
                    ],
                  );
                },
              ),
            ),

            // ── Balance footer ────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.jade, size: 16),
                const SizedBox(width: 6),
                Text('Available balance: ',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2)),
                Text('RM 5,000.00',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.jade)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(title,
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
      ]),
    );
  }

  Widget _contactTile({
    required WhitelistEntry entry,
    required bool isTrusted,
    required VoidCallback onTap,
  }) {
    final initials = entry.nickname.isNotEmpty ? entry.nickname[0].toUpperCase() : '?';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.card,
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.jadeLight, shape: BoxShape.circle),
            child: Center(
              child: Text(initials,
                style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.jade)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(entry.nickname,
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(width: 8),
                if (isTrusted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.jadeLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      const Icon(Icons.verified_rounded, color: AppColors.jade, size: 11),
                      const SizedBox(width: 3),
                      Text('Trusted',
                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.jade)),
                    ]),
                  ),
              ]),
              Text(entry.phone,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text3)),
            ],
          )),
          const Icon(Icons.chevron_right, color: AppColors.text3, size: 20),
        ]),
      ),
    );
  }

  Widget _emptyRecentHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text('No recent transfers',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text3)),
      ),
    );
  }
}
