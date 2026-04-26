import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_event.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/phone_masker.dart';

class NewSuccessScreen extends StatefulWidget {
  const NewSuccessScreen({super.key});
  @override
  State<NewSuccessScreen> createState() => _NewSuccessScreenState();
}

class _NewSuccessScreenState extends State<NewSuccessScreen> {
  int _secondsRemaining = 28; // Cancellation window
  Timer? _timer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _startCancellationTimer();
  }

  void _startCancellationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _cancelTransaction() {
    if (_secondsRemaining <= 0 || _isCancelling) return;

    setState(() => _isCancelling = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Transfer?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'This will reverse the transaction and return the money to your wallet.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.text2)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isCancelling = false);
              Navigator.pop(context);
            },
            child: Text('Keep Transfer', style: GoogleFonts.inter(color: AppColors.text2)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performCancellation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _performCancellation() {
    // Show cancelling animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.danger),
              const SizedBox(height: 16),
              Text('Cancelling transfer...',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    // Simulate cancellation delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      Navigator.pop(context); // Close loading dialog
      
      // Show cancellation success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Transfer cancelled. Money returned to your wallet.',
                  style: GoogleFonts.inter(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Return to home
      context.read<TransferBloc>().add(TransferCancelled());
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
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
        final phone = data.recipientPhone ?? '';
        final nickname = data.recipientNickname ?? 'Recipient';

        final canCancel = _secondsRemaining > 0 && !_isCancelling;

        return Scaffold(
          backgroundColor: AppColors.success,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Text('6:00',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                      const Spacer(),
                      const Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      const Icon(Icons.wifi, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      const Icon(Icons.battery_full, color: Colors.white, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Success icon ────────────────────────────
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, color: AppColors.success, size: 48),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Amount ──────────────────────────────────
                Text('RM ${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  )),

                const SizedBox(height: 8),

                Text('Transferred',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  )),

                const Spacer(),

                // ── Cancellation window (if active) ─────────
                if (canCancel)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFA726), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFA726), width: 2),
                          ),
                          child: const Icon(Icons.remove, color: Color(0xFFFFA726), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Changed your mind? Cancel now',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                )),
                              Text('Transaction can still be reversed',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF92400E).withOpacity(0.8),
                                )),
                              Text('Tap cancel within $_secondsRemaining seconds',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF92400E).withOpacity(0.8),
                                )),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelTransaction,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (canCancel) const SizedBox(height: 20),

                // ── Transaction details card ────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Receiver', nickname.toUpperCase()),
                      const Divider(height: 24),
                      _detailRow('Remark', 'Fund Transfer'),
                      const Divider(height: 24),
                      _detailRow('Date & Time', 
                        '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}'),
                      const Divider(height: 24),
                      _detailRow('Reference', txnId.toUpperCase()),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ScamShield',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.text3,
                            )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                const SizedBox(width: 4),
                                Text('Verified Safe',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Action buttons ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_border, color: AppColors.warn, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share_outlined, color: AppColors.jade, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.read<TransferBloc>().add(TransferCancelled());
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.jade,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text('Done',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.text3,
          )),
        Text(value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          )),
      ],
    );
  }
}
