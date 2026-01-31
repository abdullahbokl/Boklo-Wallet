// One-time migration trigger script
// Run with: npx ts-node trigger-migration.ts

import * as admin from 'firebase-admin';

// Initialize with Application Default Credentials
admin.initializeApp({
  projectId: 'boklo-wallet'
});

const db = admin.firestore();
const jobId = `migrate_identifiers_${Date.now()}`;

async function triggerMigration() {
  try {
    await db.collection('admin_jobs').doc(jobId).set({
      type: 'MIGRATE_WALLET_IDENTIFIERS',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'PENDING'
    });
    
    console.log('✅ Migration job created:', jobId);
    console.log('📋 Check Firestore admin_jobs collection for status');
    console.log('👉 The onAdminJobCreated trigger will process it automatically');
    
    // Wait and check status
    console.log('\n⏳ Waiting 10 seconds to check status...');
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    const doc = await db.collection('admin_jobs').doc(jobId).get();
    console.log('📊 Job status:', doc.data());
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

triggerMigration();
