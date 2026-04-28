import 'package:flutter/material.dart';
import 'package:rulewise/theme/app_theme.dart';

/// Premium Badge Components
/// Pill and Dot variants with semantic colors
class PremiumBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final BadgeSize size;

  const PremiumBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.neutral,
    this.size = BadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final padding = size == BadgeSize.small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 4);
    final fontSize = size == BadgeSize.small ? 10.0 : 11.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(100), // Full pill
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Circular',
          fontSize: fontSize,
          height: 1.2,
          letterSpacing: size == BadgeSize.small ? 0.5 : 0.3,
          fontWeight: FontWeight.w500,
          color: colors.text,
        ),
      ),
    );
  }

  _BadgeColors _getColors() {
    switch (variant) {
      case BadgeVariant.success:
        return _BadgeColors(
          background: AppTheme.accentGreen.withValues(alpha: 0.1),
          text: AppTheme.accentGreen,
        );
      case BadgeVariant.warning:
        return _BadgeColors(
          background: AppTheme.warningOrange.withValues(alpha: 0.1),
          text: AppTheme.warningOrange,
        );
      case BadgeVariant.error:
        return _BadgeColors(
          background: AppTheme.dangerRed.withValues(alpha: 0.1),
          text: AppTheme.dangerRed,
        );
      case BadgeVariant.info:
        return _BadgeColors(
          background: AppTheme.primaryBlue.withValues(alpha: 0.1),
          text: AppTheme.primaryBlue,
        );
      case BadgeVariant.neutral:
        return _BadgeColors(
          background: AppTheme.textSecondary.withValues(alpha: 0.1),
          text: AppTheme.textSecondary,
        );
    }
  }
}

/// Dot Badge for status indicators
class DotBadge extends StatelessWidget {
  final BadgeVariant variant;
  final double size;

  const DotBadge({
    super.key,
    required this.variant,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getColor() {
    switch (variant) {
      case BadgeVariant.success:
        return AppTheme.accentGreen;
      case BadgeVariant.warning:
        return AppTheme.warningOrange;
      case BadgeVariant.error:
        return AppTheme.dangerRed;
      case BadgeVariant.info:
        return AppTheme.primaryBlue;
      case BadgeVariant.neutral:
        return AppTheme.textSecondary;
    }
  }
}

/// Status Badge for licenses
class StatusBadge extends StatelessWidget {
  final LicenseStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();
    return PremiumBadge(
      text: config.text,
      variant: config.variant,
      size: BadgeSize.medium,
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case LicenseStatus.active:
        return _StatusConfig(text: 'Active', variant: BadgeVariant.success);
      case LicenseStatus.expiring:
        return _StatusConfig(
            text: 'Expiring Soon', variant: BadgeVariant.warning);
      case LicenseStatus.expired:
        return _StatusConfig(text: 'Expired', variant: BadgeVariant.error);
    }
  }
}

/// Premium Linear Progress Indicator
class PremiumLinearProgress extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;
  final double borderRadius;

  const PremiumLinearProgress({
    super.key,
    required this.value,
    this.color,
    this.height = 8.0,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
}

// Enums and Helper Classes
enum BadgeVariant { success, warning, error, info, neutral }

enum BadgeSize { small, medium }

enum LicenseStatus { active, expiring, expired }

class _BadgeColors {
  final Color background;
  final Color text;
  _BadgeColors({required this.background, required this.text});
}

class _StatusConfig {
  final String text;
  final BadgeVariant variant;
  _StatusConfig({required this.text, required this.variant});
}
