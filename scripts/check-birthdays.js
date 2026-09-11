import admin from 'firebase-admin';
import { Solar } from 'lunar-javascript';

console.log('--- Checking Environment Secrets ---');
const hasWhereaboutsSa = !!process.env.FIREBASE_SERVICE_ACCOUNT_WHEREABOUTS_510DB;
const hasDefaultSa = !!process.env.FIREBASE_SERVICE_ACCOUNT;
console.log('- FIREBASE_SERVICE_ACCOUNT_WHEREABOUTS_510DB present:', hasWhereaboutsSa);
console.log('- FIREBASE_SERVICE_ACCOUNT present:', hasDefaultSa);
console.log('- ONESIGNAL_API_KEY present:', !!process.env.ONESIGNAL_API_KEY);

const isForce = process.env.FORCE_CHECK === 'true' || process.argv.includes('--force');
console.log('- FORCE_CHECK enabled:', isForce);

const saEnv = process.env.FIREBASE_SERVICE_ACCOUNT_WHEREABOUTS_510DB || process.env.FIREBASE_SERVICE_ACCOUNT;
if (!saEnv) {
  console.error('ERROR: Missing Firebase service account secret. Neither FIREBASE_SERVICE_ACCOUNT_WHEREABOUTS_510DB nor FIREBASE_SERVICE_ACCOUNT was found.');
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(saEnv);
  console.log('Successfully parsed Firebase service account as raw JSON.');
} catch (e1) {
  try {
    const decoded = Buffer.from(saEnv, 'base64').toString('utf8');
    serviceAccount = JSON.parse(decoded);
    console.log('Successfully decoded and parsed Firebase service account from base64.');
  } catch (e2) {
    console.error('ERROR: Failed to parse Firebase service account JSON (tried raw JSON and base64).');
    console.error('Raw JSON error:', e1.message);
    console.error('Base64 decode error:', e2.message);
    process.exit(1);
  }
}

if (serviceAccount.private_key) {
  serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
}

console.log(`Connecting to Firebase project: ${serviceAccount.project_id || 'whereabouts-510db'} (Client Email: ${serviceAccount.client_email})...`);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id || 'whereabouts-510db'
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

async function sendOneSignalPush(recipientUids, title, message) {
  if (!recipientUids || recipientUids.length === 0) {
    console.log('Push notification skipped: No recipient UIDs.');
    return;
  }
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
    data: { type: 'birthdayToday' }
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
    console.log(`OneSignal Push Sent to ${recipientUids.length} users (${res.status}):`, JSON.stringify(result));
  } catch (err) {
    console.error('Failed to send OneSignal push:', err);
  }
}

async function recordInAppNotifications(recipientUids, message, groupId, birthdayPersonId, dedupePrefix) {
  if (!recipientUids || recipientUids.length === 0) {
    console.log('In-app notification skipped: No recipient UIDs.');
    return;
  }
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
    console.log(`  -> Staging in-app notification doc: ${docRef.path}`);
  }

  await batch.commit();
  console.log(`  -> Successfully saved ${recipientUids.length} in-app notification(s) to Firestore.`);
}

function parseDate(rawDate) {
  if (!rawDate) return null;
  if (typeof rawDate.toDate === 'function') {
    return rawDate.toDate();
  }
  if (rawDate instanceof Date) {
    return rawDate;
  }
  const parsed = new Date(rawDate);
  return isNaN(parsed.getTime()) ? null : parsed;
}

function matchesTodaySolar(dateObj) {
  if (!dateObj) return false;
  const bdateStr = mytFormatter.format(dateObj);
  const [, bMonth, bDay] = bdateStr.split('-').map(Number);
  const utcMonth = dateObj.getUTCMonth() + 1;
  const utcDay = dateObj.getUTCDate();

  // Match either MYT formatted date or raw UTC day/month to handle any timezone offset
  return (bMonth === todayMonth && bDay === todayDay) || (utcMonth === todayMonth && utcDay === todayDay);
}

async function run() {
  const groupsSnap = await db.collection('groups').get();
  console.log(`Found ${groupsSnap.docs.length} total group(s) in Firestore.`);

  let totalBirthdaysFound = 0;

  for (const groupDoc of groupsSnap.docs) {
    const group = groupDoc.data();
    const groupId = groupDoc.id;
    const memberIds = group.members || [];

    console.log(`\n--- Inspecting Group: "${group.name || groupId}" (${groupId}) ---`);
    console.log(`  Members (${memberIds.length}): ${JSON.stringify(memberIds)}`);
    console.log(`  lastBirthdayCheck in Firestore: "${group.lastBirthdayCheck || 'never'}"`);

    if (memberIds.length === 0) {
      console.log('  Group has 0 members. Skipping.');
      continue;
    }

    // Check if daily check was already completed today
    if (!isForce && group.lastBirthdayCheck === todayStr) {
      console.log(`  Already checked for today (${todayStr}). Skipping. (Run with FORCE_CHECK=true or trigger with force input to re-run)`);
      continue;
    }

    console.log(`  Running birthday checks for group "${group.name || groupId}"...`);

    // A. Check regular users
    for (const memberId of memberIds) {
      const userDoc = await db.collection('users').doc(memberId).get();
      if (!userDoc.exists) {
        console.log(`  [User ${memberId}] Document does not exist in 'users' collection.`);
        continue;
      }
      const u = userDoc.data();
      const displayName = u.displayName || u.email || memberId;
      const bdate = parseDate(u.birthday);
      const bdateStr = bdate ? mytFormatter.format(bdate) : 'none';

      console.log(`  [User: "${displayName}"] birthday: ${bdateStr}, lunar: ${u.hasLunarBirthday ? `M${u.lunarBirthdayMonth}/D${u.lunarBirthdayDay}` : 'false'}`);

      // 1. Solar Birthday
      if (bdate && matchesTodaySolar(bdate)) {
        totalBirthdaysFound++;
        console.log(`  🎉 MATCH! Solar Birthday today for "${displayName}"!`);
        let recipients = memberIds.filter(id => id !== memberId);
        if (recipients.length === 0) {
          console.log(`  (Note: Group only has 1 member, sending notification to "${displayName}" for testing)`);
          recipients = [memberId];
        }
        const message = `🎂 ${displayName}'s birthday is today!`;
        const dedupeKey = `birthday_${groupId}_${memberId}_${todayStr}_solar`;

        await recordInAppNotifications(recipients, message, groupId, memberId, dedupeKey);
        await sendOneSignalPush(recipients, `${displayName}'s Birthday!`, message);
      }

      // 2. Lunar Birthday
      if (u.hasLunarBirthday && (u.lunarBirthdayMonth === currentLunarMonth || u.lunarBirthdayMonth === Math.abs(lunar.getMonth())) && u.lunarBirthdayDay === currentLunarDay) {
        totalBirthdaysFound++;
        console.log(`  🏮 MATCH! Lunar Birthday today for "${displayName}"!`);
        let recipients = memberIds.filter(id => id !== memberId);
        if (recipients.length === 0) {
          recipients = [memberId];
        }
        const message = `🏮 ${displayName}'s lunar birthday is today!`;
        const dedupeKey = `birthday_${groupId}_${memberId}_${todayStr}_lunar`;

        await recordInAppNotifications(recipients, message, groupId, memberId, dedupeKey);
        await sendOneSignalPush(recipients, `${displayName}'s Lunar Birthday!`, message);
      }
    }

    // B. Check placeholder members
    const phSnap = await db.collection('placeholder_members').where('groupId', '==', groupId).get();
    console.log(`  Placeholder members found: ${phSnap.docs.length}`);

    for (const phDoc of phSnap.docs) {
      const ph = phDoc.data();
      const phId = phDoc.id;
      const displayName = ph.displayName || 'Placeholder';
      const bdate = parseDate(ph.birthday);
      const bdateStr = bdate ? mytFormatter.format(bdate) : 'none';

      console.log(`  [Placeholder: "${displayName}"] birthday: ${bdateStr}, lunar: ${ph.hasLunarBirthday ? `M${ph.lunarBirthdayMonth}/D${ph.lunarBirthdayDay}` : 'false'}`);

      // 1. Solar Birthday
      if (bdate && matchesTodaySolar(bdate)) {
        totalBirthdaysFound++;
        console.log(`  🎉 MATCH! Placeholder Solar Birthday today for "${displayName}"!`);
        const message = `🎂 ${displayName}'s birthday is today!`;
        const dedupeKey = `birthday_${groupId}_${phId}_${todayStr}_solar`;

        await recordInAppNotifications(memberIds, message, groupId, phId, dedupeKey);
        await sendOneSignalPush(memberIds, `${displayName}'s Birthday!`, message);
      }

      // 2. Lunar Birthday
      if (ph.hasLunarBirthday && (ph.lunarBirthdayMonth === currentLunarMonth || ph.lunarBirthdayMonth === Math.abs(lunar.getMonth())) && ph.lunarBirthdayDay === currentLunarDay) {
        totalBirthdaysFound++;
        console.log(`  🏮 MATCH! Placeholder Lunar Birthday today for "${displayName}"!`);
        const message = `🏮 ${displayName}'s lunar birthday is today!`;
        const dedupeKey = `birthday_${groupId}_${phId}_${todayStr}_lunar`;

        await recordInAppNotifications(memberIds, message, groupId, phId, dedupeKey);
        await sendOneSignalPush(memberIds, `${displayName}'s Lunar Birthday!`, message);
      }
    }

    // Mark group daily check done
    await db.collection('groups').doc(groupId).update({
      lastBirthdayCheck: todayStr
    });
    console.log(`  Updated group.lastBirthdayCheck to ${todayStr}`);
  }

  console.log(`\n=== CHECK COMPLETE: ${totalBirthdaysFound} birthday(s) processed. ===`);
}

run().catch(err => {
  console.error('Fatal error running birthday check:', err);
  process.exit(1);
});
