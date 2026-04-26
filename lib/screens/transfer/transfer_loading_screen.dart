import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../theme/app_colors.dart';

class TransferLoadingScreen extends StatefulWidget {
  const TransferLoadingScreen({super.key});
  @override
  State<TransferLoadingScreen> createState() => _TransferLoadingScreenState();
}

class _TransferLoadingScreenState extends State<TransferLoadingScreen> {
  // Steps: 0=Verified, 1=Encrypted, 2=Sending, 3=Confirming
  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_step < 3) {
        setState(() => _step++);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listenWhen: (_, s) => s is TransferSuccessState || s is TransferErrorState,
      listener: (context, state) {
        if (state is TransferSuccessState) {
          Navigator.pushReplacementNamed(context, '/transfer/success');
        }
        if (state is TransferErrorState) {
          switch (state.errorType) {
            case ErrorType.scamBlocked:
              Navigator.pushReplacementNamed(context, '/error/scam-blocked');
            case ErrorType.insufficientFunds:
              Navigator.pushReplacementNamed(context, '/error/insufficient-funds');
            case ErrorType.networkTimeout:
            case ErrorType.unknown:
              Navigator.pushReplacementNamed(context, '/error/timeout');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ── Shield icon ──────────────────────────
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.jadeDark,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: AppColors.jadeGlow, blurRadius: 32, offset: const Offset(0, 8)),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.jade, width: 3),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded, color: AppColors.jade, size: 26),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(children: [
                  Text('Transferring your\nmoney safely',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 26, fontWeight: FontWeight.w700,
                      color: AppColors.text, letterSpacing: -0.5, height: 1.2)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Secure transfer in progress',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2)),
                    _dot(0), _dot(200), _dot(400),
                  ]),
                ]),
              ),

              const SizedBox(height: 36),

              // ── Step progress bar ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  // Progress track
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(height: 4, decoration: BoxDecoration(
                        color: AppColors.jadeMid,
                        borderRadius: BorderRadius.circular(2),
                      )),
                      FractionallySizedBox(
                        widthFactor: (_step / 3).clamp(0.0, 1.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.jade,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Step labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stepLabel('Verified',   0),
                      _stepLabel('Encrypted',  1),
                      _stepLabel('Sending',    2),
                      _stepLabel('Confirming', 3),
                    ],
                  ),
                ]),
              ),

              const SizedBox(height: 40),

              // ── Checklist ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  _checkRow('GoGuard', 'Recipient verified safe'),
                  const SizedBox(height: 8),
                  _checkRow('256-bit encryption', 'applied'),
                  const SizedBox(height: 8),
                  _checkRow('Routing', 'via secure TNG network'),
                ]),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepLabel(String label, int index) {
    final isDone    = _step > index;
    final isActive  = _step == index;
    return Column(children: [
      if (isDone)
        Text('✓ $label',
          style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.jade))
      else
        Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? AppColors.jadeDark : AppColors.text3,
          )),
    ]);
  }

  Widget _checkRow(String bold, String normal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(color: AppColors.jade, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        RichText(text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2),
          children: [
            TextSpan(text: '$bold ',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppColors.text)),
            TextSpan(text: '— $normal'),
          ],
        )),
      ]),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 700 + delayMs),
      curve: Curves.easeInOut,
      builder: (ctx, v, child) => Opacity(opacity: v, child: child),
      child: const Text(' •',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.jade)),
    );
  }
}
