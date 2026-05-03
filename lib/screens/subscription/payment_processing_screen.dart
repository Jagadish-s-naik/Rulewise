import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

enum PaymentStatus { processing, success, failure }

class PaymentProcessingScreen extends StatefulWidget {
  final String planName;
  final double amount;
  final Future<bool> Function() onProcess;

  const PaymentProcessingScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.onProcess,
  });

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  PaymentStatus _status = PaymentStatus.processing;

  late AnimationController _pulseController;
  late AnimationController _checkController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String _statusMessage = 'Connecting to Secure Server';
  final List<String> _steps = [
    'Connecting to Secure Server',
    'Verifying Payment Identity',
    'Processing with Bank Gateway',
    'Finalizing Subscription Tier',
  ];
  int _currentStep = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();

    // Haptic feedback at start
    HapticFeedback.mediumImpact();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );


    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeIn),
    );

    _startProcessing();
  }

  void _startProcessing() {
    debugPrint('💰 PaymentProcessingScreen: Starting payment for ${widget.planName}');
    
    // Cycle through status messages
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
          _statusMessage = _steps[_currentStep];
        });
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
      }
    });

    // Run the actual payment process
    widget.onProcess().then((success) {
      debugPrint('💰 PaymentProcessingScreen: Result = $success');
      _stepTimer?.cancel();
      if (!mounted) return;

      setState(() {
        _status = success ? PaymentStatus.success : PaymentStatus.failure;
        _statusMessage = success
            ? 'Access Granted!'
            : 'Transaction Declined';
      });

      _pulseController.stop();
      _checkController.forward();
      
      if (success) {
        HapticFeedback.heavyImpact();
        // Auto-pop after success with longer delay for "wow" factor
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      } else {
        HapticFeedback.vibrate();
      }
    }).catchError((e) {
      debugPrint('💰 PaymentProcessingScreen: Error = $e');
      _stepTimer?.cancel();
      if (mounted) {
        setState(() {
          _status = PaymentStatus.failure;
          _statusMessage = 'System Error';
        });
        _pulseController.stop();
        _checkController.forward();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _status != PaymentStatus.processing,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Stack(
          children: [
            // Immersive background gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.5,
                    colors: [
                      Color(0xFF1E293B), // surfaceDark
                      AppTheme.backgroundDark,
                    ],
                  ),
                ),
              ),
            ),

            // Animated light orbs
            _buildLightOrb(Alignment.topRight, AppTheme.primaryBlue.withValues(alpha: 0.15)),
            _buildLightOrb(Alignment.bottomLeft, AppTheme.secondaryPurple.withValues(alpha: 0.1)),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo Branding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gavel_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'RULEWISE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Central Status Indicator
                    _buildCentralIndicator(),

                    const SizedBox(height: 40),

                    // Plan Badge
                    _buildPlanBadge(),

                    const SizedBox(height: 48),

                    // Dynamic Status Message
                    _buildStatusMessage(),

                    const SizedBox(height: 40),

                    // Progress Steps (Only during processing)
                    if (_status == PaymentStatus.processing)
                      _buildGlassStepsIndicator(),

                    // Success Feedback
                    if (_status == PaymentStatus.success)
                      _buildSuccessMessage(),

                    // Failure Feedback
                    if (_status == PaymentStatus.failure)
                      _buildFailureActions(),

                    const Spacer(flex: 2),

                    // Security Footer
                    _buildSecurityFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightOrb(Alignment alignment, Color color) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: 100,
                spreadRadius: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCentralIndicator() {
    if (_status == PaymentStatus.processing) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 140 * _pulseAnimation.value,
              height: 140 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryBlue,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            ),
            const Icon(Icons.shield_rounded, color: Colors.white24, size: 40),
          ],
        ),
      );
    }

    final color = _status == PaymentStatus.success ? AppTheme.accentGreen : AppTheme.dangerRed;
    final icon = _status == PaymentStatus.success ? Icons.verified_user_rounded : Icons.gpp_bad_rounded;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          Icon(icon, size: 64, color: color),
        ],
      ),
    );
  }

  Widget _buildPlanBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlue,
              boxShadow: [
                BoxShadow(color: AppTheme.primaryBlue, blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.planName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            '  •  ₹${widget.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _status == PaymentStatus.processing ? 'Secure Payment' : 
            _status == PaymentStatus.success ? 'Success' : 'Failed',
            key: ValueKey(_status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessage,
            key: ValueKey(_statusMessage),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassStepsIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: List.generate(_steps.length, (index) {
          final isDone = index < _currentStep;
          final isActive = index == _currentStep;
          final color = isDone ? AppTheme.accentGreen : (isActive ? AppTheme.primaryBlue : Colors.white24);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isDone ? const Icon(Icons.check, size: 12, color: AppTheme.accentGreen) : null,
                ),
                const SizedBox(width: 16),
                Text(
                  _steps[index],
                  style: TextStyle(
                    color: isDone ? Colors.white70 : (isActive ? Colors.white : Colors.white24),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.accentGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Premium Unlocked!',
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome to the ${widget.planName} tier. You now have full access to all protected features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureActions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.dangerRed.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'There was a problem authorizing your payment. Please check your card details and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Back to Plans',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 14),
            const SizedBox(width: 8),
            Text(
              'PCI-DSS COMPLIANT GATEWAY',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProviderLogo('VISA'),
            const SizedBox(width: 16),
            _buildProviderLogo('MasterCard'),
            const SizedBox(width: 16),
            _buildProviderLogo('UPI'),
            const SizedBox(width: 16),
            _buildProviderLogo('Razorpay'),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderLogo(String name) {
    return Text(
      name,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.15),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
