const admin = require('firebase-admin');
const serviceAccount = require('./rulewise-4ec59-firebase-adminsdk.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupUserLicenses() {
    try {
        console.log('🧹 Cleaning up user licenses with old schema...');

        // Get all users
        const usersSnapshot = await db.collection('users').get();

        for (const userDoc of usersSnapshot.docs) {
            const userId = userDoc.id;
            console.log(`Checking user: ${userId}`);

            // Get all user_licenses for this user
            const licensesSnapshot = await db
                .collection('users')
                .doc(userId)
                .collection('user_licenses')
                .get();

            if (licensesSnapshot.empty) {
                console.log(`  No licenses found for user ${userId}`);
                continue;
            }

            console.log(`  Found ${licensesSnapshot.size} licenses, deleting...`);

            // Delete all licenses
            const batch = db.batch();
            licensesSnapshot.docs.forEach(doc => {
                batch.delete(doc.ref);
            });
            await batch.commit();

            console.log(`  ✅ Deleted ${licensesSnapshot.size} licenses for user ${userId}`);
        }

        console.log('✅ Cleanup complete!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during cleanup:', error);
        process.exit(1);
    }
}

cleanupUserLicenses();
