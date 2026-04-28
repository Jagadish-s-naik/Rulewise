import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class PremiumRiskGauge extends StatelessWidget {
  final double score; // 0.0 (High Risk) to 1.0 (Safe)
  final int expiringCount;
  final int daysToExpiry;

  const PremiumRiskGauge({
    super.key,
    required this.score,
    required this.expiringCount,
    required this.daysToExpiry,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status based on score
    String statusText;
    Color statusColor;
    Color bgColor;

    if (score >= 0.8) {
      statusText = 'Low Risk';
      statusColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (score >= 0.5) {
      statusText = 'Medium';
      statusColor = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.1);
    } else {
      statusText = 'High Risk';
      statusColor = Colors.red;
      bgColor = Colors.red.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Softer rounding
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Compliance Risk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Gradient Bar
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.orange, Colors.red],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Indicator Logic: 1.0 is Left (Green), 0.0 is Right (Red)
              // Actually normally 100% compliance is Green.
              // So if score is 1.0 (Green), position should be LEFT?
              // Let's assume Left=Safe (Green), Right=Risk (Red) for the gradient.
              // So Score 1.0 -> Alignment(-1.0)
              // Score 0.0 -> Alignment(1.0)
              LayoutBuilder(builder: (context, constraints) {
                // Invert score for position: 1.0 (Safe) -> 0.0 (Left), 0.0 (Risk) -> 1.0 (Right)
                // Wait, gradient is Green->Orange->Red.
                // So Green is Left.
                // Compliance Score 100% (1.0) = Green = Left.
                // Compliance Score 0% (0.0) = Red = Right.
                // So Position = (1.0 - score) * width.
                final position = (1.0 - score).clamp(0.0, 1.0) *
                    (constraints.maxWidth - 24); // -24 for thumb width

                return Transform.translate(
                  offset:
                      Offset(position, -6), // Center vertically relative to bar
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                          color: statusColor, width: 4), // Dynamic border color
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low Risk',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              Text(
                'High Risk',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          if (expiringCount > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$expiringCount licenses expiring in $daysToExpiry days. Renew now to avoid penalties.',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
