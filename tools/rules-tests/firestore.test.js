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
  increment,
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

  test('a few words about yourself, and the lower-case name for search', async () => {
    const alice = doc(as('alice'), 'users/alice');
    await assertSucceeds(updateDoc(alice, { about: 'Collecting sunsets' }));
    await assertFails(updateDoc(alice, { about: 'x'.repeat(101) }));
    await assertFails(updateDoc(alice, { about: 42 }));
    await assertFails(updateDoc(doc(as('carol'), 'users/alice'), { about: 'hi' }));
    await assertSucceeds(updateDoc(alice, { name: 'Alice Walker', nameLower: 'alice walker' }));
    await assertFails(updateDoc(alice, { nameLower: 'someone else' }));
    // An old app renames without it; the index lags but the rename works.
    await assertSucceeds(updateDoc(alice, { name: 'Ally' }));
    await assertSucceeds(updateDoc(alice, { nameLower: deleteField() }));
    const found = await assertSucceeds(
      getDocs(query(collection(as('bob'), 'users'), where('nameLower', '>=', 'al'), where('nameLower', '<', 'al\uf8ff'), limit(20))),
    );
    assert.equal(found.size, 0, 'removed from the name index');
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

  test('co-authors: friends of the owner, up to five; they see it and may leave it', async () => {
    const db = as('alice');
    const fresh = (coAuthors, privacy = 'private') => ({
      ...capsule('alice', privacy),
      createdAt: serverTimestamp(),
      coAuthors,
    });
    await assertSucceeds(setDoc(doc(db, 'capsules/co1'), fresh(['bob'])));
    await assertFails(setDoc(doc(db, 'capsules/co2'), fresh(['carol'])), 'not a friend');
    await assertFails(setDoc(doc(db, 'capsules/co3'), fresh(['alice'])));
    await assertFails(setDoc(doc(db, 'capsules/co4'), fresh(['bob', 'bob'])));
    await assertFails(setDoc(doc(db, 'capsules/co5'), fresh(['bob', 'b2', 'b3', 'b4', 'b5', 'b6'])));
    await assertFails(setDoc(doc(db, 'capsules/co6'), fresh('bob')));
    // Bob sees Alice's private capsule because he is a co-author; Carol does not.
    await assertSucceeds(getDoc(doc(as('bob'), 'capsules/co1')));
    await assertFails(getDoc(doc(as('carol'), 'capsules/co1')));
    const mine = await assertSucceeds(
      getDocs(query(collection(as('bob'), 'capsules'), where('coAuthors', 'array-contains', 'bob'))),
    );
    assert.deepEqual(mine.docs.map((d) => d.id), ['co1']);
    // Only taking yourself off; nothing else changes.
    await assertFails(updateDoc(doc(as('bob'), 'capsules/co1'), { title: 'Mine now' }));
    await assertFails(updateDoc(doc(as('alice'), 'capsules/co1'), { coAuthors: [] }));
    await assertSucceeds(updateDoc(doc(as('bob'), 'capsules/co1'), { coAuthors: [] }));
    await assertFails(getDoc(doc(as('bob'), 'capsules/co1')));
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

describe('blocking', () => {
  test('only you block; only you and the blocked user see it', async () => {
    const block = { blockedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as('alice'), 'users/alice/blocked/carol'), block));
    await assertFails(setDoc(doc(as('carol'), 'users/alice/blocked/bob'), block));
    await assertFails(setDoc(doc(as('alice'), 'users/alice/blocked/alice'), block));
    await assertFails(setDoc(doc(as('alice'), 'users/alice/blocked/bob'), { blockedAt: Timestamp.now() }));

    await assertSucceeds(getDoc(doc(as('carol'), 'users/alice/blocked/carol')));
    await assertFails(getDoc(doc(as('bob'), 'users/alice/blocked/carol')));
    await assertSucceeds(getDocs(collection(as('alice'), 'users/alice/blocked')));
    await assertFails(getDocs(collection(as('carol'), 'users/alice/blocked')));

    await assertFails(deleteDoc(doc(as('carol'), 'users/alice/blocked/carol')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'users/alice/blocked/carol')));
  });

  test("main's blockedUsers array may only be removed", async () => {
    await seed((db) => updateDoc(doc(db, 'users/alice'), { blockedUsers: ['carol'] }));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { blockedUsers: ['carol', 'bob'] }));
    await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'), { blockedUsers: deleteField() }));
  });
});

describe('chats', () => {
  const chatRef = (db, id = 'alice_bob') => doc(db, `chats/${id}`);

  /**
   * What the app does: one transaction writing the summary (with +1 unread
   * for the recipient) and the message. `legacy` sends like main's app did,
   * without unread counts.
   */
  function send(db, from, to, extra = {}, chatId = [from, to].sort().join('_'), { legacy = false } = {}) {
    const ref = chatRef(db, chatId);
    const message = doc(collection(ref, 'messages'));
    return runTransaction(db, async (tx) => {
      const chat = await tx.get(ref);
      const summary = { lastMessage: extra.text ?? 'hi', lastUpdated: serverTimestamp(), lastSenderId: from };
      if (chat.exists()) {
        const unread = (chat.data().unreadCounts || {})[to] || 0;
        tx.update(ref, legacy ? summary : { ...summary, [`unreadCounts.${to}`]: unread + 1 });
      } else {
        tx.set(ref, {
          participants: [from, to],
          createdAt: serverTimestamp(),
          ...(legacy ? {} : { unreadCounts: { [to]: 1 } }),
          ...summary,
        });
      }
      tx.set(message, { senderId: from, text: 'hi', timestamp: serverTimestamp(), status: 'sent', ...extra });
    });
  }

  async function unreadOf(uid) {
    let data;
    await env.withSecurityRulesDisabled(async (ctx) => {
      data = (await getDoc(doc(ctx.firestore(), 'chats/alice_bob'))).data();
    });
    return (data.unreadCounts || {})[uid];
  }

  test('unread counts: +1 for the recipient per message, reset by the reader only', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    assert.equal(await unreadOf('bob'), 2);

    const alice = as('alice');
    // Inflating or touching your own count while sending is refused.
    await assertFails(
      updateDoc(chatRef(alice), { lastMessage: 'x', lastUpdated: serverTimestamp(), lastSenderId: 'alice', 'unreadCounts.bob': 5 }),
    );
    await assertFails(
      updateDoc(chatRef(alice), { lastMessage: 'x', lastUpdated: serverTimestamp(), lastSenderId: 'alice', 'unreadCounts.alice': 1 }),
    );
    // Only the reader resets their own count, and the receipt is server time.
    await assertFails(updateDoc(chatRef(alice), { 'unreadCounts.bob': 0 }));
    await assertFails(updateDoc(chatRef(as('bob')), { 'unreadCounts.bob': 0, 'lastReadAt.bob': Timestamp.now() }));
    await assertFails(updateDoc(chatRef(as('bob')), { 'lastReadAt.alice': serverTimestamp() }));
    await assertSucceeds(updateDoc(chatRef(as('bob')), { 'unreadCounts.bob': 0, 'lastReadAt.bob': serverTimestamp() }));
    assert.equal(await unreadOf('bob'), 0);
    // A new chat starts with exactly one unread message for the recipient.
    await assertFails(
      setDoc(chatRef(as('carol'), 'bob_carol'), {
        participants: ['carol', 'bob'], createdAt: serverTimestamp(), lastMessage: 'hi',
        lastUpdated: serverTimestamp(), lastSenderId: 'carol', unreadCounts: { bob: 3 },
      }),
    );
  });

  test('in a chat that exists, a message and +1 unread go as one batched write (works offline)', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    const batched = (db, from, to, unread = increment(1), id = 'q1') => {
      const batch = writeBatch(db);
      batch.update(chatRef(db), {
        lastMessage: 'queued',
        lastUpdated: serverTimestamp(),
        lastSenderId: from,
        [`unreadCounts.${to}`]: unread,
      });
      batch.set(doc(db, `chats/alice_bob/messages/${id}`), {
        senderId: from, text: 'queued', timestamp: serverTimestamp(), status: 'sent',
      });
      return batch.commit();
    };
    await assertSucceeds(batched(as('alice'), 'alice', 'bob'));
    assert.equal(await unreadOf('bob'), 2);
    await assertSucceeds(batched(as('bob'), 'bob', 'alice', increment(1), 'q2'));
    assert.equal(await unreadOf('alice'), 1);
    // Still exactly one more, never two; never your own count.
    await assertFails(batched(as('alice'), 'alice', 'bob', increment(2), 'q3'));
    await assertFails(batched(as('alice'), 'alice', 'alice', increment(1), 'q4'));
    // A message id that exists cannot be written again.
    await assertFails(batched(as('alice'), 'alice', 'bob', increment(1), 'q1'));
  });

  test('typing hints: your own, server time only, read by the other participant', async () => {
    const hint = (db, uid, chatId = 'alice_bob') => doc(db, `chats/${chatId}/typing/${uid}`);
    await assertSucceeds(setDoc(hint(as('alice'), 'alice'), { at: serverTimestamp() }));
    await assertSucceeds(setDoc(hint(as('alice'), 'alice'), { at: serverTimestamp() }));
    await assertSucceeds(getDoc(hint(as('bob'), 'alice')));
    await assertFails(getDoc(hint(as('carol'), 'alice')));
    // Not for someone else, not a made-up time, nothing else in it.
    await assertFails(setDoc(hint(as('bob'), 'alice'), { at: serverTimestamp() }));
    await assertFails(setDoc(hint(as('alice'), 'alice'), { at: Timestamp.now() }));
    await assertFails(setDoc(hint(as('alice'), 'alice'), { at: serverTimestamp(), text: 'hi' }));
    await assertFails(setDoc(hint(as('carol'), 'carol', 'alice_bob'), { at: serverTimestamp() }));
    await assertFails(deleteDoc(hint(as('bob'), 'alice')));
    await assertSucceeds(deleteDoc(hint(as('alice'), 'alice')));
  });

  test("taking back an unread message drops the other's count by exactly one", async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    assert.equal(await unreadOf('bob'), 2);
    const alice = as('alice');
    await assertSucceeds(updateDoc(chatRef(alice), { 'unreadCounts.bob': increment(-1) }));
    assert.equal(await unreadOf('bob'), 1);
    await assertFails(updateDoc(chatRef(alice), { 'unreadCounts.bob': increment(-2) }));
    await assertFails(updateDoc(chatRef(alice), { 'unreadCounts.alice': increment(-1) }));
    await assertSucceeds(updateDoc(chatRef(alice), { 'unreadCounts.bob': increment(-1) }));
    // Never below zero.
    await assertFails(updateDoc(chatRef(alice), { 'unreadCounts.bob': increment(-1) }));
  });

  test('deleting the newest message puts the one before it back in the summary', async () => {
    await assertSucceeds(send(as('bob'), 'bob', 'alice', { text: 'from bob' }));
    await assertSucceeds(send(as('alice'), 'alice', 'bob', { text: 'oops' }));
    const alice = as('alice');
    const earlier = Timestamp.fromMillis(Date.now() - 60000);
    // Back to Bob's message, with its own time; unread counts untouched.
    await assertSucceeds(
      updateDoc(chatRef(alice), { lastMessage: 'from bob', lastUpdated: earlier, lastSenderId: 'bob' }),
    );
    // Not a stranger as the sender, no future time, no empty text, no counts
    // other than one fewer for the other (see the next test).
    await assertFails(updateDoc(chatRef(alice), { lastMessage: 'x', lastUpdated: earlier, lastSenderId: 'carol' }));
    await assertFails(
      updateDoc(chatRef(alice), {
        lastMessage: 'x', lastUpdated: Timestamp.fromMillis(Date.now() + 3600000), lastSenderId: 'bob',
      }),
    );
    await assertFails(updateDoc(chatRef(alice), { lastMessage: '', lastUpdated: earlier, lastSenderId: 'bob' }));
    await assertFails(
      updateDoc(chatRef(alice), { lastMessage: 'x', lastUpdated: earlier, lastSenderId: 'bob', 'unreadCounts.bob': 5 }),
    );
    await assertFails(updateDoc(chatRef(as('carol')), { lastMessage: 'x', lastUpdated: earlier, lastSenderId: 'bob' }));
  });

  test('each participant reacts to a message with one emoji of their own', async () => {
    await assertSucceeds(send(as('bob'), 'bob', 'alice', { text: 'look' }));
    let id;
    await env.withSecurityRulesDisabled(async (ctx) => {
      id = (await getDocs(collection(ctx.firestore(), 'chats/alice_bob/messages'))).docs[0].id;
    });
    const msg = (db) => doc(db, `chats/alice_bob/messages/${id}`);
    // On a friend's message and on your own.
    await assertSucceeds(updateDoc(msg(as('alice')), { 'reactions.alice': 'heart' }));
    await assertSucceeds(updateDoc(msg(as('bob')), { 'reactions.bob': 'fire' }));
    await assertSucceeds(updateDoc(msg(as('alice')), { 'reactions.alice': 'laugh' }));
    await assertSucceeds(updateDoc(msg(as('alice')), { 'reactions.alice': deleteField() }));
    // Not someone else's, not an unknown emoji, not other fields, not outsiders.
    await assertFails(updateDoc(msg(as('alice')), { 'reactions.bob': 'sad' }));
    await assertFails(updateDoc(msg(as('alice')), { 'reactions.alice': 'poop' }));
    await assertFails(updateDoc(msg(as('alice')), { 'reactions.alice': 'wow', text: 'edited' }));
    await assertFails(updateDoc(msg(as('carol')), { 'reactions.carol': 'wow' }));
  });

  test('a reply quotes a message of the chat, briefly', async () => {
    await assertSucceeds(send(as('bob'), 'bob', 'alice', { text: 'question?' }));
    const quote = { id: 'm1', senderId: 'bob', text: 'question?' };
    await assertSucceeds(send(as('alice'), 'alice', 'bob', { text: 'answer', replyTo: quote }));
    // Only participants can be quoted; the quote is short and has no extras.
    await assertFails(send(as('alice'), 'alice', 'bob', { replyTo: { ...quote, senderId: 'carol' } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { replyTo: { ...quote, text: 'x'.repeat(201) } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { replyTo: { ...quote, extra: 1 } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { replyTo: { ...quote, id: '' } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { replyTo: 'm1' }));
  });

  test('a photo message points at a file of this chat sent by its sender', async () => {
    const photo = (who, extra = {}) => ({
      type: 'image',
      text: '📷',
      imageUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/p?alt=media&token=t',
      imagePath: `chats/alice_bob/${who}/m1.jpg`,
      width: 1200,
      height: 1600,
      ...extra,
    });
    await assertSucceeds(send(as('alice'), 'alice', 'bob', photo('alice')));
    await assertSucceeds(send(as('bob'), 'bob', 'alice', photo('bob', { text: 'Look!' })));
    // Size is optional (older drafts); the caption may be the camera sign.
    const { width, height, ...noSize } = photo('alice');
    await assertSucceeds(send(as('alice'), 'alice', 'bob', noSize));
    // Someone else's file, another chat's folder, odd names, no file at all.
    await assertFails(send(as('alice'), 'alice', 'bob', photo('bob')));
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { imagePath: 'chats/alice_carol/alice/m1.jpg' })));
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { imagePath: 'chats/alice_bob/alice/../x.jpg' })));
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { imagePath: 'chats/alice_bob/alice/m1.png' })));
    const { imagePath, ...noFile } = photo('alice');
    await assertFails(send(as('alice'), 'alice', 'bob', noFile));
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { imageUrl: 'x'.repeat(2049) })));
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { width: 0 })));
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { height: 20000 })));
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { width: '1200' })));
    // Still a message: the text cannot be empty.
    await assertFails(send(as('alice'), 'alice', 'bob', photo('alice', { text: '' })));
  });

  test('a voice message points at a recording of this chat by its sender', async () => {
    const voice = (who, extra = {}) => ({
      type: 'voice',
      text: '🎤',
      audioUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/v?alt=media&token=t',
      audioPath: `chats/alice_bob/${who}/v1.m4a`,
      durationMs: 4200,
      waveform: Array.from({ length: 40 }, (_, i) => i * 2),
      ...extra,
    });
    await assertSucceeds(send(as('alice'), 'alice', 'bob', voice('alice')));
    const { waveform, ...noBars } = voice('alice');
    await assertSucceeds(send(as('alice'), 'alice', 'bob', noBars));
    await assertFails(send(as('alice'), 'alice', 'bob', voice('bob')));
    await assertFails(send(as('alice'), 'alice', 'bob', voice('alice', { audioPath: 'chats/alice_bob/alice/v1.mp3' })));
    await assertFails(send(as('alice'), 'alice', 'bob', voice('alice', { durationMs: 0 })));
    await assertFails(send(as('alice'), 'alice', 'bob', voice('alice', { durationMs: 300001 })));
    await assertFails(send(as('alice'), 'alice', 'bob', voice('alice', { waveform: Array(65).fill(1) })));
    const { durationMs, ...noLength } = voice('alice');
    await assertFails(send(as('alice'), 'alice', 'bob', noLength));
  });

  test('a quick reply names the capsule it answers, briefly', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob', { text: 'Love it', capsuleRef: { id: 'c1', title: 'Sunset' } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: 'x', capsuleRef: { id: '', title: 'Sunset' } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: 'x', capsuleRef: { id: 'c1', title: 'x'.repeat(141) } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: 'x', capsuleRef: { id: 'c1', title: 't', imageUrl: 'u' } }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: 'x', capsuleRef: 'c1' }));
  });

  test('a forwarded message says so, and nothing else', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob', { text: 'fwd', forwarded: true }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: 'fwd', forwarded: false }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: 'fwd', forwarded: 'yes' }));
  });

  test("sending like main's app (no unread counts) is still allowed", async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob', {}, undefined, { legacy: true }));
    await assertSucceeds(send(as('bob'), 'bob', 'alice', {}, undefined, { legacy: true }));
  });

  test('participants start a chat and both write to it', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    await assertSucceeds(send(as('bob'), 'bob', 'alice'));
    const messages = await assertSucceeds(
      getDocs(query(collection(as('bob'), 'chats/alice_bob/messages'), orderBy('timestamp'))),
    );
    assert.equal(messages.size, 2);
  });

  test('outsiders, wrong ids and fake senders are refused', async () => {
    await assertFails(send(as('carol'), 'alice', 'bob'));
    await assertFails(send(as('alice'), 'alice', 'bob', {}, 'bob_alice'));
    await assertFails(send(as('alice'), 'alice', 'alice', {}, 'alice_alice'));
    await assertFails(send(as('alice'), 'alice', 'bob', { senderId: 'bob' }));
    await assertFails(send(as('alice'), 'alice', 'bob', { status: 'read' }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: '' }));
    await assertFails(send(as('alice'), 'alice', 'bob', { text: 'x'.repeat(2001) }));
    await assertFails(send(as('alice'), 'alice', 'bob', { extra: true }));

    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    await assertFails(getDoc(chatRef(as('carol'))));
    await assertFails(getDocs(collection(as('carol'), 'chats/alice_bob/messages')));
  });

  test("main's chat documents keep working", async () => {
    // Written by the app on main: participants unsorted, no lastSenderId.
    await seed((db) =>
      setDoc(doc(db, 'chats/alice_bob'), {
        participants: ['bob', 'alice'],
        lastMessage: 'old',
        lastUpdated: Timestamp.now(),
        createdAt: Timestamp.now(),
      }),
    );
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
  });

  test('the chat list query is allowed only for yourself', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    const mine = await assertSucceeds(
      getDocs(
        query(
          collection(as('bob'), 'chats'),
          where('participants', 'array-contains', 'bob'),
          orderBy('lastUpdated', 'desc'),
          limit(200),
        ),
      ),
    );
    assert.deepEqual(mine.docs.map((d) => d.id), ['alice_bob']);
    await assertFails(getDocs(query(collection(as('carol'), 'chats'), where('participants', 'array-contains', 'bob'))));
    await assertFails(getDocs(collection(as('carol'), 'chats')));
  });

  test('only the recipient marks messages read', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    const [m] = (await getDocs(collection(as('alice'), 'chats/alice_bob/messages'))).docs;
    await assertFails(updateDoc(doc(as('alice'), m.ref.path), { status: 'read' }));
    await assertFails(updateDoc(doc(as('bob'), m.ref.path), { text: 'edited' }));
    await assertSucceeds(updateDoc(doc(as('bob'), m.ref.path), { status: 'read' }));
  });

  test('clear history: delete the messages, empty the summary', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    const db = as('bob');
    const messages = await getDocs(collection(db, 'chats/alice_bob/messages'));
    const batch = writeBatch(db);
    messages.docs.forEach((d) => batch.delete(d.ref));
    await assertSucceeds(batch.commit());
    // Bob clears although Alice sent the last message; both counts go too.
    await assertFails(updateDoc(chatRef(db), { lastMessage: '', lastUpdated: serverTimestamp(), unreadCounts: { alice: 4 } }));
    await assertSucceeds(updateDoc(chatRef(db), { lastMessage: '', lastUpdated: serverTimestamp(), unreadCounts: {} }));
    await assertSucceeds(updateDoc(chatRef(db), { lastMessage: '', lastUpdated: serverTimestamp() }));
    await assertFails(updateDoc(chatRef(db), { participants: ['bob', 'carol'] }));
    await assertFails(deleteDoc(chatRef(db)));
  });

  test('nobody writes to someone who blocked them, or whom they blocked', async () => {
    await assertSucceeds(send(as('alice'), 'alice', 'bob'));
    await seed((db) => setDoc(doc(db, 'users/bob/blocked/alice'), { blockedAt: Timestamp.now() }));
    await assertFails(send(as('alice'), 'alice', 'bob'));
    await assertFails(send(as('bob'), 'bob', 'alice'));
    // Reading and clearing still work.
    await assertSucceeds(getDocs(collection(as('alice'), 'chats/alice_bob/messages')));
    await assertSucceeds(updateDoc(chatRef(as('alice')), { lastMessage: '', lastUpdated: serverTimestamp() }));
  });

  test('a capsule sent to a friend: shared with them, posted to the chat', async () => {
    const capsule = {
      ownerId: 'alice',
      imageUrl: 'https://img',
      title: 'For Bob',
      description: null,
      location: new GeoPoint(1, 2),
      privacy: 'private',
      createdAt: serverTimestamp(),
      isScheduled: false,
      openAt: null,
      color: 'red',
      sharedWith: ['alice', 'bob'],
    };
    const alice = as('alice');
    await assertFails(setDoc(doc(alice, 'capsules/bad1'), { ...capsule, sharedWith: ['bob', 'alice'] }));
    await assertFails(setDoc(doc(alice, 'capsules/bad2'), { ...capsule, sharedWith: ['alice', 'bob', 'carol'] }));
    await assertFails(setDoc(doc(alice, 'capsules/bad3'), { ...capsule, sharedWith: ['alice', 'alice'] }));
    await assertSucceeds(setDoc(doc(alice, 'capsules/gift'), capsule));

    // The recipient sees the private capsule; others do not.
    await assertSucceeds(getDoc(doc(as('bob'), 'capsules/gift')));
    await assertFails(getDoc(doc(as('carol'), 'capsules/gift')));

    const msg = { text: 'For Bob', type: 'capsule', capsuleId: 'gift', imageUrl: 'https://img' };
    await assertSucceeds(send(alice, 'alice', 'bob', msg));
    // Someone else's capsule, or one not shared with this chat, is refused.
    await seed((db) =>
      setDoc(doc(db, 'capsules/carols'), {
        ...capsule,
        ownerId: 'carol',
        createdAt: Timestamp.now(),
        sharedWith: ['carol', 'bob'],
      }),
    );
    await assertFails(send(as('bob'), 'bob', 'alice', { ...msg, capsuleId: 'carols' }));
    await assertFails(send(as('carol'), 'carol', 'alice', { ...msg, capsuleId: 'carols' }, 'alice_carol'));
    await assertFails(send(alice, 'alice', 'bob', { ...msg, capsuleId: 'missing' }));
  });
});

describe('suggestions from contacts', () => {
  const hashes = [
    'a'.repeat(64),
    'b'.repeat(64),
  ];

  test('nobody reads or writes the index from the app', async () => {
    await assertFails(getDoc(doc(as('alice'), `contactIndex/${hashes[0]}`)));
    await assertFails(setDoc(doc(as('alice'), `contactIndex/${hashes[0]}`), { uid: 'alice' }));
  });

  test('a request of your own, at most once an hour; only you read the answer', async () => {
    const mine = doc(as('alice'), 'contactMatches/alice');
    const ask = { hashes, at: serverTimestamp(), status: 'pending' };
    await assertSucceeds(setDoc(mine, ask));
    await assertSucceeds(getDoc(mine));
    await assertFails(getDoc(doc(as('bob'), 'contactMatches/alice')));
    await assertFails(setDoc(doc(as('bob'), 'contactMatches/alice'), ask));
    await assertFails(setDoc(mine, ask), 'again within the hour');
    await assertFails(setDoc(doc(as('bob'), 'contactMatches/bob'), { ...ask, status: 'done', matches: ['x'] }));
    await assertFails(
      setDoc(doc(as('bob'), 'contactMatches/bob'), { ...ask, hashes: Array.from({ length: 1001 }, () => hashes[0]) }),
    );
    // An hour later it may ask again.
    await seed((db) => setDoc(doc(db, 'contactMatches/carol'), { at: new Date(Date.now() - 2 * 3600 * 1000), status: 'done', matches: [] }));
    await assertSucceeds(setDoc(doc(as('carol'), 'contactMatches/carol'), ask));
    await assertSucceeds(deleteDoc(mine));
  });
});

describe('capsules viewed (B7)', () => {
  const mark = (db, uid, id) => doc(db, `users/${uid}/viewed/${id}`);

  test('the owner writes each marker once, with the server time', async () => {
    const alice = as('alice');
    await assertSucceeds(setDoc(mark(alice, 'alice', 'c1'), { at: serverTimestamp() }));
    // Seen before: refused (the function counted it already).
    await assertFails(setDoc(mark(alice, 'alice', 'c1'), { at: serverTimestamp() }));
    await assertFails(deleteDoc(mark(alice, 'alice', 'c1')));
    await assertFails(setDoc(mark(alice, 'alice', 'c2'), { at: serverTimestamp(), counted: true }));
    await assertFails(setDoc(mark(alice, 'alice', 'c3'), { at: new Date(2020, 1, 1) }));
    await assertFails(setDoc(mark(as('bob'), 'alice', 'c4'), { at: serverTimestamp() }));
    await assertSucceeds(getDoc(mark(alice, 'alice', 'c1')));
    await assertFails(getDoc(mark(as('bob'), 'alice', 'c1')));
  });
});

describe('settings', () => {
  const settingsRef = (db, uid = 'alice') => doc(db, `users/${uid}/settings/app`);
  const valid = {
    notifications: {
      enabled: true,
      messages: false,
      follows: true,
      capsules: true,
      preview: false,
      sound: true,
      quietHours: { enabled: true, start: 1320, end: 420 },
      utcOffsetMinutes: 120,
    },
  };

  test('only the owner reads and writes, as the app does', async () => {
    const alice = as('alice');
    await assertSucceeds(setDoc(settingsRef(alice), valid, { merge: true }));
    await assertSucceeds(setDoc(settingsRef(alice), { mutedChats: arrayUnion('alice_bob') }, { merge: true }));
    // Pinned chats: a short list.
    await assertSucceeds(setDoc(settingsRef(alice), { pinnedChats: arrayUnion('alice_bob') }, { merge: true }));
    await assertFails(setDoc(settingsRef(alice), { pinnedChats: Array.from({ length: 11 }, (_, i) => `c${i}`) }, { merge: true }));
    await assertFails(setDoc(settingsRef(alice), { pinnedChats: 'alice_bob' }, { merge: true }));
    // Pinned friends on the profile: a short list, on every phone.
    await assertSucceeds(setDoc(settingsRef(alice), { pinnedFriends: ['bob', 'carol'] }, { merge: true }));
    await assertFails(setDoc(settingsRef(alice), { pinnedFriends: Array.from({ length: 11 }, (_, i) => `u${i}`) }, { merge: true }));
    // Found by name, or not.
    await assertSucceeds(setDoc(settingsRef(alice), { privacy: { findByName: false } }, { merge: true }));
    await assertFails(setDoc(settingsRef(alice), { privacy: { findByName: 'no' } }, { merge: true }));
    await assertSucceeds(setDoc(settingsRef(alice), { privacy: { findByContacts: true } }, { merge: true }));
    await assertSucceeds(getDoc(settingsRef(alice)));
    await assertFails(getDoc(settingsRef(as('bob'), 'alice')));
    await assertFails(setDoc(settingsRef(as('bob'), 'alice'), valid));
    await assertFails(deleteDoc(settingsRef(alice)));
    await assertFails(setDoc(doc(alice, 'users/alice/settings/other'), valid));
  });

  test('values are validated', async () => {
    const alice = as('alice');
    const n = valid.notifications;
    await assertFails(setDoc(settingsRef(alice), { notifications: { ...n, enabled: 'yes' } }));
    await assertFails(setDoc(settingsRef(alice), { notifications: { ...n, quietHours: { enabled: true, start: 2000, end: 0 } } }));
    await assertFails(setDoc(settingsRef(alice), { notifications: { ...n, utcOffsetMinutes: 5000 } }));
    await assertFails(setDoc(settingsRef(alice), { notifications: { ...n, extra: true } }));
    // Vibration (B6): a switch; missing means on.
    await assertSucceeds(setDoc(settingsRef(alice), { notifications: { ...n, vibrate: false } }));
    await assertFails(setDoc(settingsRef(alice), { notifications: { ...n, vibrate: 'off' } }));
    await assertFails(setDoc(settingsRef(alice), { ...valid, isAdmin: true }));
    await assertFails(setDoc(settingsRef(alice), { mutedChats: 'alice_bob' }));
  });
});

describe('social and gamification (night session)', () => {
  const capsule = (owner, privacy, extra = {}) => ({
    ownerId: owner,
    imageUrl: 'https://img',
    title: 'T',
    location: new GeoPoint(46.5, 8.1),
    privacy,
    createdAt: Timestamp.now(),
    color: 'red',
    ...extra,
  });

  beforeEach(() =>
    seed(async (db) => {
      await setDoc(doc(db, 'capsules/bobFriends'), capsule('bob', 'friends'));
      await setDoc(doc(db, 'capsules/bobPrivate'), capsule('bob', 'private'));
      await setDoc(doc(db, 'capsules/carolPublic'), capsule('carol', 'public'));
      await setDoc(doc(db, 'capsules/carolQuiet'), capsule('carol', 'public', { allowComments: false, allowReactions: false }));
      await setDoc(doc(db, 'capsules/bobFriends/comments/top'), { authorId: 'bob', text: 'hi', createdAt: Timestamp.now() });
      await setDoc(doc(db, 'capsules/bobFriends/comments/reply'), { authorId: 'alice', text: 'yo', createdAt: Timestamp.now(), replyTo: 'top' });
      await setDoc(doc(db, 'users/bob/achievements/first_capsule'), { id: 'first_capsule', tier: 0 });
      await setDoc(doc(db, 'users/bob/private/gamification'), { cells: ['u33dc'] });
      await setDoc(doc(db, 'announcements/a1'), { title: { en: 'Hi' } });
    }),
  );

  test('counters, stats and the verified badge are server-only', async () => {
    const alice = as('alice');
    for (const field of [
      { verified: true },
      { followerCount: 1000 },
      { followingCount: 3 },
      { stats: { capsules: 999 } },
    ]) {
      await assertFails(updateDoc(doc(alice, 'users/alice'), field));
    }
    await assertSucceeds(updateDoc(doc(alice, 'users/alice'), { showAchievements: false }));
    await assertFails(updateDoc(doc(alice, 'users/alice'), { showAchievements: 'no' }));
  });

  test('achievements: the owner and friends read them, nobody writes', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'users/bob/achievements/first_capsule')));
    await assertSucceeds(getDoc(doc(as('alice'), 'users/bob/achievements/first_capsule')));
    await assertFails(getDoc(doc(as('carol'), 'users/bob/achievements/first_capsule')));
    await assertFails(setDoc(doc(as('bob'), 'users/bob/achievements/x'), { tier: 9 }));
    await seed((db) => updateDoc(doc(db, 'users/bob'), { showAchievements: false }));
    await assertFails(getDoc(doc(as('alice'), 'users/bob/achievements/first_capsule')));
  });

  test('private stats: owner reads, nobody writes', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'users/bob/private/gamification')));
    await assertFails(getDoc(doc(as('alice'), 'users/bob/private/gamification')));
    await assertFails(setDoc(doc(as('bob'), 'users/bob/private/gamification'), { cells: [] }));
  });

  test('settings: language, new categories and privacy are validated', async () => {
    const ref = doc(as('alice'), 'users/alice/settings/app');
    await assertSucceeds(setDoc(ref, {
      language: 'pl',
      notifications: { reactions: false, comments: true, friendRequests: true, achievements: true, news: false, streakReminder: true },
      privacy: { defaultVisibility: 'friends', readReceipts: false, locationPrecision: 'approximate', contactSuggestions: false },
    }));
    await assertFails(setDoc(ref, { language: 'fr' }));
    await assertFails(setDoc(ref, { notifications: { reactions: 'yes' } }));
    await assertFails(setDoc(ref, { privacy: { defaultVisibility: 'everyone' } }));
    await assertFails(setDoc(ref, { privacy: { tracking: true } }));
  });

  test('capsules: new optional fields; no 0,0; no future capture', async () => {
    const db = as('alice');
    const fresh = (extra) => ({ ...capsule('alice', 'public'), createdAt: serverTimestamp(), ...extra });
    await assertSucceeds(setDoc(doc(db, 'capsules/a1'), fresh({
      capturedAt: Timestamp.fromMillis(Date.now() - 3600 * 1000),
      utcOffsetMinutes: 120,
      showAuthor: false,
      allowComments: false,
      allowReactions: true,
      locationPrecision: 'approximate',
      frames: ['https://f1', 'https://f2'],
      frameDelayMs: 250,
      thumbUrl: 'https://thumb',
      placeName: 'Grindelwald',
    })));
    await assertFails(setDoc(doc(db, 'capsules/a2'), fresh({ location: new GeoPoint(0, 0) })));
    await assertFails(setDoc(doc(db, 'capsules/a3'), fresh({ capturedAt: Timestamp.fromMillis(Date.now() + 3600 * 1000) })));
    await assertFails(setDoc(doc(db, 'capsules/a4'), fresh({ frames: Array(11).fill('https://f') })));
    await assertFails(setDoc(doc(db, 'capsules/a5'), fresh({ locationPrecision: 'fuzzy' })));
  });

  test('reactions: whoever sees the capsule, as themselves, allowed types only', async () => {
    const react = (uid, path, type = 'heart', extra = {}) =>
      setDoc(doc(as(uid), path), { type, uid, updatedAt: serverTimestamp(), ...extra });
    await assertSucceeds(react('alice', 'capsules/bobFriends/reactions/alice')); // friend
    await assertSucceeds(react('alice', 'capsules/bobFriends/reactions/alice', 'fire')); // change
    await assertSucceeds(react('alice', 'capsules/carolPublic/reactions/alice')); // public
    await assertFails(react('carol', 'capsules/bobFriends/reactions/carol')); // not a friend
    await assertFails(react('alice', 'capsules/bobPrivate/reactions/alice')); // private
    await assertFails(react('alice', 'capsules/carolPublic/reactions/bob')); // as someone else
    await assertFails(react('alice', 'capsules/carolPublic/reactions/alice', 'poop'));
    await assertFails(react('alice', 'capsules/carolQuiet/reactions/alice')); // reactions off
    await assertSucceeds(getDoc(doc(as('carol'), 'capsules/carolPublic/reactions/alice')));
    await assertFails(getDoc(doc(as('carol'), 'capsules/bobFriends/reactions/alice')));
    await assertFails(deleteDoc(doc(as('bob'), 'capsules/bobFriends/reactions/alice')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'capsules/bobFriends/reactions/alice')));
    // Blocked by the owner.
    await seed((db) => setDoc(doc(db, 'users/carol/blocked/alice'), { blockedAt: Timestamp.now() }));
    await assertFails(react('alice', 'capsules/carolPublic/reactions/alice', 'wow'));
  });

  test('comments: one level of replies, author or owner deletes, nobody edits', async () => {
    const comment = (uid, path, extra = {}) =>
      setDoc(doc(as(uid), path), { authorId: uid, text: 'Nice', createdAt: serverTimestamp(), ...extra });
    await assertSucceeds(comment('alice', 'capsules/bobFriends/comments/c1'));
    await assertSucceeds(comment('alice', 'capsules/bobFriends/comments/c2', { replyTo: 'top' }));
    await assertFails(comment('alice', 'capsules/bobFriends/comments/c3', { replyTo: 'reply' })); // reply to a reply
    await assertFails(comment('alice', 'capsules/bobFriends/comments/c4', { replyTo: 'missing' }));
    await assertFails(comment('alice', 'capsules/bobFriends/comments/c5', { text: 'x'.repeat(501) }));
    await assertFails(comment('alice', 'capsules/bobFriends/comments/c6', { authorId: 'bob' }));
    await assertFails(comment('carol', 'capsules/bobFriends/comments/c7')); // cannot see it
    await assertFails(comment('alice', 'capsules/carolQuiet/comments/c8')); // comments off
    await assertFails(updateDoc(doc(as('alice'), 'capsules/bobFriends/comments/c1'), { text: 'Edited' }));
    // On a public capsule, a third person who can see it still cannot delete.
    await assertSucceeds(comment('alice', 'capsules/carolPublic/comments/p1'));
    await assertFails(deleteDoc(doc(as('bob'), 'capsules/carolPublic/comments/p1')));
    await assertSucceeds(deleteDoc(doc(as('carol'), 'capsules/carolPublic/comments/p1'))); // owner
    await assertSucceeds(deleteDoc(doc(as('bob'), 'capsules/bobFriends/comments/c1'))); // owner
    await assertSucceeds(deleteDoc(doc(as('alice'), 'capsules/bobFriends/comments/c2'))); // author
  });

  test('reports are write-only; announcements read-only', async () => {
    const report = { reporterId: 'alice', targetType: 'comment', targetPath: 'capsules/x/comments/y', reason: 'abuse', createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as('alice'), 'reports/r1'), report));
    await assertFails(setDoc(doc(as('alice'), 'reports/r2'), { ...report, reporterId: 'bob' }));
    await assertFails(setDoc(doc(as('alice'), 'reports/r3'), { ...report, reason: 'boring' }));
    await assertFails(getDoc(doc(as('alice'), 'reports/r1')));
    await assertSucceeds(getDoc(doc(as('carol'), 'announcements/a1')));
    await assertFails(getDoc(doc(anon(), 'announcements/a1')));
    await assertFails(setDoc(doc(as('alice'), 'announcements/a2'), { title: { en: 'Fake' } }));
  });
});

describe('group chats', () => {
  const G = 'g_group1abcdef';
  const group = (db, id = G) => doc(db, `chats/${id}`);
  const newGroup = (by, members, extra = {}) => ({
    members,
    name: 'Trip',
    createdBy: by,
    createdAt: serverTimestamp(),
    lastMessage: '',
    lastUpdated: serverTimestamp(),
    ...extra,
  });
  /** A group of alice, bob and carol, the way the invite function leaves it. */
  const make = async () => {
    await assertSucceeds(setDoc(group(as('alice')), newGroup('alice', ['alice'])));
    await seed((db) => updateDoc(doc(db, `chats/${G}`), { members: ['alice', 'bob', 'carol'] }));
  };

  /** What the app does: the message and the summary in one batch. */
  function say(db, from, extra = {}, id = `m${Math.random().toString(36).slice(2, 8)}`) {
    const batch = writeBatch(db);
    batch.update(group(db), { lastMessage: extra.text ?? 'hi', lastUpdated: serverTimestamp(), lastSenderId: from });
    batch.set(doc(db, `chats/${G}/messages/${id}`), {
      senderId: from, text: 'hi', timestamp: serverTimestamp(), status: 'sent', ...extra,
    });
    return batch.commit();
  }

  test('a group starts with its creator alone and a name', async () => {
    const alice = as('alice');
    await assertSucceeds(setDoc(group(alice), newGroup('alice', ['alice'])));
    await assertFails(setDoc(group(alice, 'g_group2abcdef'), newGroup('bob', ['bob'])));
    await assertFails(setDoc(group(alice, 'g_group3abcdef'), newGroup('alice', ['alice', 'bob'])));
    await assertFails(setDoc(group(alice, 'g_group7abcdef'), newGroup('alice', ['alice'], { name: '' })));
    await assertFails(setDoc(group(alice, 'g_group8abcdef'), newGroup('alice', ['alice'], { lastMessage: 'x' })));
    await assertFails(setDoc(group(alice, 'g_group9abcdef'), newGroup('alice', ['alice'], { participants: ['alice', 'bob'] })));
    // Not a group id: the two-person rules apply.
    await assertFails(setDoc(group(alice, 'g_x'), newGroup('alice', ['alice'])));
  });

  test('members invite people; only the function adds them', async () => {
    await make();
    const invite = (db, uid) => doc(db, `chats/${G}/invites/${uid}`);
    await assertSucceeds(setDoc(invite(as('bob'), 'dave'), { by: 'bob', at: serverTimestamp() }));
    await assertFails(setDoc(invite(as('bob'), 'erin'), { by: 'carol', at: serverTimestamp() }));
    await assertFails(setDoc(invite(as('bob'), 'carol'), { by: 'bob', at: serverTimestamp() }));
    await assertFails(setDoc(invite(as('dave'), 'erin'), { by: 'dave', at: serverTimestamp() }));
    await assertFails(updateDoc(group(as('bob')), { members: ['alice', 'bob', 'carol', 'dave'] }));
    await assertFails(deleteDoc(invite(as('bob'), 'dave')));
  });

  test('members read and list it; others cannot; two-person queries do not see it', async () => {
    await make();
    await assertSucceeds(getDoc(group(as('bob'))));
    await assertFails(getDoc(group(as('dave'))));
    const mine = await assertSucceeds(
      getDocs(query(collection(as('bob'), 'chats'), where('members', 'array-contains', 'bob'), orderBy('lastUpdated', 'desc'), limit(100))),
    );
    assert.deepEqual(mine.docs.map((d) => d.id), [G]);
    const pairs = await assertSucceeds(
      getDocs(query(collection(as('bob'), 'chats'), where('participants', 'array-contains', 'bob'))),
    );
    assert.equal(pairs.size, 0);
    await assertFails(getDocs(query(collection(as('dave'), 'chats'), where('members', 'array-contains', 'bob'))));
  });

  test('members write text messages, quote each other, react, delete their own', async () => {
    await make();
    await assertSucceeds(say(as('bob'), 'bob', {}, 'b1'));
    await assertSucceeds(say(as('carol'), 'carol', { text: 'yes', replyTo: { id: 'b1', senderId: 'bob', text: 'hi' } }, 'c1'));
    await assertFails(say(as('carol'), 'carol', { replyTo: { id: 'x', senderId: 'dave', text: 'hi' } }));
    await assertFails(say(as('dave'), 'dave'));
    await assertFails(say(as('bob'), 'carol'));
    // Text only for now (photos and capsules need checks a group cannot do yet).
    await assertFails(say(as('bob'), 'bob', { type: 'capsule', capsuleId: 'c1' }));
    await assertFails(say(as('bob'), 'bob', { type: 'image', imageUrl: 'https://x', imagePath: `chats/${G}/bob/p.jpg` }));
    await assertSucceeds(getDocs(collection(as('alice'), `chats/${G}/messages`)));
    await assertFails(getDocs(collection(as('dave'), `chats/${G}/messages`)));

    await assertSucceeds(updateDoc(doc(as('alice'), `chats/${G}/messages/b1`), { 'reactions.alice': 'heart' }));
    await assertFails(updateDoc(doc(as('alice'), `chats/${G}/messages/b1`), { 'reactions.bob': 'heart' }));
    await assertFails(updateDoc(doc(as('alice'), `chats/${G}/messages/b1`), { status: 'read' }));
    await assertFails(deleteDoc(doc(as('alice'), `chats/${G}/messages/b1`)));
    await assertSucceeds(deleteDoc(doc(as('bob'), `chats/${G}/messages/b1`)));
    // Carol deletes her newest message: the summary goes back to Bob's.
    await assertSucceeds(deleteDoc(doc(as('carol'), `chats/${G}/messages/c1`)));
    await assertSucceeds(updateDoc(group(as('carol')), { lastMessage: 'hi', lastUpdated: Timestamp.now(), lastSenderId: 'bob' }));
    await assertFails(updateDoc(group(as('carol')), { lastMessage: 'hi', lastUpdated: Timestamp.now(), lastSenderId: 'dave' }));
  });

  test('read marks, renaming, adding and leaving', async () => {
    await make();
    const bob = as('bob');
    await assertSucceeds(updateDoc(group(bob), { 'lastReadAt.bob': serverTimestamp() }));
    await assertFails(updateDoc(group(bob), { 'lastReadAt.alice': serverTimestamp() }));
    await assertFails(updateDoc(group(bob), { 'lastReadAt.bob': Timestamp.now() }));
    await assertSucceeds(updateDoc(group(bob), { name: 'Trip 2026' }));
    await assertFails(updateDoc(group(bob), { name: '' }));
    await assertFails(updateDoc(group(as('dave')), { name: 'Mine' }));

    // Dropping someone else is not leaving.
    await assertFails(updateDoc(group(bob), { members: ['bob', 'carol'] }));
    await assertFails(updateDoc(group(bob), { createdBy: 'bob' }));

    // Bob leaves, his read mark with him; then he cannot read it.
    await assertSucceeds(updateDoc(group(bob), { members: ['alice', 'carol'], lastReadAt: {} }));
    await assertFails(getDoc(group(bob)));
    await assertFails(getDocs(collection(bob, `chats/${G}/messages`)));
  });

  test('typing hints in a group: members only, their own', async () => {
    await make();
    await assertSucceeds(setDoc(doc(as('bob'), `chats/${G}/typing/bob`), { at: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(as('carol'), `chats/${G}/typing/bob`)));
    await assertFails(setDoc(doc(as('dave'), `chats/${G}/typing/dave`), { at: serverTimestamp() }));
    await assertFails(setDoc(doc(as('bob'), `chats/${G}/typing/carol`), { at: serverTimestamp() }));
  });
});
