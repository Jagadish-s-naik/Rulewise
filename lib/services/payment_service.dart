import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rulewise/services/subscription_service.dart';

class PaymentService {
  late Razorpay _razorpay;
  final SubscriptionService _subscriptionService;

  // ⚠️ REPLACE WITH YOUR REAL KEY FROM RAZORPAY DASHBOARD
  static const String _keyId = 'rzp_test_PLACEHOLDER';

  // Set to TRUE to bypass real Razorpay SDK while waiting for keys
  static const bool _useMockMode = true;

  // Temp storage for pending transaction
  String? _pendingPlanName;
  double? _pendingAmount;
  Completer<bool>? _paymentCompleter;

  PaymentService(this._subscriptionService) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<bool> openCheckout({
    required double amount,
    required String planName,
    required String userEmail,
    required String userPhone,
  }) async {
    _paymentCompleter = Completer<bool>();
    
    _pendingPlanName = planName;
    _pendingAmount = amount;

    if (_useMockMode) {
      debugPrint('💰 MOCK PAYMENT MODE: Simulating success for $planName');
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate network delay
      // Manual success trigger
      await _handlePaymentSuccess(
        PaymentSuccessResponse(
          'mock_payment_id',
          'mock_order_id',
          'mock_signature',
          null,
        ),
      );
      return _paymentCompleter?.future ?? Future.value(true);
    }

    final options = {
      'key': _keyId,
      'amount': (amount * 100).toInt(), // Razorpay takes paisa
      'name': 'RuleWise',
      'description': 'Subscription for $planName',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': userPhone, 'email': userEmail},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      _paymentCompleter?.complete(false);
    }

    return _paymentCompleter?.future ?? Future.value(false);
  }

  Future<bool> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success: ${response.paymentId}');

    // Here we would verify the signature on backend.
    // For MVP/Firebase, we trust the client (RISKY - change for production) or use Cloud Functions to verify.

    if (_pendingPlanName == null) {
      debugPrint('❌ Error: No pending plan found during success callback');
      _paymentCompleter?.complete(false);
      return false;
    }

    debugPrint('🔄 Calling upgradeToPremium for: $_pendingPlanName');

    try {
      await _subscriptionService.upgradeToPremium(
        transactionId: response.paymentId ?? 'mock_id',
        amount: _pendingAmount ?? 0.0,
        planType: _pendingPlanName!.toLowerCase(),
      );

      debugPrint('✅ upgradeToPremium completed successfully');
      _paymentCompleter?.complete(true);
      return true;
    } catch (e) {
      debugPrint('❌ Error in upgradeToPremium: $e');
      _paymentCompleter?.complete(false);
      return false;
    } finally {
      // Clear pending state
      _pendingPlanName = null;
      _pendingAmount = null;
      _paymentCompleter = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _paymentCompleter?.complete(false);
    _paymentCompleter = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    _paymentCompleter?.complete(false);
    _paymentCompleter = null;
  }
}
