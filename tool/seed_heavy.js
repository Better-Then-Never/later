// Heavy, realistic data for performance checks on a real phone
// (docs/feel/RIG.md). LOCAL EMULATORS ONLY: it refuses to run unless every
// emulator host points at this machine, so it can never write to a real
// Firebase project. It replaces whatever the emulators hold.
//
//   node tool/seed_heavy.js
//   SEED_CENTER=52.23,21.01 node tool/seed_heavy.js     # where most capsules go
//   PUBLIC_STORAGE_HOST=10.0.2.2:9199 node tool/seed_heavy.js   # Android emulator
//
// Needs firebase-admin from tools/emulator (cd tools/emulator && npm install).
//
// Data: alice@later.test (main account, password TEST_ACCOUNT_PASSWORD or the
// emulator-only default) with 60 friends, 40 other people, 2,000 capsules
// (1,500 within ~25 km of SEED_CENTER, 500 in 40 other cities; 100 are
// Alice's), a 600-message chat with Bob (capsule photos and replies), 20
// shorter chats, 40 notifications, requests, follows, reactions and comments.
// Photos are 8 shared images, so Storage stays small.

const path = require('path');
const zlib = require('zlib');

const required = {
  FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099',
  FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:9199',
};
for (const [key, fallback] of Object.entries(required)) {
  process.env[key] = process.env[key] || fallback;
}
for (const key of Object.keys(required)) {
  if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env[key])) {
    console.error(`Refusing to seed: ${key}=${process.env[key]} is not a local emulator.`);
    process.exit(1);
  }
}

const admin = require(
  require.resolve('firebase-admin', { paths: [path.join(__dirname, '..', 'tools', 'emulator')] }),
);

const projectId = process.env.GCLOUD_PROJECT || 'later-da778';
const bucketName = process.env.STORAGE_BUCKET || `${projectId}.firebasestorage.app`;
admin.initializeApp({ projectId, storageBucket: bucketName });
const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket();
const { Timestamp, GeoPoint } = admin.firestore;

const PASSWORD = process.env.TEST_ACCOUNT_PASSWORD || 'emulator-only-123';
// The phone reaches the Storage emulator through `adb reverse` on 127.0.0.1.
const PUBLIC_STORAGE_HOST = process.env.PUBLIC_STORAGE_HOST || '127.0.0.1:9199';
const [CENTER_LAT, CENTER_LNG] = (process.env.SEED_CENTER || '52.2297,21.0122')
  .split(',')
  .map(Number);

// Deterministic pseudo-random numbers: the same data every run.
let seed = 20261017;
const rand = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
const pick = (list) => list[Math.floor(rand() * list.length)];
const between = (a, b) => a + rand() * (b - a);

const DAY = 86400000;
const now = Date.now();
const ts = (ms) => Timestamp.fromMillis(Math.round(ms));

// ---- images ------------------------------------------------------------------

function png(width, height, [r1, g1, b1], [r2, g2, b2], stripes = 0) {
  const rows = [];
  for (let y = 0; y < height; y++) {
    const t = y / (height - 1);
    const row = Buffer.alloc(1 + width * 3);
    for (let x = 0; x < width; x++) {
      // Soft diagonal stripes give the decoder some detail to chew on.
      const s = stripes ? 0.85 + 0.15 * Math.sin(((x + y) / width) * stripes * Math.PI) : 1;
      row[1 + x * 3] = Math.round((r1 + (r2 - r1) * t) * s);
      row[2 + x * 3] = Math.round((g1 + (g2 - g1) * t) * s);
      row[3 + x * 3] = Math.round((b1 + (b2 - b1) * t) * s);
    }
    rows.push(row);
  }
  const crcTable = Array.from({ length: 256 }, (_, n) => {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    return c >>> 0;
  });
  const crc = (buf) => {
    let c = 0xffffffff;
    for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
  };
  const chunk = (type, data) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type), data]);
    const sum = Buffer.alloc(4);
    sum.writeUInt32BE(crc(td));
    return Buffer.concat([len, td, sum]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(Buffer.concat(rows))),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

async function upload(file, bytes) {
  const token = `seed-${file.replace(/[^a-z0-9]/gi, '-')}`;
  await bucket.file(file).save(bytes, {
    contentType: 'image/png',
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  return `http://${PUBLIC_STORAGE_HOST}/v0/b/${bucketName}/o/${encodeURIComponent(file)}?alt=media&token=${token}`;
}

const COLORS = {
  red: [[255, 90, 90], [140, 20, 20]],
  blue: [[90, 160, 255], [20, 40, 140]],
  green: [[120, 230, 120], [20, 120, 40]],
  yellow: [[255, 230, 90], [200, 140, 20]],
  orange: [[255, 180, 90], [200, 90, 20]],
  purple: [[190, 120, 255], [80, 20, 140]],
};

// ---- people --------------------------------------------------------------------

const FIRST = ['Anna', 'Ben', 'Chloe', 'Daniel', 'Ella', 'Felix', 'Greta', 'Hugo', 'Iris', 'Jonas', 'Kira',
  'Leo', 'Mila', 'Nico', 'Olga', 'Pavel', 'Quinn', 'Rosa', 'Sasha', 'Tom', 'Uma', 'Viktor', 'Wanda', 'Yara', 'Zoe'];
const LAST = ['Novak', 'Kowalski', 'Ivanova', 'Schmidt', 'Garcia', 'Rossi', 'Dubois', 'Larsen', 'Berg', 'Moreno',
  'Fischer', 'Petrov', 'Nowak', 'Silva', 'Klein'];

const people = [
  { key: 'alice', name: 'Alice Walker', username: 'alice', email: process.env.TEST_ACCOUNT_EMAIL || 'alice@later.test' },
  { key: 'bob', name: 'Bob Stone', username: 'bobstone', email: 'bob@later.test' },
  { key: 'carol', name: 'Carol King', username: 'carolk', email: 'carol@later.test' },
  { key: 'dave', name: 'Dave Miller', username: 'davem', email: 'dave@later.test' },
  { key: 'erin', name: 'Erin Moss', username: 'erinm', email: 'erin@later.test' },
  { key: 'frank', name: 'Frank Ocean', username: 'franko', email: 'frank@later.test' },
];
for (let i = 1; i <= 58; i++) {
  const name = `${FIRST[i % FIRST.length]} ${LAST[(i * 7) % LAST.length]}`;
  people.push({ key: `friend${i}`, name, username: `friend_${String(i).padStart(2, '0')}`, email: `friend${i}@later.test` });
}
for (let i = 1; i <= 40; i++) {
  const name = `${FIRST[(i * 3) % FIRST.length]} ${LAST[(i * 11) % LAST.length]}`;
  people.push({ key: `other${i}`, name, username: `person_${String(i).padStart(2, '0')}`, email: `other${i}@later.test` });
}
const friendKeys = ['bob', 'carol', ...Array.from({ length: 58 }, (_, i) => `friend${i + 1}`)];
const otherKeys = Array.from({ length: 40 }, (_, i) => `other${i + 1}`);

const CITIES = [
  [48.8566, 2.3522], [51.5074, -0.1278], [40.4168, -3.7038], [41.9028, 12.4964], [52.52, 13.405],
  [50.0755, 14.4378], [47.4979, 19.0402], [48.2082, 16.3738], [59.3293, 18.0686], [60.1699, 24.9384],
  [55.6761, 12.5683], [52.3676, 4.9041], [50.8503, 4.3517], [38.7223, -9.1393], [37.9838, 23.7275],
  [41.0082, 28.9784], [55.7558, 37.6173], [50.4501, 30.5234], [54.6872, 25.2797], [56.9496, 24.1052],
  [59.437, 24.7536], [53.9006, 27.559], [50.0647, 19.945], [51.1079, 17.0385], [54.352, 18.6466],
  [45.4642, 9.19], [43.7696, 11.2558], [45.764, 4.8357], [43.2965, 5.3698], [46.2044, 6.1432],
  [47.3769, 8.5417], [40.7128, -74.006], [34.0522, -118.2437], [35.6762, 139.6503], [-33.8688, 151.2093],
  [-22.9068, -43.1729], [19.4326, -99.1332], [1.3521, 103.8198], [25.2048, 55.2708], [-33.9249, 18.4241],
];

const TITLES = ['First snow', 'Morning coffee', 'Lake day', 'Old town walk', 'Birthday', 'Concert night', 'Graduation',
  'Road trip', 'Sunset', 'Picnic', 'Museum', 'Rainy Sunday', 'Market', 'Bike ride', 'Mountains', 'Beach', 'Rooftop',
  'New flat', 'Football', 'Dinner with friends', 'Train window', 'Night city', 'Garden', 'Ferry', 'Festival'];
const TEXTS = ['Open this when you miss summer', '', 'We laughed so much', 'Remember this place?', '',
  'Next year we come back', 'The best day this month', '', 'For future me', 'Do not open before the trip'];

const scatter = (lat, lng, km) => {
  // Points thicken towards the centre.
  const r = km * Math.sqrt(rand()) * (0.3 + 0.7 * rand());
  const a = rand() * 2 * Math.PI;
  return new GeoPoint(
    lat + (r / 111) * Math.cos(a),
    lng + (r / (111 * Math.cos((lat * Math.PI) / 180))) * Math.sin(a),
  );
};

async function clearAll() {
  for (;;) {
    const list = await auth.listUsers(1000);
    if (!list.users.length) break;
    await auth.deleteUsers(list.users.map((u) => u.uid));
  }
  for (const c of ['users', 'capsules', 'friend_requests', 'chats', 'usernames', 'reports', 'announcements']) {
    await db.recursiveDelete(db.collection(c));
  }
  const [files] = await bucket.getFiles();
  await Promise.all(files.map((f) => f.delete()));
}

class Writer {
  constructor() {
    this.batch = db.batch();
    this.count = 0;
    this.total = 0;
  }
  async set(ref, data) {
    this.batch.set(ref, data);
    this.count++;
    this.total++;
    if (this.count === 450) await this.flush();
  }
  async flush() {
    if (!this.count) return;
    await this.batch.commit();
    this.batch = db.batch();
    this.count = 0;
  }
}

// With the Functions emulator running, every seeded write would fire the
// triggers (stats, fan-out notifications); they are paused while seeding.
async function backgroundTriggers(on) {
  try {
    await fetch(`http://127.0.0.1:4400/functions/${on ? 'enable' : 'disable'}BackgroundTriggers`, { method: 'PUT' });
  } catch (_) {
    // No emulator hub or no Functions emulator: nothing to pause.
  }
}

async function main() {
  const started = Date.now();
  console.log(`Seeding heavy data for ${projectId}, centre ${CENTER_LAT},${CENTER_LNG} …`);
  await clearAll();

  const uid = {};
  for (const p of people) {
    const record = await auth.createUser({ email: p.email, password: PASSWORD, displayName: p.name });
    uid[p.key] = record.uid;
  }
  const byUid = Object.fromEntries(people.map((p) => [uid[p.key], p]));

  // Avatars for most people (two sizes, as the app expects); Frank and a few
  // others have none, so the placeholders show too.
  const colorNames = Object.keys(COLORS);
  await Promise.all(
    people
      .filter((p, i) => p.key !== 'frank' && i % 7 !== 3)
      .map(async (p, i) => {
        const [c1, c2] = COLORS[colorNames[i % colorNames.length]];
        const base = `userdata/${uid[p.key]}/assets/images`;
        await upload(`${base}/profile_image`, png(256, 256, c1, c2));
        await upload(`${base}/profile_image_small`, png(128, 128, c1, c2));
      }),
  );
  await upload(`userdata/${uid.alice}/assets/images/background_image`, png(800, 400, [120, 180, 255], [40, 60, 160], 6));

  // Eight shared capsule photos.
  const photos = [];
  for (let i = 0; i < 8; i++) {
    const [c1, c2] = COLORS[colorNames[i % colorNames.length]];
    photos.push(await upload(`seed/photos/photo_${i}.png`, png(1200, 1600, c1, c2, 4 + i)));
  }

  // People: Alice has 60 friends; the others know 2-3 of them (friends of
  // friends for suggestions).
  const friendsOf = Object.fromEntries(people.map((p) => [p.key, new Set()]));
  const link = (a, b) => {
    friendsOf[a].add(uid[b]);
    friendsOf[b].add(uid[a]);
  };
  for (const f of friendKeys) link('alice', f);
  for (let i = 0; i < friendKeys.length; i++) link(friendKeys[i], friendKeys[(i + 1) % friendKeys.length]);
  otherKeys.forEach((o, i) => {
    link(o, friendKeys[i % friendKeys.length]);
    link(o, friendKeys[(i * 5 + 3) % friendKeys.length]);
    if (i % 3 === 0) link(o, friendKeys[(i * 11 + 7) % friendKeys.length]);
  });

  const w = new Writer();
  for (const p of people) {
    await w.set(db.doc(`users/${uid[p.key]}`), {
      uid: uid[p.key],
      email: p.email,
      name: p.name,
      username: p.username,
      createdAt: ts(now - 400 * DAY),
      friends: [...friendsOf[p.key]],
      favorites: [],
      followerCount: 0,
      followingCount: 0,
    });
    await w.set(db.doc(`usernames/${p.username}`), { uid: uid[p.key] });
  }

  // Requests: Dave and five others ask Alice; Alice asked Erin.
  const requests = [['dave', 'alice'], ['alice', 'erin'], ...otherKeys.slice(0, 5).map((o) => [o, 'alice'])];
  for (const [from, to] of requests) {
    await w.set(db.doc(`friend_requests/${uid[from]}_${uid[to]}`), {
      fromUserId: uid[from],
      toUserId: uid[to],
      status: 'pending',
      createdAt: ts(now - between(0.1, 6) * DAY),
    });
  }

  // Follows: 30 people follow Alice, she follows 20.
  for (const f of friendKeys.slice(0, 30)) {
    await w.set(db.doc(`users/${uid[f]}/following/${uid.alice}`), { followedAt: ts(now - 20 * DAY), notificationsEnabled: true });
    await w.set(db.doc(`users/${uid.alice}/followers/${uid[f]}`), { followedAt: ts(now - 20 * DAY) });
  }
  for (const f of friendKeys.slice(10, 30)) {
    await w.set(db.doc(`users/${uid.alice}/following/${uid[f]}`), { followedAt: ts(now - 15 * DAY), notificationsEnabled: true });
    await w.set(db.doc(`users/${uid[f]}/followers/${uid.alice}`), { followedAt: ts(now - 15 * DAY) });
  }

  // Capsules: 100 Alice's, 1,200 friends', 700 others' (public).
  const owners = [
    ...Array(100).fill('alice'),
    ...Array.from({ length: 1200 }, (_, i) => friendKeys[i % friendKeys.length]),
    ...Array.from({ length: 700 }, (_, i) => otherKeys[i % otherKeys.length]),
  ];
  const aliceCapsules = [];
  const bobCapsules = [];
  for (let i = 0; i < owners.length; i++) {
    const owner = owners[i];
    const ref = db.collection('capsules').doc();
    const local = i % 4 !== 0; // 1,500 near the centre
    const [lat, lng] = local ? [CENTER_LAT, CENTER_LNG] : pick(CITIES);
    const created = now - between(1, 700) * DAY;
    const opened = rand() < 0.62;
    const color = pick(colorNames);
    const privacy = owner === 'alice'
      ? pick(['public', 'friends', 'private'])
      : otherKeys.includes(owner) ? 'public' : pick(['public', 'friends', 'friends']);
    const doc = {
      ownerId: uid[owner],
      imageUrl: pick(photos),
      title: pick(TITLES),
      description: pick(TEXTS) || null,
      location: scatter(lat, lng, local ? 25 : 12),
      privacy,
      createdAt: ts(created),
      capturedAt: ts(created),
      utcOffsetMinutes: 120,
      isScheduled: !opened,
      openAt: ts(opened ? created + between(0, 3) * DAY : now + between(1, 300) * DAY),
      color,
    };
    if (rand() < 0.3) {
      doc.reactionTotal = Math.floor(between(1, 40));
      doc.reactionCounts = { heart: doc.reactionTotal };
      doc.commentCount = Math.floor(between(0, 12));
    }
    await w.set(ref, doc);
    if (owner === 'alice') aliceCapsules.push({ id: ref.id, opened, ...doc });
    if (owner === 'bob') bobCapsules.push({ id: ref.id, opened, ...doc });
  }

  // "On this day": two of Alice's capsules from today's date one and two years ago.
  for (const years of [1, 2]) {
    const d = new Date(now);
    d.setFullYear(d.getFullYear() - years);
    const ref = db.collection('capsules').doc();
    await w.set(ref, {
      ownerId: uid.alice, imageUrl: photos[years], title: years === 1 ? 'Lake picnic' : 'First snow',
      description: null, location: scatter(CENTER_LAT, CENTER_LNG, 5), privacy: 'private',
      createdAt: ts(d.getTime()), capturedAt: ts(d.getTime()), utcOffsetMinutes: 120,
      isScheduled: false, openAt: ts(d.getTime()), color: 'green',
    });
  }

  // A busy open capsule of Alice's: 50 reactions, 30 comments with replies.
  const busy = aliceCapsules.find((c) => c.opened && c.privacy !== 'private') || aliceCapsules[0];
  const kinds = ['heart', 'laugh', 'wow', 'sad', 'fire', 'clap'];
  const counts = {};
  for (const f of friendKeys.slice(0, 50)) {
    const kind = pick(kinds);
    counts[kind] = (counts[kind] || 0) + 1;
    await w.set(db.doc(`capsules/${busy.id}/reactions/${uid[f]}`), { uid: uid[f], type: kind, updatedAt: ts(now - between(0, 9) * DAY) });
  }
  const comments = [];
  for (let i = 0; i < 30; i++) {
    const ref = db.collection(`capsules/${busy.id}/comments`).doc();
    const author = friendKeys[i % 20];
    const parent = i > 5 && rand() < 0.4 ? pick(comments) : null;
    const data = {
      authorId: uid[author],
      text: pick(['So good!', 'Where is this?', 'Take me there next time', 'Haha', 'Beautiful light', 'Miss this']),
      createdAt: ts(now - (30 - i) * 3600000),
    };
    if (parent) data.replyTo = parent;
    await w.set(ref, data);
    if (!parent) comments.push(ref.id);
  }
  await w.set(db.doc(`capsules/${busy.id}`), {
    ...Object.fromEntries(Object.entries(busy).filter(([k]) => !['id', 'opened'].includes(k))),
    reactionCounts: counts,
    reactionTotal: 50,
    commentCount: 30,
  });

  // The long chat: Alice and Bob, 600 messages over 30 days, capsule photos
  // every ~10th message, replies every ~7th.
  const [a, b] = [uid.alice, uid.bob].sort();
  const chatId = `${a}_${b}`;
  const lines = ['Hey!', 'Are you around this weekend?', 'Look at this one', 'Haha yes', 'Where was that?',
    'We should go back there', 'Sent you a capsule', 'Open it in a week', 'No way', 'That was such a good day',
    'Coffee tomorrow?', 'I am on the train', 'Did you see the lake photos?', 'Not yet, opening now',
    'This is a longer message to see how bubbles wrap over several lines in the chat on a real phone screen.'];
  const messages = [];
  let t = now - 30 * DAY;
  let sender = uid.alice;
  const shareable = [...aliceCapsules.filter((c) => c.opened), ...bobCapsules.filter((c) => c.opened)];
  for (let i = 0; i < 600; i++) {
    if (rand() < 0.35) sender = sender === uid.alice ? uid.bob : uid.alice;
    t += between(1, 120) * 60000;
    const ref = db.collection(`chats/${chatId}/messages`).doc();
    const msg = { senderId: sender, text: pick(lines), timestamp: ts(Math.min(t, now - (600 - i) * 1000)), status: 'sent' };
    if (i % 10 === 4 && shareable.length) {
      const c = pick(shareable);
      Object.assign(msg, { type: 'capsule', capsuleId: c.id, imageUrl: c.imageUrl, text: c.title });
    } else if (i % 7 === 3 && messages.length) {
      const q = pick(messages.slice(-60));
      msg.replyTo = { id: q.id, senderId: q.senderId, text: q.text.slice(0, 140) };
    }
    if (i % 13 === 5) msg.reactions = { [sender === uid.alice ? uid.bob : uid.alice]: pick(kinds) };
    await w.set(ref, msg);
    messages.push({ id: ref.id, senderId: sender, text: msg.text });
  }
  const last = messages[messages.length - 1];
  await w.set(db.doc(`chats/${chatId}`), {
    participants: [uid.alice, uid.bob],
    lastMessage: last.text,
    lastUpdated: ts(now - 1000),
    lastSenderId: last.senderId,
    createdAt: ts(now - 30 * DAY),
    unreadCounts: { [uid.alice]: last.senderId === uid.bob ? 3 : 0 },
  });

  // Twenty shorter chats so the list scrolls.
  for (const f of friendKeys.slice(2, 22)) {
    const [x, y] = [uid.alice, uid[f]].sort();
    let mt = now - between(1, 20) * DAY;
    let lastText = '';
    let lastSender = uid[f];
    for (let i = 0; i < 12; i++) {
      mt += between(5, 300) * 60000;
      lastSender = i % 3 ? uid[f] : uid.alice;
      lastText = pick(lines);
      await w.set(db.collection(`chats/${x}_${y}/messages`).doc(), {
        senderId: lastSender, text: lastText, timestamp: ts(Math.min(mt, now - 60000)), status: 'sent',
      });
    }
    await w.set(db.doc(`chats/${x}_${y}`), {
      participants: [uid.alice, uid[f]], lastMessage: lastText, lastUpdated: ts(Math.min(mt, now - 60000)),
      lastSenderId: lastSender, createdAt: ts(now - 25 * DAY),
      unreadCounts: { [uid.alice]: lastSender === uid.alice ? 0 : Math.floor(between(0, 4)) },
    });
  }

  // Forty notifications of every kind.
  const notificationKinds = ['follow', 'capsule', 'reaction', 'comment', 'reply', 'friendRequest', 'friendAccepted', 'achievement'];
  for (let i = 0; i < 40; i++) {
    const kind = notificationKinds[i % notificationKinds.length];
    const from = friendKeys[i % friendKeys.length];
    const n = {
      type: kind,
      fromUserId: uid[from],
      fromUserName: byUid[uid[from]].username,
      fromUserAvatar: '',
      message: kind,
      timestamp: ts(now - i * 5 * 3600000),
      isRead: i > 6,
    };
    if (['capsule', 'reaction', 'comment', 'reply'].includes(kind)) n.capsuleId = busy.id;
    if (kind === 'reaction') n.reaction = pick(kinds);
    if (kind === 'achievement') n.achievementId = 'collector';
    await w.set(db.collection(`users/${uid.alice}/notifications`).doc(), n);
  }

  // Alice's counters and stats, as the functions would keep them.
  await w.flush();
  await db.doc(`users/${uid.alice}`).update({
    followerCount: 30,
    followingCount: 20,
    favorites: aliceCapsules.slice(0, 5).map((c) => c.id),
    stats: {
      capsules: 102, publicCapsules: 35, streakCurrent: 4, streakLongest: 12,
      streakLastDay: new Date(now).toISOString().slice(0, 10), places: 31, distanceKm: 1240, reactionsReceived: 140, commentsWritten: 12,
    },
  });
  for (const [id, tier, tiers, value] of [['first_capsule', 0, 1, 102], ['collector', 2, 4, 102], ['streak', 1, 5, 12], ['explorer', 2, 4, 31]]) {
    await db.doc(`users/${uid.alice}/achievements/${id}`).set({ id, tier, tiers, value, unlockedAt: ts(now - 3 * DAY) });
  }

  console.log(`Done in ${Math.round((Date.now() - started) / 1000)} s: ${people.length} people, 2,002 capsules, ` +
    `600 + 240 messages, 40 notifications.`);
  console.log(`Sign in as ${people[0].email} (password: TEST_ACCOUNT_PASSWORD or the emulator-only default).`);
  console.log(`Long chat id: ${chatId}`);
}

backgroundTriggers(false)
  .then(main)
  .finally(() => backgroundTriggers(true))
  .then(
    () => process.exit(0),
    (e) => {
      console.error(e);
      process.exit(1);
    },
  );
