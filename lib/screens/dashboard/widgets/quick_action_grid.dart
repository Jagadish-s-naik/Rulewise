import 'package:flutter/material.dart';

class QuickActionGrid extends StatelessWidget {
  final VoidCallback onEmergencyTap;
  final VoidCallback onAiTap;
  final VoidCallback onAddLicenseTap;
  final VoidCallback onUploadDocTap;

  const QuickActionGrid({
    super.key,
    required this.onEmergencyTap,
    required this.onAiTap,
    required this.onAddLicenseTap,
    required this.onUploadDocTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B), // Slate 800
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Emergency Button (Large Red)
            Expanded(
              child: _buildLargeCard(
                label: 'Emergency',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFDC2626), // Red 600
                onTap: onEmergencyTap,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 16),
            // Ask AI Button (Large Blue)
            Expanded(
              child: _buildLargeCard(
                label: 'Ask AI',
                icon: Icons.smart_toy_rounded,
                color: const Color(0xFF2563EB), // Blue 600
                onTap: onAiTap,
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Add License (White/Light)
            Expanded(
              child: _buildSecondaryCard(
                label: 'Add License',
                icon: Icons.add_rounded,
                color: const Color(0xFF2563EB),
                onTap: onAddLicenseTap,
              ),
            ),
            const SizedBox(width: 16),
            // Upload Doc (White/Light)
            Expanded(
              child: _buildSecondaryCard(
                label: 'Upload Doc',
                icon: Icons.upload_file_rounded,
                color: const Color(0xFF2563EB),
                onTap: onUploadDocTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 140, // Fixed: Increased height to prevent overflow
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), // Glassy effect
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1, // Subtle elevation
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 120, // Fixed: Increased height
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
