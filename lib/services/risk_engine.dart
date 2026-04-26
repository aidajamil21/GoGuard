import '../models/risk_label.dart';

class RiskResult {
  final double finalScore;
  final RiskLabel riskLabel;
  const RiskResult({
    required this.finalScore,
    required this.riskLabel,
  });
}

// ───────────────────────────────────────────────────
// Risk Engine — Pure Dart, no I/O, no side effects
// Formula: Final_Score = 0.5 * GNN + 0.5 * XGBoost
// Thresholds:
//   LOW    → score < 0.4
//   MEDIUM → 0.4 ≤ score < 0.7
//   HIGH   → score ≥ 0.7
// ───────────────────────────────────────────────────
class RiskEngine {
  RiskEngine._(); // Prevent instantiation

  static RiskResult compute(double gnnScore, double xgbScore) {
    // Step 1: Weighted average
    final double finalScore = (0.5 * gnnScore) + (0.5 * xgbScore);

    // Step 2: Clamp to [0,1] for floating point safety
    final double clamped = finalScore.clamp(0.0, 1.0);

    // Step 3: Assign label
    final RiskLabel label;
    if (clamped < 0.4) {
      label = RiskLabel.low;
    } else if (clamped < 0.7) {
      label = RiskLabel.medium;
    } else {
      label = RiskLabel.high;
    }

    return RiskResult(finalScore: clamped, riskLabel: label);
  }
}
