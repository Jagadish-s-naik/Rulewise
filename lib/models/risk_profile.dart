class RiskProfile {
  final double overallScore; // 0 to 100
  final RiskLevel level;
  final List<RiskFactor> riskFactors;
  final DateTime lastCalculated;

  RiskProfile({
    required this.overallScore,
    required this.level,
    required this.riskFactors,
    required this.lastCalculated,
  });

  factory RiskProfile.initial() {
    return RiskProfile(
      overallScore: 100,
      level: RiskLevel.safe,
      riskFactors: [],
      lastCalculated: DateTime.now(),
    );
  }
}

enum RiskLevel {
  safe, // Score > 70
  warning, // Score 30-70
  highRisk, // Score < 30
}

class RiskFactor {
  final String description; // e.g., "3 Licenses Expired"
  final double impact; // e.g., -15.0
  final bool isCritical;

  RiskFactor({
    required this.description,
    required this.impact,
    this.isCritical = false,
  });
}
