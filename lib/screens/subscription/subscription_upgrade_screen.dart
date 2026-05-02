import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../models/subscription_plan.dart';
import '../../theme/app_theme.dart';

class SubscriptionUpgradeScreen extends StatefulWidget {
  const SubscriptionUpgradeScreen({super.key});

  @override
  State<SubscriptionUpgradeScreen> createState() =>
      _SubscriptionUpgradeScreenState();
}

class _SubscriptionUpgradeScreenState extends State<SubscriptionUpgradeScreen> {
  bool _isLoading = false;

  Future<void> _upgradeTo(SubscriptionTier tier) async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final userEmail = authService.currentUser?.email ?? 'user@example.com';
      const userPhone =
          '9876543210'; // In a real app, fetch from ProfileService

      // Map tier to amount
      double amount = 0;
      switch (tier) {
        case SubscriptionTier.protection:
          amount = 249;
          break;
        case SubscriptionTier.businessShield:
          amount = 399;
          break;
        case SubscriptionTier.enterprise:
          amount = 999;
          break;
        default:
          amount = 0;
      }

      if (amount > 0) {
        // Trigger Payment Flow
        final isSuccess = await context.read<PaymentService>().openCheckout(
              amount: amount,
              planName: tier.name,
              userEmail: userEmail,
              userPhone: userPhone,
            );

        if (!mounted) return;

        if (isSuccess) {
          // Check if upgrade was successful
          final newTier = context.read<SubscriptionService>().currentTier;

          if (newTier == tier || newTier == SubscriptionTier.businessShield || newTier == SubscriptionTier.enterprise || newTier == SubscriptionTier.protection) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Successfully upgraded to ${tier.name}!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Payment processing... Please refresh later.'),
                backgroundColor: Colors.orange,
              ),
            );
          }

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Payment failed or cancelled.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = context.watch<SubscriptionService>().currentTier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose Your Protection',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stay compliant and grow your business worry-free',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildPlanCard(
                  title: 'Free',
                  price: '₹0',
                  description: 'Perfect for getting started',
                  features: [
                    'Basic Dashboard',
                    'License List',
                    '3 AI Queries/Week',
                  ],
                  tier: SubscriptionTier.free,
                  currentTier: currentTier,
                  color: AppTheme.textSecondary,
                ),
                _buildPlanCard(
                  title: 'Protection',
                  price: '₹249/mo',
                  description: 'For growing businesses',
                  features: [
                    'Everything in Free',
                    'Renewal Alerts',
                    'Risk Monitor',
                    '15 AI Queries/Week',
                  ],
                  tier: SubscriptionTier.protection,
                  currentTier: currentTier,
                  color: AppTheme.primaryBlue,
                  isPopular: true,
                ),
                _buildPlanCard(
                  title: 'Business Shield',
                  price: '₹399/mo',
                  description: 'For established businesses',
                  features: [
                    'Everything in Protection',
                    'Fine Simulator',
                    '50 AI Queries/Week',
                    'Priority Support',
                  ],
                  tier: SubscriptionTier.businessShield,
                  currentTier: currentTier,
                  color: AppTheme.warningOrange,
                ),
                _buildPlanCard(
                  title: 'Enterprise',
                  price: '₹999/mo',
                  description: 'For large organizations',
                  features: [
                    'All Features',
                    'Multi-Business Support',
                    'Unlimited AI Assistant',
                    'Dedicated Account Manager',
                    'API Access',
                  ],
                  tier: SubscriptionTier.enterprise,
                  currentTier: currentTier,
                  color: AppTheme.secondaryPurple,
                ),
                if (!context.read<SubscriptionService>().hasUsedTrial &&
                    currentTier == SubscriptionTier.free)
                  _buildTrialCard(context),

                const SizedBox(height: 24),
                // Trust Elements
                _buildTrustElements(),
              ],
            ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required SubscriptionTier tier,
    required SubscriptionTier currentTier,
    required Color color,
    bool isPopular = false,
  }) {
    final isCurrent = currentTier == tier;
    final isUpgrade = tier.index > currentTier.index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPopular
            ? [
                // Blue glow for popular card
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                // Standard shadow for other cards
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: isPopular ? Border.all(color: color, width: 2) : null,
            // Gradient overlay for popular card
            gradient: isPopular
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.03),
                      Colors.white,
                      color.withValues(alpha: 0.02),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(28), // Updated to 28px
            child: Column(
              children: [
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: color),
                          const SizedBox(width: 8),
                          Text(f),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () => _upgradeTo(tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey : color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isCurrent
                          ? 'Current Plan'
                          : isUpgrade
                              ? 'Upgrade'
                              : 'Downgrade',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustElements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.1)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppTheme.accentGreen, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '7-Day Money Back Guarantee',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.support_agent,
                  color: AppTheme.secondaryPurple, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '24/7 Customer Support',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            Colors.teal.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.yellow, size: 28),
              SizedBox(width: 8),
              Text(
                '7-Day Free Trial',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Experience the full power of Business Shield completely risk-free for 7 days. No credit card required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _activateTrial(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                'Start My Free Trial',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _activateTrial() async {
    setState(() => _isLoading = true);
    // Use context.read directly (this.context)
    final subscriptionService = context.read<SubscriptionService>();

    try {
      await subscriptionService.activateTrial();
      if (!mounted) return;

      Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Your 7-Day Free Trial has started!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
