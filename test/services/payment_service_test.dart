import 'package:flutter_test/flutter_test.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rulewise/services/payment_service.dart';
import 'package:rulewise/services/subscription_service.dart';

// Fake Razorpay to avoid using Mockito generated mocks
class FakeRazorpay implements Razorpay {
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  
  @override
  void on(String event, Function handler) {
    if (event == Razorpay.EVENT_PAYMENT_SUCCESS) {
      onSuccess = handler as Function(PaymentSuccessResponse);
    } else if (event == Razorpay.EVENT_PAYMENT_ERROR) {
      onFailure = handler as Function(PaymentFailureResponse);
    }
  }

  @override
  void open(Map<String, dynamic> options) {
    // Simulate immediately calling onSuccess or onFailure based on test setup.
    // By default, simulate success.
    if (onSuccess != null) {
      onSuccess!(PaymentSuccessResponse.fromMap({
        'razorpay_payment_id': 'pay_123',
        'razorpay_order_id': 'order_123',
        'razorpay_signature': 'sig_123'
      }));
    }
  }

  @override
  void clear() {}
}

class FakeSubscriptionService extends SubscriptionService {
  String? upgradedPlanName;
  
  @override
  Future<void> upgradeToPremium({
    required String transactionId,
    required double amount,
    required String planType,
  }) async {
    upgradedPlanName = planType;
  }
}

void main() {
  group('PaymentService Tests', () {
    late FakeSubscriptionService fakeSubscriptionService;
    late FakeRazorpay fakeRazorpay;
    late PaymentService paymentService;

    setUp(() {
      fakeSubscriptionService = FakeSubscriptionService();
      fakeRazorpay = FakeRazorpay();
      paymentService = PaymentService(
        fakeSubscriptionService,
        razorpay: fakeRazorpay,
      );
    });

    test('openCheckout completes successfully when mock mode simulates success', () async {
      final result = await paymentService.openCheckout(
        amount: 500,
        planName: 'protection',
        userPhone: '1234567890',
        userEmail: 'test@example.com',
      );

      expect(result, isTrue);
    });
  });
}
