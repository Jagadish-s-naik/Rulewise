# Automated Firestore Seeding - Quick Start

## ✅ Best Method: Node.js Script (One Command!)

### Step 1: Download Service Account Key

1. Go to: https://console.firebase.google.com/project/rulewise-4ec59/settings/serviceaccounts/adminsdk
2. Click "**Generate new private key**"
3. Save the JSON file as: `rulewise-4ec59-firebase-adminsdk.json`
4. Move it to: `c:\xampp\htdocs\RuleWise\`

### Step 2: Install Dependencies

```bash
cd c:\xampp\htdocs\RuleWise
npm install firebase-admin
```

### Step 3: Run Seeding Script

```bash
node seed_firestore.js
```

**That's it!** The script will:
- ✅ Add 5 law updates
- ✅ Add 5 penalties
- ✅ Add legal rights
- ✅ Add inspection checklist

**Time**: 30 seconds total

---

## What Happens

```
🌱 Starting Firestore data seeding...

📜 Seeding law updates...
  ✓ FSSAI License Fee Revision 2024
  ✓ GST Rate Changes for Restaurants
  ✓ Shop Act Amendment - Karnataka
  ✓ Fire Safety NOC Mandatory
  ✓ Trade License Renewal Extended

⚖️  Seeding penalties...
  ✓ Operating without valid FSSAI license
  ✓ Operating without Trade License
  ✓ Non-payment of Professional Tax
  ✓ Expired Fire Safety NOC
  ✓ Non-compliance with Labour Laws

📚 Seeding legal resources...
  ✓ Legal rights
  ✓ Inspection checklist

✅ All data seeded successfully!
```

---

## Troubleshooting

### Error: "Cannot find module 'firebase-admin'"
**Solution**: Run `npm install firebase-admin`

### Error: "Service account key not found"
**Solution**: Download the service account key from Firebase Console and save it in the project root

### Error: "Permission denied"
**Solution**: Check Firestore security rules allow writes

---

## After Seeding

1. **Test in app**: Open Law Change Radar and Emergency Mode
2. **Verify data**: Check Firebase Console to see the data
3. **Continue development**: Data is now populated!

---

## Files Created

- `seed_firestore.js` - The seeding script
- `firestore_seed_data.json` - Raw data (for reference)
- `rulewise-4ec59-firebase-adminsdk.json` - Service account key (you need to download this)

---

## Next Steps

After seeding, I'll fix:
1. PDF storage (not saving to device)
2. Services integration (Report/Renewal/AI)
3. Any other bugs
