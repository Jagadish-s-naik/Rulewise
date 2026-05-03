import 'package:flutter_test/flutter_test.dart';
import 'package:rulewise/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    test('signIn soft fails when firebase auth is null (offline/uninitialized)', () async {
      // Intentionally pass null to simulate Firebase not being initialized
      final authService = AuthService(auth: null, firestore: null);

      final result = await authService.signIn(email: 'test@test.com', password: 'password');

      expect(result, isFalse);
      expect(authService.errorMessage, equals('Service unavailable'));
      expect(authService.isLoading, isFalse);
    });

    test('signUp soft fails when firebase auth is null (offline/uninitialized)', () async {
      final authService = AuthService(auth: null, firestore: null);

      final result = await authService.signUp(
        email: 'test@test.com',
        password: 'password',
        businessName: 'My Business',
      );

      expect(result, isFalse);
      expect(authService.errorMessage, equals('Service unavailable (Offline/Init failed)'));
      expect(authService.isLoading, isFalse);
    });
  });
}
