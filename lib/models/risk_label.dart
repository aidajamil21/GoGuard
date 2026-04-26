enum RiskLabel { low, medium, high }

extension RiskLabelExtension on RiskLabel {
  String get displayName {
    switch (this) {
      case RiskLabel.low:
        return 'LOW';
      case RiskLabel.medium:
        return 'MEDIUM';
      case RiskLabel.high:
        return 'HIGH';
    }
  }
}
