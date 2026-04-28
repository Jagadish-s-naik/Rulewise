# Manual Firestore Rules Deployment

Since Firebase CLI isn't configured, follow these steps to deploy rules manually:

## 📋 Steps

### 1. Open Firebase Console
Go to: https://console.firebase.google.com

### 2. Select Your Project
Click on your RuleWise project

### 3. Navigate to Firestore Rules
- Click **Firestore Database** in left sidebar
- Click **Rules** tab at the top

### 4. Copy Rules
Open the file: `c:\xampp\htdocs\RuleWise\firestore.rules`

Copy ALL contents (starting from `rules_version = '2';`)

### 5. Paste and Publish
- Paste the rules into the Firebase Console editor
- Click **Publish** button
- Wait for confirmation message

### 6. Verify
You should see a success message: "Rules published successfully"

---

## 🔧 Alternative: Configure Firebase CLI (Optional)

If you want to use CLI in future:

```bash
# Initialize Firebase
firebase init

# Select:
# - Firestore
# - Use existing project
# - Accept default firestore.rules path
# - Accept default firestore.indexes.json path

# Then deploy
firebase deploy --only firestore:rules
```

---

## ✅ After Deploying Rules

Run the app again:
```bash
flutter run -d windows
```

The permission errors should be resolved!
