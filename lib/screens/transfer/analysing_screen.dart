import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/transfer_bloc/transfer_bloc.dart';
import '../../blocs/transfer_bloc/transfer_state.dart';
import '../../theme/app_colors.dart';

class AnalysingScreen extends StatefulWidget {
  const AnalysingScreen({super.key});
  @override
  State<AnalysingScreen> createState() => _AnalysingScreenState();
}

class _AnalysingScreenState extends State<AnalysingScreen> {
  // 0 = GNN running, 1 = XGBoost running, 2 = LLM running, 3 = all done
  int _stage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fallback: if RiskFusedState was already emitted before this screen mounted
    // (race condition on web with instant mock), navigate immediately on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<TransferBloc>().state;
      if (s is RiskFusedState) {
        Navigator.pushReplacementNamed(context, '/transfer/warning');
      } else if (s is TransferErrorState) {
        Navigator.pushReplacementNamed(context, '/error/timeout');
      }
    });
    // Advance stage every 1.8s — purely visual, actual result driven by BLoC
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_stage < 3) {
        setState(() => _stage++);
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
      listenWhen: (_, s) => s is RiskFusedState || s is TransferErrorState,
      listener: (context, state) {
        if (state is RiskFusedState) {
          Navigator.pushReplacementNamed(context, '/transfer/warning');
        }
        if (state is TransferErrorState) {
          Navigator.pushReplacementNamed(context, '/error/timeout');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Shield badge
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
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.jade, width: 3),
                    ),
                    child: const Center(
                      child: Icon(Icons.shield_rounded, color: AppColors.jade, size: 28),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text('Analysing Transfer', textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.text, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('GoGuard AI is running',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2)),
                _dot(0), _dot(150), _dot(300),
              ]),

              const SizedBox(height: 28),

              // ── Three-stage progress ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  _stageRow(
                    icon: Icons.hub_rounded,
                    label: 'GNN Network Check',
                    stage: 0,
                    doneStatus: 'Safe',
                    runningStatus: 'Scanning graph...',
                  ),
                  const SizedBox(height: 12),
                  _stageRow(
                    icon: Icons.psychology_rounded,
                    label: 'XGBoost Behavioural Model',
                    stage: 1,
                    doneStatus: 'Complete',
                    runningStatus: 'Analysing patterns...',
                  ),
                  const SizedBox(height: 12),
                  _stageRow(
                    icon: Icons.auto_awesome,
                    label: 'AI Explanation',
                    stage: 2,
                    doneStatus: 'Ready',
                    runningStatus: 'Generating...',
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // Overall progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Overall', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text2)),
                        Text('${((_stage / 3) * 100).toInt()}%',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.jade)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _stage / 3,
                        backgroundColor: AppColors.jadeLight,
                        color: AppColors.jade,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageRow({
    required IconData icon,
    required String label,
    required int stage,        // which stage index this row represents
    required String doneStatus,
    required String runningStatus,
  }) {
    final isDone    = _stage > stage;
    final isRunning = _stage == stage;
    final isPending = _stage < stage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? AppColors.jadeLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning ? AppColors.jade : AppColors.border,
          width: isRunning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.jade
                    : isRunning
                        ? AppColors.jadeLight
                        : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : isRunning
                      ? const SizedBox(
                          width: 12, height: 12,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.jade),
                          ))
                      : Icon(icon, color: AppColors.text3, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: isRunning ? FontWeight.w700 : FontWeight.w500,
                color: isPending ? AppColors.text3 : AppColors.text,
              ))),
            Text(
              isDone ? doneStatus : isRunning ? runningStatus : 'Queued',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDone ? AppColors.jade : isRunning ? AppColors.warn : AppColors.text3,
              ),
            ),
          ]),
          // Animated progress bar when this stage is running
          if (isRunning) ...[
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              key: ValueKey('prog_$stage'),
              tween: Tween(begin: 0.0, end: 0.9),
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeOut,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.jadeMid,
                  color: AppColors.jade,
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: const Text('.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text)),
    );
  }
}
