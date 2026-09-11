import admin from 'firebase-admin';
import { Solar } from 'lunar-javascript';

// 1. Initialize Firebase Admin
const saEnv = process.env.FIREBASE_SERVICE_ACCOUNT_WHEREABOUTS_510DB || process.env.FIREBASE_SERVICE_ACCOUNT;
if (!saEnv) {
  console.error('ERROR: Missing FIREBASE_SERVICE_ACCOUNT or FIREBASE_SERVICE_ACCOUNT_WHEREABOUTS_510DB secret/environment variable.');
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(saEnv);
} catch (e) {
  console.error('ERROR: Failed to parse Firebase service account JSON:', e.message);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// OneSignal credentials
const oneSignalApiKey = process.env.ONESIGNAL_API_KEY;
const oneSignalAppId = process.env.ONESIGNAL_APP_ID || '74c32f25-a8d0-4d63-889b-9edf49ba8784';

// Get Malaysia local date (UTC+8)
const now = new Date();
const mytFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Asia/Kuala_Lumpur',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit'
});
const todayStr = mytFormatter.format(now); // "YYYY-MM-DD"
const [todayYear, todayMonth, todayDay] = todayStr.split('-').map(Number);

// Convert to Solar / Lunar for Malaysia local day
const solar = Solar.fromYmd(todayYear, todayMonth, todayDay);
const lunar = solar.getLunar();
const currentLunarMonth = Math.abs(lunar.getMonth());
const currentLunarDay = lunar.getDay();

console.log(`=== DAILY BIRTHDAY CHECK (MYT ${todayStr} 00:00) ===`);
console.log(`Solar: ${todayYear}-${todayMonth}-${todayDay} | Lunar: Month ${currentLunarMonth}, Day ${currentLunarDay}`);

async function sendOneSignalPush(recipientUids, title, message, dedupeKey) {
  if (!recipientUids || recipientUids.length === 0) return;
  if (!oneSignalApiKey) {
    console.warn('ONESIGNAL_API_KEY not configured, skipping push notification.');
    return;
  }

  const payload = {
    app_id: oneSignalAppId,
    target_channel: 'push',
    include_aliases: {
      external_id: recipientUids
    },
    headings: { en: title || 'Orbit' },
    contents: { en: message },
    data: { type: 'birthdayToday' },
    ...(dedupeKey ? { external_id: String(dedupeKey) } : {})
  };

  try {
    const res = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${oneSignalApiKey}`
      },
      body: JSON.stringify(payload)
    });
    const result = await res.json();
    console.log(`OneSignal Push Sent to ${recipientUids.length} users:`, JSON.stringify(result));
  } catch (err) {
    console.error('Failed to send OneSignal push:', err);
  }
}

async function recordInAppNotifications(recipientUids, message, groupId, birthdayPersonId, dedupePrefix) {
  if (!recipientUids || recipientUids.length === 0) return;
  const batch = db.batch();
  const nowTs = admin.firestore.FieldValue.serverTimestamp();

  for (const uid of recipientUids) {
    const dedupeKey = `${dedupePrefix}_${uid}`;
    const docRef = db.collection('notifications').doc(`${uid}_${dedupeKey}`);
    batch.set(docRef, {
      userId: uid,
      message,
      timestamp: nowTs,
      read: false,
      type: 'birthdayToday',
      dedupeKey,
      groupId,
      relatedId: birthdayPersonId
    }, { merge: true });
  }

  await batch.commit();
}

async function run() {
  const groupsSnap = await db.collection('groups').get();
  console.log(`Found ${groupsSnap.docs.length} total groups.`);

  let totalBirthdaysFound = 0;

  for (const groupDoc of groupsSnap.docs) {
    const group = groupDoc.data();
    const groupId = groupDoc.id;
    const memberIds = group.members || [];

    if (memberIds.length === 0) continue;

    // Check if daily check was already completed today
    if (group.lastBirthdayCheck === todayStr) {
      console.log(`Group "${group.name || groupId}": Already checked for ${todayStr}. Skipping.`);
      continue;
    }

    console.log(`Checking group: "${group.name || groupId}" (${memberIds.length} members)...`);

    // A. Check regular users
    for (const memberId of memberIds) {
      const userDoc = await db.collection('users').doc(memberId).get();
      if (!userDoc.exists) continue;
      const u = userDoc.data();
      const displayName = u.displayName || u.email || 'Group Member';

      // 1. Solar Birthday
      if (u.birthday) {
        const bdate = u.birthday.toDate ? u.birthday.toDate() : new Date(u.birthday);
        const bdateStr = mytFormatter.format(bdate);
        const [, bMonth, bDay] = bdateStr.split('-').map(Number);
        if (bMonth === todayMonth && bDay === todayDay) {
          totalBirthdaysFound++;
          console.log(`🎂 Solar Birthday today: ${displayName} in group "${group.name}"`);
          const recipients = memberIds.filter(id => id !== memberId);
          const message = `🎂 ${displayName}'s birthday is today!`;
          const dedupeKey = `birthday_${groupId}_${memberId}_${todayStr}_solar`;

          await recordInAppNotifications(recipients, message, groupId, memberId, dedupeKey);
          await sendOneSignalPush(recipients, `${displayName}'s Birthday!`, message, dedupeKey);
        }
      }

      // 2. Lunar Birthday
      if (u.hasLunarBirthday && (u.lunarBirthdayMonth === currentLunarMonth || u.lunarBirthdayMonth === Math.abs(lunar.getMonth())) && u.lunarBirthdayDay === currentLunarDay) {
        totalBirthdaysFound++;
        console.log(`🏮 Lunar Birthday today: ${displayName} in group "${group.name}"`);
        const recipients = memberIds.filter(id => id !== memberId);
        const message = `🏮 ${displayName}'s lunar birthday is today!`;
        const dedupeKey = `birthday_${groupId}_${memberId}_${todayStr}_lunar`;

        await recordInAppNotifications(recipients, message, groupId, memberId, dedupeKey);
        await sendOneSignalPush(recipients, `${displayName}'s Lunar Birthday!`, message, dedupeKey);
      }
    }

    // B. Check placeholder members
    const phSnap = await db.collection('placeholder_members').where('groupId', '==', groupId).get();
    for (const phDoc of phSnap.docs) {
      const ph = phDoc.data();
      const phId = phDoc.id;
      const displayName = ph.displayName || 'Placeholder';

      // 1. Solar Birthday
      if (ph.birthday) {
        const bdate = ph.birthday.toDate ? ph.birthday.toDate() : new Date(ph.birthday);
        const bdateStr = mytFormatter.format(bdate);
        const [, bMonth, bDay] = bdateStr.split('-').map(Number);
        if (bMonth === todayMonth && bDay === todayDay) {
          totalBirthdaysFound++;
          console.log(`🎂 Placeholder Solar Birthday today: ${displayName} in group "${group.name}"`);
          const message = `🎂 ${displayName}'s birthday is today!`;
          const dedupeKey = `birthday_${groupId}_${phId}_${todayStr}_solar`;

          await recordInAppNotifications(memberIds, message, groupId, phId, dedupeKey);
          await sendOneSignalPush(memberIds, `${displayName}'s Birthday!`, message, dedupeKey);
        }
      }

      // 2. Lunar Birthday
      if (ph.hasLunarBirthday && (ph.lunarBirthdayMonth === currentLunarMonth || ph.lunarBirthdayMonth === Math.abs(lunar.getMonth())) && ph.lunarBirthdayDay === currentLunarDay) {
        totalBirthdaysFound++;
        console.log(`🏮 Placeholder Lunar Birthday today: ${displayName} in group "${group.name}"`);
        const message = `🏮 ${displayName}'s lunar birthday is today!`;
        const dedupeKey = `birthday_${groupId}_${phId}_${todayStr}_lunar`;

        await recordInAppNotifications(memberIds, message, groupId, phId, dedupeKey);
        await sendOneSignalPush(memberIds, `${displayName}'s Lunar Birthday!`, message, dedupeKey);
      }
    }

    // Mark group daily check done to prevent duplicate alerts
    await db.collection('groups').doc(groupId).update({
      lastBirthdayCheck: todayStr
    });
  }

  console.log(`=== CHECK COMPLETE: ${totalBirthdaysFound} birthdays processed. ===`);
}

run().catch(err => {
  console.error('Fatal error running birthday check:', err);
  process.exit(1);
});
