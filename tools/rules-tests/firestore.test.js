// Firestore security rules tests. Run with `npm run emulate` (starts its own
// emulators on other ports, see firebase.json). Never uses a real project.
const { test, before, after, beforeEach, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  writeBatch,
  runTransaction,
  serverTimestamp,
  arrayUnion,
  arrayRemove,
  deleteField,
  GeoPoint,
  Timestamp,
  setLogLevel,
} = require('firebase/firestore');

// Denied writes are expected; keep the output readable.
setLogLevel('silent');

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-later-rules',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8180,
    },
  });
});

after(() => env.cleanup());

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

/** Seed data with rules disabled. */
async function seed(fn) {
  await env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
}

function user(uid, extra = {}) {
  return {
    uid,
    name: uid.toUpperCase(),
    username: uid,
    friends: [],
    favorites: [],
    createdAt: Timestamp.now(),
    ...extra,
  };
}

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, 'users/alice'), user('alice', { friends: ['bob'] }));
    await setDoc(doc(db, 'users/bob'), user('bob', { friends: ['alice'] }));
    await setDoc(doc(db, 'users/carol'), user('carol'));
    await setDoc(doc(db, 'usernames/alice'), { uid: 'alice' });
  });
});

describe('users', () => {
  test('profiles need sign-in to read', async () => {
    await assertFails(getDoc(doc(anon(), 'users/alice')));
    await assertSucceeds(getDoc(doc(as('carol'), 'users/alice')));
  });

  test('signup creates the profile and the username reservation together', async () => {
    const db = as('dave');
    await assertSucceeds(
      runTransaction(db, async (tx) => {
        tx.set(doc(db, 'usernames/dave'), { uid: 'dave' });
        tx.set(doc(db, 'users/dave'), {
          uid: 'dave',
          name: 'Dave',
          username: 'dave',
          friends: [],
          favorites: [],
          createdAt: serverTimestamp(),
        });
      }),
    );
  });

  test('a profile without a reservation, or with a taken name, is refused', async () => {
    const db = as('dave');
    await assertFails(
      setDoc(doc(db, 'users/dave'), {
        uid: 'dave', name: 'Dave', username: 'dave', friends: [], favorites: [],
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(setDoc(doc(db, 'usernames/alice'), { uid: 'dave' }));
  });

  test('a new profile cannot start with friends or extra fields', async () => {
    const db = as('dave');
    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames/dave'), { uid: 'dave' });
    batch.set(doc(db, 'users/dave'), {
      uid: 'dave', name: 'Dave', username: 'dave', friends: ['alice'],
      favorites: [], createdAt: serverTimestamp(), email: 'd@x.y',
    });
    await assertFails(batch.commit());
  });

  test('owners edit name and favourites, nobody else does', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'), { name: 'Al' }));
    await assertSucceeds(
      setDoc(doc(as('alice'), 'users/alice'), { favorites: arrayUnion('c1') }, { merge: true }),
    );
    await assertFails(updateDoc(doc(as('carol'), 'users/alice'), { name: 'X' }));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { name: '' }));
  });

  test('legacy private fields may only be removed', async () => {
    await seed((db) => updateDoc(doc(db, 'users/alice'), { fcmToken: 't', email: 'a@x.y' }));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { fcmToken: 'new' }));
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'users/alice'), {
        fcmToken: deleteField(),
        email: deleteField(),
      }),
    );
  });

  test('username change moves the reservation in one transaction', async () => {
    const db = as('alice');
    await assertSucceeds(
      runTransaction(db, async (tx) => {
        tx.set(doc(db, 'usernames/alice.w'), { uid: 'alice' });
        tx.delete(doc(db, 'usernames/alice'));
        tx.update(doc(db, 'users/alice'), { username: 'alice.w' });
      }),
    );
    // Without the reservation the change is refused.
    await assertFails(updateDoc(doc(db, 'users/alice'), { username: 'free.name' }));
    // Invalid usernames are refused.
    await assertFails(
      runTransaction(db, async (tx) => {
        tx.set(doc(db, 'usernames/Bad Name'), { uid: 'alice' });
        tx.update(doc(db, 'users/alice'), { username: 'Bad Name' });
      }),
    );
  });

  test("a reservation cannot be released while it is the user's username", async () => {
    await assertFails(deleteDoc(doc(as('alice'), 'usernames/alice')));
    await assertFails(deleteDoc(doc(as('carol'), 'usernames/alice')));
  });
});

describe('friendships (BUG-076)', () => {
  beforeEach(() =>
    seed((db) =>
      setDoc(doc(db, 'friend_requests/carol_alice'), {
        fromUserId: 'carol',
        toUserId: 'alice',
        status: 'pending',
        createdAt: Timestamp.now(),
      }),
    ),
  );

  function acceptBatch(db) {
    const batch = writeBatch(db);
    batch.update(doc(db, 'friend_requests/carol_alice'), {
      status: 'accepted',
      acceptedAt: serverTimestamp(),
    });
    batch.set(doc(db, 'users/alice'), { friends: arrayUnion('carol') }, { merge: true });
    batch.set(doc(db, 'users/carol'), { friends: arrayUnion('alice') }, { merge: true });
    return batch.commit();
  }

  test('the receiver accepts: request + both friend lists in one batch', async () => {
    await assertSucceeds(acceptBatch(as('alice')));
  });

  test('the sender cannot accept their own request', async () => {
    await assertFails(acceptBatch(as('carol')));
  });

  test('nobody can add themselves to a friend list without an accepted request', async () => {
    await assertFails(
      setDoc(doc(as('carol'), 'users/bob'), { friends: arrayUnion('carol') }, { merge: true }),
    );
  });

  test('nobody can add or remove a third user', async () => {
    await assertFails(
      setDoc(doc(as('carol'), 'users/bob'), { friends: arrayRemove('alice') }, { merge: true }),
    );
    await assertFails(
      setDoc(doc(as('carol'), 'users/bob'), { friends: arrayUnion('dave') }, { merge: true }),
    );
  });

  test('unfriending removes both sides and both requests', async () => {
    const db = as('alice');
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/alice'), { friends: arrayRemove('bob') }, { merge: true });
    batch.set(doc(db, 'users/bob'), { friends: arrayRemove('alice') }, { merge: true });
    batch.delete(doc(db, 'friend_requests/alice_bob'));
    batch.delete(doc(db, 'friend_requests/bob_alice'));
    await assertSucceeds(batch.commit());
  });
});

describe('friend requests', () => {
  const pending = (from, to) => ({
    fromUserId: from,
    toUserId: to,
    status: 'pending',
    createdAt: serverTimestamp(),
  });

  test('only as yourself, only pending', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'friend_requests/alice_carol'), pending('alice', 'carol')));
    await assertFails(setDoc(doc(as('alice'), 'friend_requests/carol_bob'), pending('carol', 'bob')));
    await assertFails(
      setDoc(doc(as('alice'), 'friend_requests/alice_bob'), {
        ...pending('alice', 'bob'),
        status: 'accepted',
      }),
    );
    await assertFails(setDoc(doc(as('alice'), 'friend_requests/x_y'), pending('alice', 'carol')));
  });

  test('participants read; the app queries are allowed; strangers are not', async () => {
    await seed((db) =>
      setDoc(doc(db, 'friend_requests/alice_carol'), { ...pending('alice', 'carol'), createdAt: Timestamp.now() }),
    );
    await assertSucceeds(getDoc(doc(as('carol'), 'friend_requests/alice_carol')));
    await assertFails(getDoc(doc(as('bob'), 'friend_requests/alice_carol')));
    const db = as('carol');
    await assertSucceeds(
      getDocs(query(collection(db, 'friend_requests'), where('toUserId', '==', 'carol'), where('status', '==', 'pending'))),
    );
    await assertFails(getDocs(query(collection(db, 'friend_requests'), where('status', '==', 'pending'))));
  });

  test('cancel, reject and deleting a missing request', async () => {
    await seed((db) =>
      setDoc(doc(db, 'friend_requests/alice_carol'), { ...pending('alice', 'carol'), createdAt: Timestamp.now() }),
    );
    await assertFails(deleteDoc(doc(as('bob'), 'friend_requests/alice_carol')));
    await assertSucceeds(deleteDoc(doc(as('carol'), 'friend_requests/alice_carol')));
    await assertSucceeds(deleteDoc(doc(as('carol'), 'friend_requests/carol_bob')));
  });
});

describe('notifications, follows and tokens', () => {
  function follow(db, me, target) {
    const batch = writeBatch(db);
    batch.set(doc(db, `users/${me}/following/${target}`), {
      followedAt: serverTimestamp(),
      notificationsEnabled: true,
    });
    batch.set(doc(db, `users/${target}/followers/${me}`), { followedAt: serverTimestamp() });
    return batch.commit();
  }

  const followNotice = (from) => ({
    type: 'follow',
    fromUserId: from,
    fromUserName: from,
    fromUserAvatar: '',
    message: 'started following you',
    timestamp: serverTimestamp(),
    isRead: false,
  });

  test('follow, then leave a follow notification', async () => {
    const db = as('carol');
    await assertFails(setDoc(doc(db, 'users/alice/notifications/n1'), followNotice('carol')));
    await assertSucceeds(follow(db, 'carol', 'alice'));
    await assertSucceeds(follow(db, 'carol', 'alice')); // following again
    await assertSucceeds(setDoc(doc(db, 'users/alice/notifications/n1'), followNotice('carol')));
    await assertFails(setDoc(doc(db, 'users/alice/notifications/n2'), followNotice('bob')));
    await assertFails(
      setDoc(doc(db, 'users/alice/notifications/n3'), { ...followNotice('carol'), type: 'capsule' }),
    );
  });

  test('cannot fake a follower entry', async () => {
    await assertFails(setDoc(doc(as('carol'), 'users/alice/followers/bob'), { followedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as('carol'), 'users/alice/followers/carol'), { followedAt: serverTimestamp() }));
  });

  test('only the recipient reads, marks read and deletes', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users/alice/notifications/n1'), { ...followNotice('bob'), timestamp: Timestamp.now() }),
    );
    await assertFails(getDoc(doc(as('bob'), 'users/alice/notifications/n1')));
    await assertSucceeds(getDocs(collection(as('alice'), 'users/alice/notifications')));
    await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice/notifications/n1'), { isRead: true }));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice/notifications/n1'), { message: 'x' }));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'users/alice/notifications/n1')));
  });

  test('push tokens are private to their owner', async () => {
    const token = { token: 'tok1', platform: 'android', updatedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as('alice'), 'users/alice/fcmTokens/tok1'), token));
    await assertFails(getDoc(doc(as('bob'), 'users/alice/fcmTokens/tok1')));
    await assertFails(setDoc(doc(as('bob'), 'users/alice/fcmTokens/tok2'), { ...token, token: 'tok2' }));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'users/alice/fcmTokens/tok1')));
  });
});

describe('capsules', () => {
  const capsule = (owner, privacy, lat = 37.4, extra = {}) => ({
    ownerId: owner,
    imageUrl: 'https://img',
    title: 'T',
    description: null,
    location: new GeoPoint(lat, -122.08),
    privacy,
    createdAt: Timestamp.now(),
    isScheduled: false,
    openAt: null,
    color: 'red',
    ...extra,
  });

  beforeEach(() =>
    seed(async (db) => {
      await setDoc(doc(db, 'capsules/bobPrivate'), capsule('bob', 'private'));
      await setDoc(doc(db, 'capsules/bobFriends'), capsule('bob', 'friends'));
      await setDoc(doc(db, 'capsules/carolFriends'), capsule('carol', 'friends'));
      await setDoc(doc(db, 'capsules/carolPublic'), capsule('carol', 'public'));
      await setDoc(doc(db, 'capsules/carolFarPublic'), capsule('carol', 'public', 60));
      await setDoc(doc(db, 'capsules/alicePrivate'), capsule('alice', 'private'));
    }),
  );

  test('create: own, valid, server time', async () => {
    const db = as('alice');
    const fresh = { ...capsule('alice', 'friends'), createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db, 'capsules/new1'), fresh));
    await assertFails(setDoc(doc(db, 'capsules/new2'), { ...fresh, ownerId: 'bob' }));
    await assertFails(setDoc(doc(db, 'capsules/new3'), { ...fresh, createdAt: Timestamp.now() }));
    await assertFails(setDoc(doc(db, 'capsules/new4'), { ...fresh, privacy: 'everyone' }));
    await assertFails(setDoc(doc(db, 'capsules/new5'), { ...fresh, title: '' }));
  });

  test('visibility: own, friends-only of friends, public; never others\' private', async () => {
    const db = as('alice');
    await assertSucceeds(getDoc(doc(db, 'capsules/alicePrivate')));
    await assertSucceeds(getDoc(doc(db, 'capsules/bobFriends')));
    await assertSucceeds(getDoc(doc(db, 'capsules/carolPublic')));
    await assertFails(getDoc(doc(db, 'capsules/bobPrivate')));
    await assertFails(getDoc(doc(db, 'capsules/carolFriends')));
    await assertSucceeds(getDoc(doc(db, 'capsules/doesNotExist')));
  });

  test('the three map queries and the history query are allowed', async () => {
    const db = as('alice');
    const own = await assertSucceeds(
      getDocs(query(collection(db, 'capsules'), where('ownerId', '==', 'alice'), orderBy('createdAt', 'desc'))),
    );
    assert.deepEqual(own.docs.map((d) => d.id), ['alicePrivate']);

    const friends = await assertSucceeds(
      getDocs(query(collection(db, 'capsules'), where('ownerId', 'in', ['bob']), where('privacy', '==', 'friends'))),
    );
    assert.deepEqual(friends.docs.map((d) => d.id), ['bobFriends']);

    // Not friends with carol: asking for her friends-only capsules fails.
    await assertFails(
      getDocs(query(collection(db, 'capsules'), where('ownerId', 'in', ['carol']), where('privacy', '==', 'friends'))),
    );
    // Unfiltered queries would include private capsules: refused.
    await assertFails(getDocs(collection(db, 'capsules')));
  });

  test('public capsules in a latitude band (GeoPoint range)', async () => {
    const db = as('alice');
    const band = await assertSucceeds(
      getDocs(
        query(
          collection(db, 'capsules'),
          where('privacy', '==', 'public'),
          where('location', '>=', new GeoPoint(35.4, -180)),
          where('location', '<=', new GeoPoint(39.4, 180)),
          limit(300),
        ),
      ),
    );
    assert.deepEqual(band.docs.map((d) => d.id), ['carolPublic']);
  });

  test('only the owner deletes; nobody updates', async () => {
    await assertFails(deleteDoc(doc(as('alice'), 'capsules/bobFriends')));
    await assertSucceeds(deleteDoc(doc(as('bob'), 'capsules/bobFriends')));
    await assertFails(updateDoc(doc(as('carol'), 'capsules/carolPublic'), { title: 'X' }));
  });
});
