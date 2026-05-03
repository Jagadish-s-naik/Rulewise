import 'dart:async'; // For StreamSubscription
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  StreamSubscription<User?>? _authStateSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore}) {
    _auth = auth;
    _firestore = firestore;
    _initialize();
  }

  void _initialize() {
    try {
      _auth ??= FirebaseAuth.instance;
      _firestore ??= FirebaseFirestore.instance;

      _authStateSubscription = _auth?.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthService: Firebase not initialized or not available: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String businessName,
  }) async {
    if (_auth == null) {
      _errorMessage = 'Service unavailable (Offline/Init failed)';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential =
          await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String userId = userCredential.user!.uid;

      // Create user profile in Firestore
      if (_firestore != null) {
        await _firestore!.collection('users').doc(userId).set({
          'email': email,
          'business_name': businessName,
          'created_at': FieldValue.serverTimestamp(),
          'profile_completed': false,
          'aadhaar_verified': false,
          'pan_verified': false,
          'location': null,
          'business_type': null,
          // Subscription fields
          'subscription_tier': 'free',
          'is_premium': false,
          'ai_queries_this_week': 0,
          'has_used_trial': false,
        });
        debugPrint('✅ Created user document with subscription_tier=free');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Sign In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      _errorMessage = 'Service unavailable';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth?.signOut();
    notifyListeners();
  }

  // Phone Authentication Methods
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    if (_auth == null) {
      onError('Service unavailable');
      return;
    }

    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          try {
            await _auth?.signInWithCredential(credential);
            notifyListeners();
          } catch (e) {
            debugPrint('Auto-verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Code auto-retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<UserCredential?> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (_auth == null) return null;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth!.signInWithCredential(credential);
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with OTP: $e');
      rethrow;
    }
  }

  // Password Reset
  Future<bool> resetPassword(String email) async {
    if (_auth == null) return false;
    try {
      await _auth!.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Email OTP Authentication Methods

  /// Send OTP to email using Gmail SMTP
  Future<void> sendEmailOTP(String email) async {
    if (_firestore == null) throw Exception('Service unavailable');

    try {
      // Generate 6-digit OTP
      final String otp = _generateOTP();

      // Store OTP in Firestore with expiry
      await _firestore!.collection('email_otps').doc(email).set({
        'otp': otp,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });

      // Send OTP via email
      final emailService = EmailService();
      final emailSent = await emailService.sendOTPEmail(
        recipientEmail: email,
        otp: otp,
      );

      if (!emailSent) {
        throw Exception(
            'Failed to send email. Please check your email configuration.');
      }

      debugPrint('✅ OTP email sent successfully to: $email');
    } catch (e) {
      debugPrint('❌ Error sending email OTP: $e');
      rethrow;
    }
  }

  /// Verify email OTP
  Future<UserCredential> verifyEmailOTP(String email, String otp) async {
    if (_firestore == null || _auth == null) {
      throw Exception('Service unavailable');
    }

    try {
      // Get OTP from Firestore
      final doc = await _firestore!.collection('email_otps').doc(email).get();

      if (!doc.exists) {
        throw Exception('Invalid or expired code');
      }

      final data = doc.data()!;
      final storedOTP = (data['otp'] as String?) ?? '';
      final expiresAtTimestamp = data['expires_at'];
      if (expiresAtTimestamp is! Timestamp) {
        throw Exception('Invalid OTP expiry data');
      }
      final expiresAt = expiresAtTimestamp.toDate();

      // Check if OTP is expired
      if (DateTime.now().isAfter(expiresAt)) {
        await _firestore!.collection('email_otps').doc(email).delete();
        throw Exception('Code expired. Please request a new one.');
      }

      // Verify OTP
      if (storedOTP != otp) {
        throw Exception('Invalid code. Please try again.');
      }

       // OTP is valid, create/sign in user
       UserCredential userCredential;
       final password = _generatePasswordFromEmail(email);

       try {
         // Try to sign in first (existing user)
         try {
           userCredential = await _auth!.signInWithEmailAndPassword(
             email: email,
             password: password,
           );
           debugPrint('✅ Sign-in successful - user created via OTP');
         } on FirebaseAuthException catch (signInError) {
           if (signInError.code == 'user-not-found') {
             // New user - create account with OTP
             debugPrint('➕ New user, creating account with OTP...');
             userCredential = await _auth!.createUserWithEmailAndPassword(
               email: email,
               password: password,
             );

             // Create user profile
             await _firestore!
                 .collection('users')
                 .doc(userCredential.user!.uid)
                 .set({
               'email': email,
               'created_at': FieldValue.serverTimestamp(),
               'profile_completed': false,
               'subscription_tier': 'free',
               'auth_method': 'email_otp',
             });
             debugPrint('✅ New account created via OTP');
           } else if (signInError.code == 'wrong-password' ||
               signInError.code == 'invalid-credential') {
             debugPrint('⚠️ This email was registered with a password');
             debugPrint(
                 '💡 User should use "Login with Email & Password" instead');

             throw Exception(
                 'This email is already registered with a password.\n\n'
                 'Please use "Login with Email & Password" option instead.\n\n'
                 'If you forgot your password, use the "Forgot Password" link.');
           } else {
             rethrow;
           }
         }
      } catch (authError) {
        debugPrint('❌ Auth error: $authError');
        rethrow;
      }

      // Delete used OTP
      await _firestore!.collection('email_otps').doc(email).delete();

      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Error verifying email OTP: $e');
      rethrow;
    }
  }

  /// Generate 6-digit OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// Generate consistent password from email (for internal use only)
  String _generatePasswordFromEmail(String email) {
    // This is a simple hash - in production use proper password generation
    return 'RW_${email.hashCode.abs()}_2024';
  }

  /// Migrate user subcollections from old UID to new UID
  /// This preserves all user data when recreating Firebase Auth account
}
