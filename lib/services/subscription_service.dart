import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_plan.dart';
import 'remote_config_service.dart';

class SubscriptionService extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  RemoteConfigService? _remoteConfigService;

  SubscriptionService({FirebaseFirestore? firestore, FirebaseAuth? auth, RemoteConfigService? remoteConfigService}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
      _auth = auth ?? FirebaseAuth.instance;
      _remoteConfigService = remoteConfigService;
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
    // 1. Determine new tier from plan name FIRST
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
      newTier = SubscriptionTier.businessShield;
    }

    // 2. Update local state IMMEDIATELY so the UI reflects the change right away
    final oldTier = _currentTier;
    _currentTier = newTier;
    debugPrint('🔄 [SubscriptionService] Local tier updated: $oldTier → $newTier');
    notifyListeners();
    debugPrint('📢 [SubscriptionService] Listeners notified of immediate upgrade');

    // 3. Persist to Firestore (best-effort — UI is already updated)
    final userId = _auth?.currentUser?.uid;
    if (userId == null || _firestore == null) {
      debugPrint('⚠️ [SubscriptionService] No user/Firestore — local state updated but not persisted');
      return;
    }

    try {
      debugPrint('📡 [SubscriptionService] Persisting upgrade to Firestore...');
      
      // Record the transaction
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

      // Update User Profile in Firebase
      // 1. Update Firestore
      await _firestore!.collection('users').doc(userId).set({
        'subscription_tier': newTier.toString().split('.').last,
        'subscription_updated_at': FieldValue.serverTimestamp(),
        'is_premium': true,
      }, SetOptions(merge: true));

      // 2. FORCE local state update immediately to avoid race conditions
      _currentTier = newTier;
      debugPrint('✅ [SubscriptionService] Local state forced to: $newTier');

      // 3. Notify listeners so UI updates instantly
      notifyListeners();
      
      // 4. Record transaction in separate collection
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add({
        'type': 'upgrade',
        'tier': newTier.toString().split('.').last,
        'amount': amount,
        'transaction_id': transactionId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('🏁 [SubscriptionService] Upgrade flow complete for $newTier');
      
      // Re-fetch to confirm server-side state (optional delay)
      await Future.delayed(const Duration(milliseconds: 1000));
      await _loadSubscription();
      
      // force it back to newTier one last time since we KNOW the payment was successful.
      if (_currentTier != newTier) {
        debugPrint('⚠️ [SubscriptionService] Detected stale read after reload. Re-asserting local state.');
        _currentTier = newTier;
        notifyListeners();
      }

      debugPrint('✅ [SubscriptionService] User fully upgraded to $newTier');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error persisting upgrade: $e');
      // We don't revert the UI here because the user DID pay. 
      // We'll let the next app restart or background sync handle it.
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

  /// Clear subscription data (called on logout)
  void clear() {
    _currentTier = SubscriptionTier.free;
    _aiQueriesUsedThisWeek = 0;
    _isTrialActive = false;
    _trialEndsAt = null;
    _hasUsedTrial = false;
    notifyListeners();
  }
}
