import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_plan.dart';
import 'remote_config_service.dart';

class SubscriptionService extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  RemoteConfigService? _remoteConfigService;

  SubscriptionService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      debugPrint('✅ SubscriptionService: Firebase instances obtained');
      debugPrint(
        '🔐 Current user: ${_auth?.currentUser?.email ?? "NOT LOGGED IN"}',
      );
    } catch (e) {
      debugPrint('❌ SubscriptionService: Firebase not ready - $e');
    }
  }

  SubscriptionTier _currentTier = SubscriptionTier.free;
  int _aiQueriesUsedThisWeek = 0;

  // Trial State
  bool _isTrialActive = false;
  DateTime? _trialEndsAt;
  bool _hasUsedTrial = false;

  // 🧪 NOTE: Set testingMode = true only during development
  // When true, all premium features are unlocked and no real payments are processed
  // Set to FALSE before production release
  static const bool testingMode = false; // ✅ DISABLED FOR PRODUCTION

  // 🧪 testing: Override tier for testing (only works when testingMode = true)
  static const SubscriptionTier testingTier = SubscriptionTier.enterprise;

  SubscriptionTier get currentTier => testingMode ? testingTier : _currentTier;
  int get aiQueriesUsedThisWeek => _aiQueriesUsedThisWeek;

  int get currentQueryLimit {
    switch (currentTier) {
      case SubscriptionTier.free:
        return _remoteConfigService?.freeTierQueryLimit ?? currentTier.aiQueriesPerWeek;
      case SubscriptionTier.protection:
        return _remoteConfigService?.basicTierQueryLimit ?? currentTier.aiQueriesPerWeek;
      default:
        return currentTier.aiQueriesPerWeek;
    }
  }

  int get aiQueriesRemaining => currentQueryLimit - _aiQueriesUsedThisWeek;

  void updateRemoteConfig(RemoteConfigService? config) {
    _remoteConfigService = config;
    notifyListeners();
  }

  bool get isTrialActive => testingMode ? true : _isTrialActive;
  bool get hasUsedTrial => _hasUsedTrial;
  DateTime? get trialEndsAt => _trialEndsAt;

  Future<void> init() async {
    if (testingMode) {
      debugPrint('🧪 TESTING MODE ENABLED - All premium features unlocked');
      debugPrint('🧪 Testing as: ${testingTier.name}');
      return;
    }

    debugPrint('🔄 Initializing SubscriptionService...');
    await _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final userId = _auth?.currentUser?.uid;

    debugPrint('📊 Loading subscription for user: ${userId ?? "NULL"}');

    if (userId == null) {
      debugPrint('⚠️ No user logged in - cannot load subscription');
      return;
    }

    if (_firestore == null) {
      debugPrint('❌ Firestore is null - cannot load subscription');
      return;
    }

    try {
      debugPrint('🔍 Fetching user document from Firestore...');
      final doc = await _firestore!.collection('users').doc(userId).get();

      if (!doc.exists) {
        debugPrint('⚠️ User document does not exist in Firestore');
        return;
      }

      final data = doc.data()!;
      final tierString = data['subscription_tier'] ?? 'free';
      debugPrint('📄 Firestore data: subscription_tier=$tierString');

      _currentTier = SubscriptionTier.values.firstWhere(
        (tier) => tier.toString().split('.').last == tierString,
        orElse: () => SubscriptionTier.free,
      );

      debugPrint('✅ Loaded tier: $_currentTier');

      _aiQueriesUsedThisWeek = data['ai_queries_this_week'] ?? 0;

      // Trial Logic
      _hasUsedTrial = data['has_used_trial'] ?? false;
      if (data['trial_ends_at'] != null) {
        final trialEnd = (data['trial_ends_at'] as Timestamp).toDate();
        if (trialEnd.isAfter(DateTime.now())) {
          _isTrialActive = true;
          _trialEndsAt = trialEnd;
        } else {
          _isTrialActive = false; // Expired
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading subscription: $e');
    }
  }

  /// Check if user has access to a specific feature
  bool canAccess(String feature) {
    if (testingMode || _isTrialActive) {
      return true; // 🧪 All features unlocked in testing mode or active trial
    }

    return currentTier.hasFeature(feature);
  }

  /// Check if user can make an AI query
  bool canUseAI() {
    if (testingMode) {
      return true; // 🧪 Unlimited AI in testing mode
    }

    return aiQueriesRemaining > 0;
  }

  /// Increment AI query usage
  Future<void> incrementAIUsage() async {
    if (testingMode) {
      debugPrint('🧪 AI query used (not tracked in testing mode)');
      return; // 🧪 Don't track in testing mode
    }

    final userId = _auth?.currentUser?.uid;
    if (userId == null || _firestore == null) return;

    _aiQueriesUsedThisWeek++;
    notifyListeners();

    try {
      await _firestore!.collection('users').doc(userId).update({
        'ai_queries_this_week': _aiQueriesUsedThisWeek,
      });
    } catch (e) {
      debugPrint('Error updating AI usage: $e');
    }
  }

  /// Upgrade subscription tier
  Future<void> upgradeTier(SubscriptionTier newTier) async {
    if (testingMode) {
      debugPrint('🧪 Cannot upgrade in testing mode');
      return;
    }

    final userId = _auth?.currentUser?.uid;
    if (userId == null || _firestore == null) return;

    try {
      await _firestore!.collection('users').doc(userId).update({
        'subscription_tier': newTier.toString().split('.').last,
        'subscription_updated_at': FieldValue.serverTimestamp(),
      });

      _currentTier = newTier;
      notifyListeners();
    } catch (e) {
      debugPrint('Error upgrading subscription: $e');
      rethrow;
    }
  }

  /// Process a premium upgrade with transaction details
  Future<void> upgradeToPremium({
    required String transactionId,
    required double amount,
    required String planType,
  }) async {
    final userId = _auth?.currentUser?.uid;
    if (userId == null || _firestore == null) return;

    try {
      // 1. Record the transaction
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('payments')
          .add({
            'transaction_id': transactionId,
            'amount': amount,
            'plan_type': planType,
            'status': 'success',
            'timestamp': FieldValue.serverTimestamp(),
            'provider': 'razorpay',
          });

      // 2. Determine new tier based on plan name
      SubscriptionTier newTier;
      final planLower = planType.toLowerCase();

      if (planLower.contains('enterprise')) {
        newTier = SubscriptionTier.enterprise;
      } else if (planLower.contains('businessshield') ||
          planLower.contains('business')) {
        newTier = SubscriptionTier.businessShield;
      } else if (planLower.contains('protection')) {
        newTier = SubscriptionTier.protection;
      } else {
        // Default to businessShield for any premium payment
        newTier = SubscriptionTier.businessShield;
      }

      // 3. Update User Profile in Firebase
      await _firestore!.collection('users').doc(userId).set({
        'subscription_tier': newTier.toString().split('.').last,
        'subscription_updated_at': FieldValue.serverTimestamp(),
        'is_premium': true,
      }, SetOptions(merge: true));
      debugPrint(
        '✅ Firebase updated with tier: ${newTier.toString().split('.').last}',
      );

      // 4. Update local state
      final oldTier = _currentTier;
      _currentTier = newTier;
      debugPrint('🔄 Local tier updated: $oldTier → $newTier');

      // 5. Notify listeners immediately
      notifyListeners();
      debugPrint('📢 Listeners notified');

      // 6. CRITICAL: Reload from Firebase to ensure sync
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadSubscription();
      debugPrint('🔄 Reloaded subscription from Firebase');

      debugPrint('✅ User upgraded to $newTier (from plan: $planType)');
    } catch (e) {
      debugPrint('❌ Error processing upgrade: $e');
      rethrow;
    }
  }

  /// Reset weekly AI query count (called by cron job)
  Future<void> resetWeeklyAIQueries() async {
    if (testingMode) return;

    final userId = _auth?.currentUser?.uid;
    if (userId == null || _firestore == null) return;

    _aiQueriesUsedThisWeek = 0;
    notifyListeners();

    try {
      await _firestore!.collection('users').doc(userId).update({
        'ai_queries_this_week': 0,
      });
    } catch (e) {
      debugPrint('Error resetting AI queries: $e');
    }
  }

  /// Activate 7-Day Free Trial
  Future<void> activateTrial() async {
    final userId = _auth?.currentUser?.uid;
    if (userId == null || _firestore == null) return;

    if (_hasUsedTrial) {
      throw Exception('Trial already used');
    }

    try {
      final trialEnd = DateTime.now().add(const Duration(days: 7));

      await _firestore!.collection('users').doc(userId).update({
        'has_used_trial': true,
        'trial_started_at': FieldValue.serverTimestamp(),
        'trial_ends_at': Timestamp.fromDate(trialEnd),
      });

      _isTrialActive = true;
      _hasUsedTrial = true;
      _trialEndsAt = trialEnd;
      // Temporarily set tier to Business Shield for local logic if needed,
      // but isTrialActive flag should override most checks.

      notifyListeners();
    } catch (e) {
      debugPrint('Error activating trial: $e');
      rethrow;
    }
  }
}
