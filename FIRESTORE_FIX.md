# Fix Firestore Permission Error

## Problem
Data seeding is failing with error:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Solution

### Step 1: Deploy Updated Firestore Rules

I've updated the `firestore.rules` file to allow write access for testing. Now deploy them:

```bash
# Option 1: Using Firebase CLI
firebase deploy --only firestore:rules

# Option 2: Using Firebase Console
# 1. Go to https://console.firebase.google.com
# 2. Select your project
# 3. Go to Firestore Database → Rules
# 4. Copy the content from firestore.rules file
# 5. Click "Publish"
```

### Step 2: What Changed

**Before** (Read-only):
```javascript
match /law_updates/{updateId} {
  allow read: if isAuthenticated();
  allow write: if false; // Only backend can write
}
```

**After** (Testing mode):
```javascript
match /law_updates/{updateId} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated(); // Allow for testing/seeding
}
```

Same changes for:
- `legal_resources`
- `penalty_reference`

### Step 3: Deploy via Firebase Console (Easiest)

1. Open https://console.firebase.google.com
2. Select your RuleWise project
3. Click "Firestore Database" in left menu
4. Click "Rules" tab
5. Replace all content with the updated rules from `firestore.rules`
6. Click "Publish"

### Step 4: Test Data Seeding

After deploying rules:
1. Restart the app (hot restart: `r` in terminal)
2. Go to Dashboard → Menu → "Seed Test Data"
3. Tap "Seed Data Now"
4. Should see success message ✅

---

## Alternative: Quick Fix (Manual Data Entry)

If you can't deploy rules immediately, manually add data via Firebase Console:

### Add Law Update
1. Go to Firestore Database → Data
2. Click "+ Start collection"
3. Collection ID: `law_updates`
4. Add document with fields:
   - title: "FSSAI License Renewal Process Updated"
   - description: "New online renewal process..."
   - effective_date: (timestamp) 2026-02-01
   - source_url: "https://www.fssai.gov.in"
   - business_types: (array) ["food_beverage", "restaurant"]
   - state: "karnataka"
   - city: "bengaluru"
   - status: "approved"

### Add Legal Rights
1. Collection: `legal_resources`
2. Document ID: `inspection_rights`
3. Fields:
   - title: "Your Legal Rights During Inspection"
   - rights: (array) ["Inspector must show valid ID", "You have right to ask for notice", ...]

---

## Production Note

⚠️ **Important**: These rules allow any authenticated user to write data. This is fine for testing but should be restricted in production.

**For Production**:
```javascript
match /law_updates/{updateId} {
  allow read: if isAuthenticated();
  allow write: if request.auth.token.admin == true; // Admin only
}
```

---

## Current Status

✅ Rules file updated
⏳ Waiting for deployment
🔄 After deployment, data seeding will work

**Next**: Deploy rules using Firebase Console or CLI
