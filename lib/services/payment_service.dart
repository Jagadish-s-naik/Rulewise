import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rulewise/services/subscription_service.dart';

class PaymentService {
  Razorpay? _razorpay; // nullable — not initialised on web
  final SubscriptionService _subscriptionService;

  // Load from .env for security
  static String get _keyId => dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_PLACEHOLDER';

  // Controlled by .env flag
  static bool get _useMockMode => dotenv.env['ENABLE_RAZORPAY_MOCK'] == 'true';

  // Temp storage for pending transaction
  String? _pendingPlanName;
  double? _pendingAmount;
  Completer<bool>? _paymentCompleter;

  PaymentService(this._subscriptionService, {Razorpay? razorpay}) {
    // Razorpay plugin is not available on web — skip initialisation
    if (!kIsWeb) {
      _razorpay = razorpay ?? Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }
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

    // Use mock mode on web or when mock flag is set
    if (kIsWeb || _useMockMode) {
      debugPrint('💰 MOCK PAYMENT MODE: Simulating success for $planName');
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      // Capture the completer before _handlePaymentSuccess nullifies it
      final completer = _paymentCompleter;
      await _handlePaymentSuccess(
        PaymentSuccessResponse(
          'mock_payment_id',
          'mock_order_id',
          'mock_signature',
          null,
        ),
      );
      return completer?.future ?? Future.value(true);
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
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      _paymentCompleter?.complete(false);
    }

    return _paymentCompleter?.future ?? Future.value(false);
  }

  Future<bool> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success: ${response.paymentId}');

    if (_pendingPlanName == null) {
      debugPrint('❌ Error: No pending plan found during success callback');
      _paymentCompleter?.complete(false);
      _paymentCompleter = null;
      return false;
    }

    debugPrint('🔄 Calling upgradeToPremium for: $_pendingPlanName');

    // Capture references before clearing state
    final completer = _paymentCompleter;
    final planName = _pendingPlanName!;
    final pendingAmount = _pendingAmount ?? 0.0;

    // Clear pending state BEFORE the async call
    _pendingPlanName = null;
    _pendingAmount = null;
    _paymentCompleter = null;

    try {
      await _subscriptionService.upgradeToPremium(
        transactionId: response.paymentId ?? 'mock_id',
        amount: pendingAmount,
        planType: planName.toLowerCase(),
      );

      debugPrint('✅ upgradeToPremium completed successfully');
      completer?.complete(true);
      return true;
    } catch (e) {
      debugPrint('❌ Error in upgradeToPremium: $e');
      completer?.complete(false);
      return false;
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
