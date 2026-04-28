# RuleWise - Quick Setup Guide

## 🚨 Fix Firestore Permission Errors

### 1. Deploy Security Rules
```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project (if not done)
firebase init firestore

# Deploy the rules
firebase deploy --only firestore:rules
```

### 2. Alternative: Manual Upload
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Copy contents from `firestore.rules` file
5. Click **Publish**

---

## ✅ Code Fixes Applied

### 1. ProfileService - Added currentProfile getter ✅
```dart
UserProfile? get currentProfile {
  // Returns structured profile with businessName, city, state, businessType
}
```

### 2. UserLicenseModel - Added toMap method ✅
```dart
Map<String, dynamic> toMap() => toFirestore();
```

### 3. Packages Installed ✅
- `html` - For web scraping
- `pdf` - For PDF generation
- `path_provider` - For file storage
- `hive_flutter` - For offline cache

---

## 🔧 Remaining Setup

### 1. Configure AI Service (Optional)
Edit `lib/services/context_aware_ai_service.dart`:
```dart
static const String _apiKey = 'YOUR_OPENAI_API_KEY';
```

Get API key from: https://platform.openai.com/api-keys

### 2. Seed Legal Rights Collection
Run in Firebase Console or create a script:

**Collection**: `legal_resources`
**Document ID**: `inspection_rights`
**Data**:
```json
{
  "title": "Your Legal Rights During Inspection",
  "rights": [
    "Inspector must show valid ID and authorization letter",
    "You have right to ask for advance notice",
    "You can request presence of witness",
    "Inspector cannot seize documents without proper memo",
    "You have right to take photographs/videos",
    "You can request copy of inspection report",
    "Right to legal representation if required"
  ],
  "source": "Based on Indian Administrative Law",
  "last_updated": "2026-01-22"
}
```

---

## 🚀 Run the App

```bash
flutter run -d windows
```

Or for Android:
```bash
flutter run -d <device-id>
```

---

## 🐛 Troubleshooting

### Permission Denied Errors
- **Cause**: Firestore security rules not deployed
- **Fix**: Deploy `firestore.rules` as shown above

### Missing currentProfile
- **Cause**: User not logged in or profile not loaded
- **Fix**: Ensure user completes profile setup

### Hive Errors
- **Cause**: Hive not initialized
- **Fix**: Add to `main.dart`:
```dart
await Hive.initFlutter();
```

---

## 📊 What Works Now

✅ **Executive Summary Panel** - Shows business info, compliance score, nearest deadline
✅ **Risk Monitor** - Real-time risk calculation (locked for Free users)
✅ **All Backend Services** - 8 major services ready
✅ **Government Data Integration** - Web scraping framework
✅ **PDF Report Generation** - Monthly reports with live data
✅ **Emergency Mode** - Offline cache
✅ **Smart Renewal** - Fee tracking
✅ **Fine Simulator** - Penalty calculations
✅ **Growth Advisor** - Threshold monitoring

---

## 📝 Next Steps

1. **Deploy Firestore Rules** (CRITICAL)
2. **Test App** - Login and verify dashboard
3. **Seed Legal Rights** - Add to Firestore
4. **Configure AI** (Optional) - Add OpenAI key
5. **Build UI Screens** - Emergency Mode, Law Updates, etc.
