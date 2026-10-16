// Seeds the LOCAL Firebase Emulator Suite with a small, realistic data set so
// every screen of the app can be exercised (populated, empty and pending
// states). It refuses to run unless all emulator hosts are set, so it can
// never write to a real Firebase project.
//
// Usage (emulators must be running, see docs/refactor/REPORT.md):
//   cd tools/emulator && npm install && npm run seed
//
// The test account password comes from TEST_ACCOUNT_PASSWORD; the emulator-only
// default below is not a real credential.

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

const admin = require('firebase-admin');

const projectId = process.env.GCLOUD_PROJECT || 'later-da778';
const bucketName = process.env.STORAGE_BUCKET || `${projectId}.firebasestorage.app`;
admin.initializeApp({ projectId, storageBucket: bucketName });

const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket();

const PASSWORD = process.env.TEST_ACCOUNT_PASSWORD || 'emulator-only-123';

// Android emulator default GPS fix (Googleplex), so seeded capsules are nearby.
const HOME = { lat: 37.4219983, lng: -122.084 };
const near = (dLat, dLng) =>
  new admin.firestore.GeoPoint(HOME.lat + dLat, HOME.lng + dLng);

const users = [
  { key: 'alice', name: 'Alice Walker', username: 'alice', email: process.env.TEST_ACCOUNT_EMAIL || 'alice@later.test' },
  { key: 'bob', name: 'Bob Stone', username: 'bobstone', email: 'bob@later.test' },
  { key: 'carol', name: 'Carol King', username: 'carolk', email: 'carol@later.test' },
  { key: 'dave', name: 'Dave Miller', username: 'davem', email: 'dave@later.test' },
  { key: 'erin', name: 'Erin Moss', username: 'erinm', email: 'erin@later.test' },
  { key: 'frank', name: 'Frank Ocean', username: 'franko', email: 'frank@later.test' },
];

/** Minimal PNG encoder: a vertical two-colour gradient, so seeded images are distinguishable. */
function gradientPng(width, height, [r1, g1, b1], [r2, g2, b2]) {
  const rows = [];
  for (let y = 0; y < height; y++) {
    const t = y / (height - 1);
    const row = Buffer.alloc(1 + width * 3);
    for (let x = 0; x < width; x++) {
      row[1 + x * 3] = Math.round(r1 + (r2 - r1) * t);
      row[2 + x * 3] = Math.round(g1 + (g2 - g1) * t);
      row[3 + x * 3] = Math.round(b1 + (b2 - b1) * t);
    }
    rows.push(row);
  }
  const crcTable = Array.from({ length: 256 }, (_, n) => {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    return c >>> 0;
  });
  const crc32 = (buf) => {
    let c = 0xffffffff;
    for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
  };
  const chunk = (type, data) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(td));
    return Buffer.concat([len, td, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 2; // colour type RGB
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(Buffer.concat(rows))),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

async function upload(path, png) {
  const token = `seed-${path.replace(/[^a-z0-9]/gi, '-')}`;
  await bucket.file(path).save(png, {
    contentType: 'image/png',
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
  // URL as seen from the Android emulator (10.0.2.2 is the host loopback).
  const publicHost = host.replace(/^(127\.0\.0\.1|localhost)/, '10.0.2.2');
  return `http://${publicHost}/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

async function clearAll() {
  const list = await auth.listUsers(1000);
  if (list.users.length) await auth.deleteUsers(list.users.map((u) => u.uid));
  await db.recursiveDelete(db.collection('users'));
  await db.recursiveDelete(db.collection('capsules'));
  await db.recursiveDelete(db.collection('friend_requests'));
  const [files] = await bucket.getFiles();
  await Promise.all(files.map((f) => f.delete()));
}

async function main() {
  console.log(`Seeding emulators for project ${projectId} …`);
  await clearAll();

  const uid = {};
  for (const u of users) {
    const record = await auth.createUser({
      email: u.email,
      password: PASSWORD,
      displayName: u.name,
    });
    uid[u.key] = record.uid;
  }

  const ts = (daysAgo) =>
    admin.firestore.Timestamp.fromDate(new Date(Date.now() - daysAgo * 86400000));

  const userDoc = (u, extra = {}) => ({
    uid: uid[u.key],
    email: u.email,
    name: u.name,
    username: u.username,
    createdAt: ts(30),
    ...extra,
  });

  // Alice is the primary test account: two friends, one request each way.
  await db.doc(`users/${uid.alice}`).set(
    userDoc(users[0], { friends: [uid.bob, uid.carol], favorites: [] }),
  );
  await db.doc(`users/${uid.bob}`).set(userDoc(users[1], { friends: [uid.alice] }));
  await db.doc(`users/${uid.carol}`).set(userDoc(users[2], { friends: [uid.alice] }));
  await db.doc(`users/${uid.dave}`).set(userDoc(users[3], { friends: [] }));
  await db.doc(`users/${uid.erin}`).set(userDoc(users[4], { friends: [] }));
  await db.doc(`users/${uid.frank}`).set(userDoc(users[5], { friends: [] }));

  await db.doc(`friend_requests/${uid.dave}_${uid.alice}`).set({
    fromUserId: uid.dave,
    toUserId: uid.alice,
    status: 'pending',
    createdAt: ts(1),
  });
  await db.doc(`friend_requests/${uid.alice}_${uid.erin}`).set({
    fromUserId: uid.alice,
    toUserId: uid.erin,
    status: 'pending',
    createdAt: ts(2),
  });

  // Profile and background images.
  await upload(`userdata/${uid.bob}/assets/images/profile_image`, gradientPng(256, 256, [86, 201, 46], [20, 90, 20]));
  await upload(`userdata/${uid.bob}/assets/images/profile_image_small`, gradientPng(128, 128, [86, 201, 46], [20, 90, 20]));
  await upload(`userdata/${uid.alice}/assets/images/profile_image`, gradientPng(256, 256, [255, 170, 60], [200, 60, 60]));
  await upload(`userdata/${uid.alice}/assets/images/profile_image_small`, gradientPng(128, 128, [255, 170, 60], [200, 60, 60]));
  await upload(`userdata/${uid.alice}/assets/images/background_image`, gradientPng(400, 200, [120, 180, 255], [40, 60, 160]));

  const capsules = [
    { owner: 'alice', title: 'First snow', description: 'The day it snowed in the valley', color: 'red', privacy: 'public', loc: near(0.002, 0.001), created: 20, openIn: -2 },
    { owner: 'alice', title: 'Graduation', description: 'Open in a year', color: 'blue', privacy: 'friends', loc: near(-0.003, 0.002), created: 10, openIn: 365 },
    { owner: 'alice', title: 'Secret note', description: '', color: 'purple', privacy: 'private', loc: near(0.001, -0.004), created: 5, openIn: 30 },
    { owner: 'alice', title: 'Beach day', description: 'Sun, sand and friends', color: 'yellow', privacy: 'public', loc: near(0.05, 0.05), created: 1, openIn: 7 },
    { owner: 'bob', title: "Bob's garden", description: 'Tomatoes!', color: 'green', privacy: 'public', loc: near(0.004, 0.003), created: 3, openIn: -1 },
    { owner: 'carol', title: 'For friends only', description: 'Hi Alice', color: 'orange', privacy: 'friends', loc: near(-0.002, -0.002), created: 2, openIn: 14 },
    { owner: 'erin', title: "Erin's private", description: 'Must stay hidden', color: 'purple', privacy: 'private', loc: near(0.003, -0.001), created: 2, openIn: 14 },
  ];
  const palette = {
    red: [[255, 90, 90], [140, 20, 20]],
    blue: [[90, 160, 255], [20, 40, 140]],
    purple: [[190, 120, 255], [80, 20, 140]],
    yellow: [[255, 230, 90], [200, 140, 20]],
    green: [[120, 230, 120], [20, 120, 40]],
    orange: [[255, 180, 90], [200, 90, 20]],
  };
  const capsuleIds = [];
  for (const c of capsules) {
    const ref = db.collection('capsules').doc();
    capsuleIds.push(ref.id);
    const imageUrl = await upload(
      `userdata/${uid[c.owner]}/capsules/${ref.id}/image.jpg`,
      gradientPng(360, 480, ...palette[c.color]),
    );
    await ref.set({
      ownerId: uid[c.owner],
      imageUrl,
      title: c.title,
      description: c.description || null,
      location: c.loc,
      privacy: c.privacy,
      createdAt: ts(c.created),
      isScheduled: true,
      openAt: ts(-c.openIn),
      color: c.color,
    });
  }
  await db.doc(`users/${uid.alice}`).update({ favorites: [capsuleIds[0]] });

  // Bob follows Alice; Alice follows Carol.
  await db.doc(`users/${uid.bob}/following/${uid.alice}`).set({ followedAt: ts(4), notificationsEnabled: true });
  await db.doc(`users/${uid.alice}/followers/${uid.bob}`).set({ followedAt: ts(4) });
  await db.doc(`users/${uid.alice}/following/${uid.carol}`).set({ followedAt: ts(3), notificationsEnabled: true });
  await db.doc(`users/${uid.carol}/followers/${uid.alice}`).set({ followedAt: ts(3) });

  const notifications = [
    { type: 'follow', fromUserId: uid.bob, fromUserName: 'bobstone', message: 'started following you', timestamp: ts(4), isRead: true },
    { type: 'capsule', fromUserId: uid.carol, fromUserName: 'carolk', message: 'created a new capsule', capsuleId: capsuleIds[5], timestamp: ts(2), isRead: false },
    { type: 'follow', fromUserId: uid.frank, fromUserName: 'franko', message: 'started following you', timestamp: ts(0.1), isRead: false },
  ];
  for (const n of notifications) {
    await db.collection(`users/${uid.alice}/notifications`).add({ fromUserAvatar: '', ...n });
  }

  console.log('Seeded users:');
  for (const u of users) console.log(`  ${u.email}  uid=${uid[u.key]}`);
  console.log('Password for all seeded accounts: value of TEST_ACCOUNT_PASSWORD (or the emulator-only default).');
}

main().then(
  () => process.exit(0),
  (e) => {
    console.error(e);
    process.exit(1);
  },
);
