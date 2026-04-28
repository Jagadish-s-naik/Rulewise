# Premium Features Testing Guide

## 🧪 Testing Mode (Current Setup)

### How It Works
The app is currently in **TESTING MODE** which unlocks ALL premium features for testing without requiring payment.

### Configuration
In `lib/services/subscription_service.dart`:
```dart
// Line 13-14
static const bool TESTING_MODE = true;  // ✅ Testing enabled
static const SubscriptionTier TESTING_TIER = SubscriptionTier.enterprise;
```

### What's Unlocked in Testing Mode
✅ **All Premium Features**:
- Emergency Mode (offline inspector guide)
- Law Change Radar (regulation tracking)
- Fine Simulator (penalty calculator)
- Timeline View (compliance journey)
- Growth Advisor (business scaling)
- Risk Monitor (real-time risk)
- Unlimited AI queries
- Monthly PDF reports

### Testing Steps
1. **Run the app**: `flutter run -d chrome`
2. **Login** with phone authentication
3. **Access Dashboard** → Open menu (☰)
4. **Test Premium Features**:
   - Tap "Emergency Mode" → Should open (not locked)
   - Tap "Law Change Radar" → Should open (not locked)
   - Tap "Fine Simulator" → Should open (not locked)
   - Tap "Timeline View" → Should open (not locked)
   - Tap "Growth Advisor" → Should open (not locked)
   - Check Risk Monitor → Should be visible (not blurred)

### Console Output
You'll see testing indicators:
```
🧪 TESTING MODE ENABLED - All premium features unlocked
🧪 Testing as: Enterprise
🧪 AI query used (not tracked in testing mode)
```

---

## 🚀 Production Mode (Subscription Enforcement)

### Switch to Production
When ready to enforce subscriptions, edit `lib/services/subscription_service.dart`:

```dart
// Line 13
static const bool TESTING_MODE = false;  // ❌ Testing disabled
```

**That's it!** The app will now enforce subscription tiers.

---

## 📊 Subscription Tiers & Features

### Free Tier (₹0/month)
- ✅ View compliance requirements
- ❌ All premium features locked
- 🤖 1 AI query per week

### Protection Tier (₹99/month)
- ✅ Risk Monitor
- ✅ Guided License Acquisition
- ✅ Renewal Automation
- ✅ Law Change Radar
- ✅ Fine Simulator
- ❌ Emergency Mode (locked)
- ❌ Timeline View (locked)
- ❌ Growth Advisor (locked)
- 🤖 5 AI queries per week

### Business Shield Tier (₹399/month)
- ✅ **ALL FEATURES UNLOCKED**
- ✅ Emergency Mode
- ✅ Timeline View
- ✅ Growth Advisor
- ✅ Monthly PDF Reports
- 🤖 Unlimited AI queries

### Enterprise Tier (₹999/month)
- ✅ **ALL FEATURES UNLOCKED**
- ✅ Multi-business support
- ✅ Priority support
- 🤖 Unlimited AI queries

---

## 🔧 Manual Subscription Assignment (Testing)

### Option 1: Via Firestore Console
1. Go to Firebase Console → Firestore
2. Navigate to `users/{user_id}`
3. Edit document, set:
   ```
   subscription_tier: "business_shield"
   ```
4. Restart app

### Option 2: Via Code (Temporary)
Add this to your test user creation:
```dart
await FirebaseFirestore.instance.collection('users').doc(userId).update({
  'subscription_tier': 'business_shield',  // or 'protection', 'enterprise'
});
```

---

## 🎯 Production Subscription Flow

### 1. User Sees Locked Feature
```dart
// Example: Emergency Mode screen
if (!hasAccess) {
  return _buildLockedView(); // Shows upgrade button
}
```

### 2. User Taps "Upgrade"
Navigate to subscription selection screen (to be built):
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => SubscriptionPlansScreen()),
);
```

### 3. User Selects Plan
Show Razorpay payment gateway (to be integrated):
```dart
final razorpay = Razorpay();
razorpay.open({
  'amount': 39900, // ₹399 in paise
  'name': 'RuleWise Business Shield',
  // ... payment options
});
```

### 4. Payment Success
Update Firestore:
```dart
await subscriptionService.upgradeTier(SubscriptionTier.businessShield);
```

### 5. Features Unlocked
User can now access all Business Shield features!

---

## 📝 Testing Checklist

### Before Testing
- [ ] Set `TESTING_MODE = true`
- [ ] Set `TESTING_TIER = SubscriptionTier.enterprise`
- [ ] Run app: `flutter run -d chrome`

### During Testing
- [ ] Login with phone authentication
- [ ] Verify all premium features are accessible
- [ ] Test Emergency Mode (offline guide)
- [ ] Test Law Change Radar (updates list)
- [ ] Test Fine Simulator (penalty calculator)
- [ ] Test Timeline View (license timeline)
- [ ] Test Growth Advisor (business metrics)
- [ ] Test Risk Monitor (not blurred)
- [ ] Test AI assistant (unlimited queries)

### After Testing (Production)
- [ ] Set `TESTING_MODE = false`
- [ ] Test Free tier (features locked)
- [ ] Test Protection tier (some features unlocked)
- [ ] Test Business Shield tier (all features unlocked)
- [ ] Integrate payment gateway (Razorpay)
- [ ] Test subscription upgrade flow
- [ ] Test AI query limits

---

## 🔐 Security Notes

### Testing Mode Safety
- ✅ Safe for development/testing
- ❌ **NEVER deploy to production with TESTING_MODE = true**
- ⚠️ Add reminder in code comments
- 🔒 Consider environment variable for extra safety

### Production Checklist
Before deploying to production:
```dart
// ❌ CRITICAL: Set to false before production deployment!
static const bool TESTING_MODE = false;
```

Add this check in your CI/CD:
```bash
# Fail build if TESTING_MODE is true
grep -q "TESTING_MODE = true" lib/services/subscription_service.dart && exit 1
```

---

## 🎨 UI Indicators

### Testing Mode Badge (Optional)
Add visual indicator when testing:
```dart
if (SubscriptionService.TESTING_MODE) {
  return Banner(
    message: 'TESTING MODE',
    location: BannerLocation.topEnd,
    child: child,
  );
}
```

### Subscription Badge
Show current tier in UI:
```dart
Consumer<SubscriptionService>(
  builder: (context, service, _) {
    return Chip(
      label: Text(service.currentTier.name),
      backgroundColor: Colors.gold,
    );
  },
)
```

---

## 📞 Support

### Common Issues

**Q: Features still locked in testing mode?**
A: Ensure `TESTING_MODE = true` and restart app with hot restart (not hot reload)

**Q: How to test different tiers?**
A: Change `TESTING_TIER` to desired tier and restart app

**Q: AI queries not working?**
A: Check console for `🧪 AI query used` message. In testing mode, queries are unlimited.

**Q: Ready for production?**
A: Set `TESTING_MODE = false`, integrate Razorpay, test subscription flow

---

## ✅ Quick Reference

| Mode | TESTING_MODE | Features | AI Queries |
|------|--------------|----------|------------|
| **Testing** | `true` | All unlocked | Unlimited |
| **Production** | `false` | Tier-based | Tier-based |

**Current Status**: 🧪 TESTING MODE ENABLED

**To Switch**: Edit line 13 in `subscription_service.dart`
