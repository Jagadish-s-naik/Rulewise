import 'package:flutter/material.dart';
import 'package:rulewise/theme/app_theme.dart';

/// Alert Banner Component
/// Red or amber banners with left border for critical alerts and warnings
class AlertBanner extends StatelessWidget {
  final AlertType type;
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AlertBanner({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: config.borderColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: config.borderColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: config.iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config.icon,
                color: config.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: config.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: config.textColor.withValues(alpha: 0.8),
                    ),
                  ),
                  if (onAction != null && actionLabel != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        actionLabel!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: config.borderColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: config.textColor.withValues(alpha: 0.5),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _AlertConfig _getConfig() {
    switch (type) {
      case AlertType.critical:
        return _AlertConfig(
          backgroundColor: AppTheme.dangerRed.withValues(alpha: 0.08),
          borderColor: AppTheme.dangerRed,
          iconBackgroundColor: AppTheme.dangerRed.withValues(alpha: 0.15),
          iconColor: AppTheme.dangerRed,
          textColor: AppTheme.dangerRed.withValues(alpha: 0.9),
          icon: Icons.error_outline,
        );
      case AlertType.warning:
        return _AlertConfig(
          backgroundColor: AppTheme.warningOrange.withValues(alpha: 0.08),
          borderColor: AppTheme.warningOrange,
          iconBackgroundColor: AppTheme.warningOrange.withValues(alpha: 0.15),
          iconColor: AppTheme.warningOrange,
          textColor: AppTheme.warningOrange.withValues(alpha: 0.9),
          icon: Icons.warning_amber_outlined,
        );
      case AlertType.info:
        return _AlertConfig(
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
          borderColor: AppTheme.primaryBlue,
          iconBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
          iconColor: AppTheme.primaryBlue,
          textColor: AppTheme.primaryBlue.withValues(alpha: 0.9),
          icon: Icons.info_outline,
        );
    }
  }
}

enum AlertType { critical, warning, info }

class _AlertConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  _AlertConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
