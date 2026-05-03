import 'package:flutter_test/flutter_test.dart';
import 'package:rulewise/services/subscription_service.dart';

void main() {
  group('SubscriptionService Tests', () {
    test('init soft fails and handles null firestore gracefully', () async {
      // Simulate missing firestore by passing null
      final service = SubscriptionService(firestore: null, auth: null);

      // Normally it throws if it tries to access firestore!.collection
      // But we added soft fails, so it shouldn't throw an error.
      await service.init();
      
      // If we reach here, it soft failed correctly.
      expect(service.currentTier.name, equals('free'));
    });
  });
}
