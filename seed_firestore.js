const admin = require('firebase-admin');
const serviceAccount = require('./rulewise-4ec59-firebase-adminsdk.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seedFirestore() {
  console.log('🌱 Starting Firestore data seeding...\n');

  try {
    // Seed law updates
    console.log('📜 Seeding law updates...');
    await seedLawUpdates();
    
    // Seed penalties
    console.log('\n⚖️  Seeding penalties...');
    await seedPenalties();
    
    // Seed legal resources
    console.log('\n📚 Seeding legal resources...');
    await seedLegalResources();
    
    console.log('\n✅ All data seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error seeding data:', error);
    process.exit(1);
  }
}

async function seedLawUpdates() {
  const updates = [
    {
      title: 'FSSAI License Fee Revision 2024',
      description: 'Ministry of Health revises FSSAI license fees for all categories. New fee structure effective from April 1, 2024. Basic license fee increased from ₹100 to ₹200 per year.',
      published_date: admin.firestore.Timestamp.now(),
      effective_date: admin.firestore.Timestamp.fromDate(new Date('2024-04-01')),
      states: ['All India'],
      business_types: ['food_beverage', 'retail_shop'],
      impact: 'high',
      source_url: 'https://www.fssai.gov.in/notifications'
    },
    {
      title: 'GST Rate Changes for Restaurants',
      description: 'GST Council revises tax rates for restaurant services. AC restaurants now at 18%, non-AC at 12%. Effective from February 2024.',
      published_date: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)),
      effective_date: admin.firestore.Timestamp.fromDate(new Date('2024-02-01')),
      states: ['All India'],
      business_types: ['food_beverage'],
      impact: 'high',
      source_url: 'https://www.gst.gov.in'
    },
    {
      title: 'Shop Act Amendment - Karnataka',
      description: 'Karnataka amends Shop and Establishment Act. All shops must now register online. Penalty for non-compliance increased to ₹10,000.',
      published_date: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)),
      effective_date: admin.firestore.Timestamp.fromDate(new Date('2024-03-01')),
      states: ['Karnataka'],
      business_types: ['retail_shop', 'service_provider'],
      impact: 'medium',
      source_url: 'https://labour.karnataka.gov.in'
    },
    {
      title: 'Fire Safety NOC Mandatory',
      description: 'Maharashtra Fire Department makes Fire Safety NOC mandatory for all commercial establishments above 500 sq ft. Deadline: June 30, 2024.',
      published_date: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 15 * 24 * 60 * 60 * 1000)),
      effective_date: admin.firestore.Timestamp.fromDate(new Date('2024-06-30')),
      states: ['Maharashtra'],
      business_types: ['retail_shop', 'food_beverage', 'service_provider'],
      impact: 'high',
      source_url: 'https://mahafireservice.gov.in'
    },
    {
      title: 'Trade License Renewal Extended',
      description: 'Delhi Municipal Corporation extends trade license renewal period by 3 months. New deadline: March 31, 2024. No late fees till then.',
      published_date: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)),
      effective_date: admin.firestore.Timestamp.fromDate(new Date('2024-03-31')),
      states: ['Delhi'],
      business_types: ['retail_shop', 'food_beverage', 'service_provider'],
      impact: 'medium',
      source_url: 'https://mcdonline.gov.in'
    }
  ];

  for (const update of updates) {
    await db.collection('law_updates').add(update);
    console.log(`  ✓ ${update.title}`);
  }
}

async function seedPenalties() {
  const penalties = [
    {
      violation: 'Operating without valid FSSAI license',
      penalty: '₹25,000 fine or imprisonment up to 6 months',
      law_reference: 'Food Safety and Standards Act 2006, Section 59'
    },
    {
      violation: 'Operating without Trade License',
      penalty: '₹10,000 fine and possible business closure',
      law_reference: 'Shop and Establishment Act, Section 7'
    },
    {
      violation: 'Non-payment of Professional Tax',
      penalty: '₹5,000 fine plus 2% interest per month on dues',
      law_reference: 'Professional Tax Act, Section 12'
    },
    {
      violation: 'Expired Fire Safety NOC',
      penalty: '₹50,000 fine and immediate closure order',
      law_reference: 'Fire Safety Act, Section 15'
    },
    {
      violation: 'Non-compliance with Labour Laws',
      penalty: '₹20,000 fine per violation',
      law_reference: 'Labour Welfare Act, Section 25'
    }
  ];

  for (const penalty of penalties) {
    await db.collection('penalty_reference').add(penalty);
    console.log(`  ✓ ${penalty.violation}`);
  }
}

async function seedLegalResources() {
  // Legal Rights
  await db.collection('legal_resources').doc('legal_rights').set({
    title: 'Your Legal Rights During Inspection',
    source: 'Constitution of India, Article 19 & 21',
    rights: [
      'Inspector must show valid ID and authorization letter',
      'You have right to ask for inspection notice (except emergency)',
      'You can request presence of witness during inspection',
      'Inspector cannot seize documents without proper procedure',
      'You have right to take photographs of inspection process',
      'Inspector must provide inspection report copy',
      'You can refuse entry if inspector has no valid authorization',
      'You have right to legal representation during inspection'
    ]
  });
  console.log('  ✓ Legal rights');

  // Inspection Checklist
  await db.collection('legal_resources').doc('inspection_checklist').set({
    title: 'Quick Inspection Checklist',
    categories: [
      {
        name: 'Documentation',
        items: [
          'Original license certificates (FSSAI, Trade, etc.)',
          'Renewal receipts and payment proofs',
          'Employee health certificates',
          'Fire safety NOC',
          'Pollution clearance certificate'
        ]
      },
      {
        name: 'Hygiene & Safety',
        items: [
          'Clean and sanitized premises',
          'Proper waste disposal system',
          'Fire extinguishers in working condition',
          'First aid kit available'
        ]
      },
      {
        name: 'Employee Records',
        items: [
          'Employee attendance register',
          'Salary payment records',
          'EPF and ESI compliance documents'
        ]
      }
    ]
  });
  console.log('  ✓ Inspection checklist');
}

// Run the seeding
seedFirestore();
