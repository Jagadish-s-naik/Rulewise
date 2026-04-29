import 'package:flutter/material.dart';
import 'package:rulewise/theme/app_theme.dart';
import 'dart:math' as math;

/// Premium Compliance Score Widget
/// 160px diameter circular progress with 12px stroke and trend indicator
class ComplianceScoreWidget extends StatefulWidget {
  final double score; // 0.0 to 1.0
  final double? previousScore; // For trend calculation
  final String? trendText;

  const ComplianceScoreWidget({
    super.key,
    required this.score,
    this.previousScore,
    this.trendText,
  });

  @override
  State<ComplianceScoreWidget> createState() => _ComplianceScoreWidgetState();
}

class _ComplianceScoreWidgetState extends State<ComplianceScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendPercentage = widget.previousScore != null
        ? ((widget.score - widget.previousScore!) * 100).toInt()
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
       boxShadow: [
         BoxShadow(
           color: Colors.black.withValues(alpha: 0.06),
           blurRadius: 12,
           offset: const Offset(0, 4),
         ),
       ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compliance Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ComplianceScorePainter(
                      progress: _animation.value,
                      strokeWidth: 12,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(_animation.value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getScoreLabel(widget.score),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _getScoreColor(widget.score),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (trendPercentage != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                 decoration: BoxDecoration(
                   color: trendPercentage >= 0
                       ? AppTheme.accentGreen.withValues(alpha: 0.1)
                       : AppTheme.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendPercentage >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: trendPercentage >= 0
                          ? AppTheme.accentGreen
                          : AppTheme.dangerRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.trendText ??
                          '${trendPercentage.abs()}% from last month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trendPercentage >= 0
                            ? AppTheme.accentGreen
                            : AppTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.75) return 'Good';
    if (score >= 0.6) return 'Fair';
    return 'Needs Attention';
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return AppTheme.accentGreen;
    if (score >= 0.75) return AppTheme.primaryBlue;
    if (score >= 0.6) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }
}

class _ComplianceScorePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _ComplianceScorePainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

     // Background circle
     final backgroundPaint = Paint()
       ..color = AppTheme.textSecondary.withValues(alpha: 0.1)
       ..style = PaintingStyle.stroke
       ..strokeWidth = strokeWidth
       ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppTheme.primaryBlue,
          AppTheme.secondaryPurple,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ComplianceScorePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
