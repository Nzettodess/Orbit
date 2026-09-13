import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Load environment variables from .env.local and .env
function loadEnv() {
  const envFiles = [
    path.resolve(__dirname, '../.env.local'),
    path.resolve(__dirname, '../.env')
  ];

  for (const envFile of envFiles) {
    if (fs.existsSync(envFile)) {
      const content = fs.readFileSync(envFile, 'utf8');
      const lines = content.split(/\r?\n/);
      for (const line of lines) {
        const match = line.match(/^\s*([A-Za-z_0-9]+)\s*=\s*(.*)?\s*$/);
        if (match) {
          const key = match[1];
          let value = (match[2] || '').trim();
          if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
            value = value.slice(1, -1);
          }
          if (!process.env[key]) {
            process.env[key] = value;
          }
        }
      }
    }
  }
}

loadEnv();

const VERSION = '1.1.0';
const NOTIFICATION_TITLE = 'Orbit v1.1.0 is here! 🦦✈️';
const NOTIFICATION_BODY = 'Meet Cosmic Otter, explore smarter flight search, set custom member nicknames, and enjoy instant loading.';
const TARGET_URL = 'https://orbit-wheat-sigma.vercel.app/';

const oneSignalApiKey = process.env.ONESIGNAL_API_KEY;
const oneSignalAppId = process.env.ONESIGNAL_APP_ID || '74c32f25-a8d0-4d63-889b-9edf49ba8784';

const isSend = process.argv.includes('--send') || process.argv.includes('--execute');
const statusIndex = process.argv.indexOf('--status');
const statusId = statusIndex !== -1 && process.argv[statusIndex + 1] ? process.argv[statusIndex + 1] : null;
const userIndex = process.argv.indexOf('--user');
const targetUser = userIndex !== -1 && process.argv[userIndex + 1] ? process.argv[userIndex + 1] : null;

console.log('====================================================');
console.log(`📣 Orbit v${VERSION} Manual Announcement Broadcaster`);
console.log('====================================================');

if (statusId) {
  console.log(`Checking status for notification ID: ${statusId}...`);
  try {
    const res = await fetch(`https://onesignal.com/api/v1/notifications/${statusId}?app_id=${oneSignalAppId}`, {
      headers: { 'Authorization': `Basic ${oneSignalApiKey}` }
    });
    const data = await res.json();
    console.log('Status Report:', JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Error fetching notification status:', err);
  }
  process.exit(0);
}

console.log(`Title   : ${NOTIFICATION_TITLE}`);
console.log(`Message : ${NOTIFICATION_BODY}`);
console.log(`Target  : ${targetUser ? `Single User (${targetUser})` : 'All Subscribed Devices (Segment: "Total Subscriptions")'}`);
console.log(`URL     : ${TARGET_URL}`);
console.log(`Mode    : ${isSend ? '🚀 EXECUTE BROADCAST' : '🛡️ DRY-RUN (Pass --send to deliver)'}`);
console.log('----------------------------------------------------');

if (!oneSignalApiKey) {
  console.error('❌ Error: ONESIGNAL_API_KEY not found in environment or .env.local');
  process.exit(1);
}

async function sendBroadcast() {
  if (!isSend) {
    console.log('Dry-run complete. No notification was pushed.');
    console.log(`To send for real, run: node scripts/broadcast-announcement.mjs --send${targetUser ? ` --user ${targetUser}` : ''}`);
    return;
  }

  console.log('Sending broadcast via OneSignal REST API...');
  
  const payload = {
    app_id: oneSignalAppId,
    headings: { en: NOTIFICATION_TITLE },
    contents: { en: NOTIFICATION_BODY },
    chrome_web_icon: 'https://orbit-wheat-sigma.vercel.app/icons/Icon-512.png',
    chrome_web_badge: 'https://orbit-wheat-sigma.vercel.app/icons/Icon-192.png',
    firefox_icon: 'https://orbit-wheat-sigma.vercel.app/icons/Icon-512.png',
    data: {
      type: 'announcement',
      version: VERSION,
      click_action: 'open_announcement'
    },
    url: TARGET_URL,
    collapse_id: `announcement_${VERSION}`,
    ...(targetUser ? {
      target_channel: 'push',
      include_aliases: {
        external_id: [targetUser]
      }
    } : {
      included_segments: ['Total Subscriptions']
    })
  };

  try {
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${oneSignalApiKey}`
      },
      body: JSON.stringify(payload)
    });

    const result = await response.json();
    
    if (response.ok && result.id) {
      console.log('✅ Push notification successfully dispatched!');
      console.log(`- Notification ID : ${result.id}`);
      console.log(`- Recipients Count: ${result.recipients || 0}`);
      if (result.external_id) {
        console.log(`- External ID     : ${result.external_id}`);
      }
    } else {
      console.error('❌ OneSignal API returned an error:', result);
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ Network or execution error:', error);
    process.exit(1);
  }

  // Optional: Also populate Firestore in-app notifications if Firebase Admin is configured
  const saEnv = process.env.FIREBASE_SERVICE_ACCOUNT_WHEREABOUTS_510DB || process.env.FIREBASE_SERVICE_ACCOUNT;
  if (saEnv) {
    console.log('\nFirebase Service Account detected. Syncing Firestore in-app notifications...');
    try {
      const admin = (await import('firebase-admin')).default;
      let serviceAccount;
      try {
        serviceAccount = JSON.parse(saEnv);
      } catch {
        serviceAccount = JSON.parse(Buffer.from(saEnv, 'base64').toString('utf8'));
      }
      if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
      }
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id || 'whereabouts-510db'
        });
      }
      const db = admin.firestore();
      const usersSnap = await db.collection('users').get();
      let created = 0;
      for (const doc of usersSnap.docs) {
        const uid = doc.id;
        const dedupeKey = `announcement_${VERSION}`;
        const notifDocRef = db.collection('notifications').doc(`${uid}_${dedupeKey}`);
        const existing = await notifDocRef.get();
        if (!existing.exists) {
          await notifDocRef.set({
            userId: uid,
            title: NOTIFICATION_TITLE,
            message: NOTIFICATION_BODY,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
            type: 'general',
            dedupeKey: dedupeKey,
            relatedId: VERSION,
            isAnnouncement: true
          });
          created++;
        }
      }
      console.log(`✅ In-app notifications created for ${created} users (skipped already notified users).`);
    } catch (fbError) {
      console.warn('⚠️ Note: Could not sync Firestore in-app notifications:', fbError.message);
    }
  } else {
    console.log('\n💡 Note: Push broadcast sent to all subscribed devices.');
  }

  console.log('\n🎉 Broadcast announcement complete!');
}

sendBroadcast();
