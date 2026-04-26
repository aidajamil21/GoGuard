import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/whitelist_cubit/whitelist_cubit.dart';
import '../../blocs/whitelist_cubit/whitelist_state.dart';
import '../../models/whitelist_entry.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';

class WhitelistScreen extends StatelessWidget {
  const WhitelistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── Jade header ───────────────────────────────
          Container(
            decoration: BoxDecoration(gradient: AppColors.jadeGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Trusted Contacts',
                        style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.add, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('Add', style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'Trusted contacts bypass the GNN scam network check. Behavioural analysis still runs.',
                          style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4),
                        )),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Contact list ──────────────────────────────
          Expanded(
            child: BlocBuilder<WhitelistCubit, WhitelistState>(
              builder: (context, state) {
                if (state.entries.isEmpty) {
                  return _emptyState(context);
                }
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(children: [
                        Text('${state.entries.length} trusted contact${state.entries.length == 1 ? '' : 's'}',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                      ]),
                    ),
                    ...state.entries.map((e) => _contactCard(context, e)),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.jade,
        elevation: 4,
        icon: const Icon(Icons.verified_user_rounded, color: Colors.white),
        label: Text('Add Trusted Contact',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.jadeLight, shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.verified_user_rounded, color: AppColors.jade, size: 40)),
            ),
            const SizedBox(height: 20),
            Text('No Trusted Contacts Yet',
              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(
              'Add people you know and trust. They will bypass the scam network check when you transfer to them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _showAddSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.jadeGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Text('Add First Contact',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(BuildContext context, WhitelistEntry entry) {
    final initials = entry.nickname.isNotEmpty ? entry.nickname[0].toUpperCase() : '?';
    final daysAgo = DateTime.now().difference(entry.addedAt).inDays;
    final addedLabel = daysAgo == 0 ? 'Added today' : 'Added $daysAgo day${daysAgo == 1 ? '' : 's'} ago';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.jadeLight, shape: BoxShape.circle),
            child: Center(
              child: Text(initials,
                style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.jade)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(entry.nickname,
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.jadeLight, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.verified_rounded, color: AppColors.jade, size: 11),
                    const SizedBox(width: 3),
                    Text('Trusted', style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.jade)),
                  ]),
                ),
              ]),
              const SizedBox(height: 2),
              Text(entry.phone,
                style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.text3)),
              const SizedBox(height: 2),
              Text(addedLabel,
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3)),
            ],
          )),

          // Remove button
          GestureDetector(
            onTap: () => _confirmRemove(context, entry),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.dangerLight, shape: BoxShape.circle),
              child: const Center(
                child: Icon(Icons.close_rounded, color: AppColors.danger, size: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WhitelistEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${entry.nickname}?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppColors.text)),
        content: Text(
          '${entry.nickname} will no longer be a trusted contact. Future transfers will go through the full scam check.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.text2))),
          TextButton(
            onPressed: () {
              context.read<WhitelistCubit>().removeEntry(entry.phone);
              Navigator.pop(context);
            },
            child: Text('Remove', style: GoogleFonts.dmSans(color: AppColors.danger, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final nickCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 20, 24,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),

                // Title
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.jadeLight, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.jade, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Add Trusted Contact',
                    style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                ]),
                const SizedBox(height: 20),

                // Nickname field
                Text('Name / Nickname',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
                const SizedBox(height: 6),
                _sheetInput(nickCtrl, 'e.g. Mum, Ali, Office'),
                const SizedBox(height: 16),

                // Phone field
                Text('Phone Number',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
                const SizedBox(height: 6),
                _sheetInput(phoneCtrl, '+601X-XXXXXXXX or 01X-XXXXXXXX',
                  keyboardType: TextInputType.phone),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(error!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.danger)),
                ],
                const SizedBox(height: 24),

                // Warning note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warnLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warn.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warn, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Only add people you personally know and trust.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF92400E)),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),

                // Add button
                GestureDetector(
                  onTap: () {
                    final phone = phoneCtrl.text.trim();
                    final name  = nickCtrl.text.trim();
                    if (name.isEmpty) {
                      setSheetState(() => error = 'Please enter a name');
                      return;
                    }
                    if (!validateMalaysianPhone(phone)) {
                      setSheetState(() => error = 'Enter a valid Malaysian phone number');
                      return;
                    }
                    // Check for duplicates
                    final wState = context.read<WhitelistCubit>().state;
                    if (wState.contains(phone)) {
                      setSheetState(() => error = 'This number is already in your whitelist');
                      return;
                    }
                    context.read<WhitelistCubit>().addEntry(phone, name);
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name added to trusted contacts'),
                        backgroundColor: AppColors.jade,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppColors.jadeGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    alignment: Alignment.center,
                    child: Text('Add to Trusted Contacts',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetInput(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: AppColors.text3, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
