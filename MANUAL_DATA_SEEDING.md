# Manual Firestore Data Seeding Guide

Since the Dart seeding script has compilation issues, use this guide to manually seed data via Firebase Console.

## Step 1: Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/rulewise-4ec59/firestore)
2. Navigate to Firestore Database
3. Click on "Start collection" or select existing collection

---

## Step 2: Seed `law_updates` Collection

**Collection Name**: `law_updates`

### Document 1
```json
{
  "title": "FSSAI License Fee Revision 2024",
  "description": "Ministry of Health revises FSSAI license fees for all categories. New fee structure effective from April 1, 2024. Basic license fee increased from ₹100 to ₹200 per year.",
  "published_date": "2024-01-22T00:00:00Z",
  "effective_date": "2024-04-01T00:00:00Z",
  "states": ["All India"],
  "business_types": ["food_beverage", "retail_shop"],
  "impact": "high",
  "source_url": "https://www.fssai.gov.in/notifications"
}
```

### Document 2
```json
{
  "title": "GST Rate Changes for Restaurants",
  "description": "GST Council revises tax rates for restaurant services. AC restaurants now at 18%, non-AC at 12%. Effective from February 2024.",
  "published_date": "2024-01-17T00:00:00Z",
  "effective_date": "2024-02-01T00:00:00Z",
  "states": ["All India"],
  "business_types": ["food_beverage"],
  "impact": "high",
  "source_url": "https://www.gst.gov.in"
}
```

### Document 3
```json
{
  "title": "Shop and Establishment Act Amendment - Karnataka",
  "description": "Karnataka amends Shop and Establishment Act. All shops must now register online. Penalty for non-compliance increased to ₹10,000.",
  "published_date": "2024-01-12T00:00:00Z",
  "effective_date": "2024-03-01T00:00:00Z",
  "states": ["Karnataka"],
  "business_types": ["retail_shop", "service_provider"],
  "impact": "medium",
  "source_url": "https://labour.karnataka.gov.in"
}
```

### Document 4
```json
{
  "title": "Fire Safety NOC Mandatory for All Commercial Establishments",
  "description": "Maharashtra Fire Department makes Fire Safety NOC mandatory for all commercial establishments above 500 sq ft. Deadline: June 30, 2024.",
  "published_date": "2024-01-07T00:00:00Z",
  "effective_date": "2024-06-30T00:00:00Z",
  "states": ["Maharashtra"],
  "business_types": ["retail_shop", "food_beverage", "service_provider"],
  "impact": "high",
  "source_url": "https://mahafireservice.gov.in"
}
```

### Document 5
```json
{
  "title": "Trade License Renewal Period Extended",
  "description": "Delhi Municipal Corporation extends trade license renewal period by 3 months. New deadline: March 31, 2024. No late fees till then.",
  "published_date": "2024-01-19T00:00:00Z",
  "effective_date": "2024-03-31T00:00:00Z",
  "states": ["Delhi"],
  "business_types": ["retail_shop", "food_beverage", "service_provider"],
  "impact": "medium",
  "source_url": "https://mcdonline.gov.in"
}
```

**Add 5-10 more similar documents for variety**

---

## Step 3: Seed `penalty_reference` Collection

**Collection Name**: `penalty_reference`

### Document 1
```json
{
  "violation": "Operating without valid FSSAI license",
  "penalty": "₹25,000 fine or imprisonment up to 6 months",
  "law_reference": "Food Safety and Standards Act 2006, Section 59"
}
```

### Document 2
```json
{
  "violation": "Operating without Trade License",
  "penalty": "₹10,000 fine and possible business closure",
  "law_reference": "Shop and Establishment Act, Section 7"
}
```

### Document 3
```json
{
  "violation": "Non-payment of Professional Tax",
  "penalty": "₹5,000 fine plus 2% interest per month on dues",
  "law_reference": "Professional Tax Act, Section 12"
}
```

### Document 4
```json
{
  "violation": "Expired Fire Safety NOC",
  "penalty": "₹50,000 fine and immediate closure order",
  "law_reference": "Fire Safety Act, Section 15"
}
```

### Document 5
```json
{
  "violation": "Non-compliance with Labour Laws",
  "penalty": "₹20,000 fine per violation",
  "law_reference": "Labour Welfare Act, Section 25"
}
```

**Add 5 more penalty documents**

---

## Step 4: Seed `legal_resources` Collection

**Collection Name**: `legal_resources`

### Document ID: `legal_rights`
```json
{
  "title": "Your Legal Rights During Inspection",
  "source": "Constitution of India, Article 19 & 21",
  "rights": [
    "Inspector must show valid ID and authorization letter",
    "You have right to ask for inspection notice (except emergency)",
    "You can request presence of witness during inspection",
    "Inspector cannot seize documents without proper procedure",
    "You have right to take photographs of inspection process",
    "Inspector must provide inspection report copy",
    "You can refuse entry if inspector has no valid authorization",
    "You have right to legal representation during inspection"
  ]
}
```

### Document ID: `inspection_checklist`
```json
{
  "title": "Quick Inspection Checklist",
  "categories": [
    {
      "name": "Documentation",
      "items": [
        "Original license certificates (FSSAI, Trade, etc.)",
        "Renewal receipts and payment proofs",
        "Employee health certificates",
        "Fire safety NOC",
        "Pollution clearance certificate",
        "GST registration certificate",
        "Professional tax enrollment"
      ]
    },
    {
      "name": "Hygiene & Safety",
      "items": [
        "Clean and sanitized premises",
        "Proper waste disposal system",
        "Fire extinguishers in working condition",
        "First aid kit available",
        "Adequate lighting and ventilation",
        "Pest control records"
      ]
    },
    {
      "name": "Employee Records",
      "items": [
        "Employee attendance register",
        "Salary payment records",
        "EPF and ESI compliance documents",
        "Leave records",
        "Appointment letters"
      ]
    },
    {
      "name": "Food Safety (if applicable)",
      "items": [
        "Food handler medical certificates",
        "Temperature logs for refrigeration",
        "Supplier invoices and bills",
        "Water quality test reports",
        "Cleaning and sanitization logs"
      ]
    },
    {
      "name": "Display Requirements",
      "items": [
        "License numbers displayed at entrance",
        "Price list displayed prominently",
        "No smoking signage",
        "Emergency exit signs",
        "Business hours displayed"
      ]
    }
  ]
}
```

---

## Quick Copy-Paste Instructions

1. **For Timestamps in Firebase Console**:
   - Use "timestamp" type
   - Click "Set to current time" for `published_date`
   - Manually set future dates for `effective_date`

2. **For Arrays**:
   - Click "Add field" → Select "array" type
   - Add each item individually

3. **For Nested Objects** (like categories in checklist):
   - Click "Add field" → Select "map" type
   - Add nested fields inside

---

## Verification

After seeding, verify in the app:
1. Open Law Change Radar → Should show 5+ updates
2. Open Emergency Mode → Should show all 3 sections populated
3. Check that data displays correctly with proper formatting

---

## Alternative: Import JSON (Faster)

If you have Firebase CLI installed:

```bash
# Export this data to JSON file
# Then import using:
firebase firestore:import ./firestore-data --project rulewise-4ec59
```

But manual entry via console is simpler for small datasets.
