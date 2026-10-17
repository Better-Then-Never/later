// lib/social.js: follower counts, reactions, comments, friend requests.
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { GeoPoint } = require('firebase-admin/firestore');
const { ctx, fakeMessaging, users, addUser, setSettings } = require('./helpers');
const social = require('../lib/social');

const noon = () => new Date(Date.UTC(2026, 9, 16, 12, 0));
const services = (messaging = fakeMessaging()) => ({ db: ctx.db, messaging, now: noon });

async function addCapsule(id, ownerId, extra = {}) {
  await ctx.db.collection('capsules').doc(id).set({
    ownerId,
    title: 'Lake',
    privacy: 'public',
    location: new GeoPoint(46.5, 8.1),
    ...extra,
  });
}
const capsule = async (id) => (await ctx.db.collection('capsules').doc(id).get()).data();
const inbox = async (uid) =>
  (await users().doc(uid).collection('notifications').get()).docs.map((d) => ({ id: d.id, ...d.data() }));

describe('follower counts', () => {
  test('go up and down with the followers and following documents', async () => {
    await addUser('bob');
    const s = services();
    await social.onFollowerChanged(s, 'bob', 1);
    await social.onFollowerChanged(s, 'bob', 1);
    await social.onFollowerChanged(s, 'bob', -1);
    await social.onFollowingChanged(s, 'bob', 1);
    const bob = (await users().doc('bob').get()).data();
    assert.equal(bob.followerCount, 1);
    assert.equal(bob.followingCount, 1);
  });
});

describe('reactions', () => {
  test('a first reaction counts and notifies the owner once, in their language', async () => {
    await addUser('owner', {}, ['o1']);
    await addUser('fan', { name: 'Ana' });
    await setSettings('owner', { language: 'es' });
    await addCapsule('c1', 'owner');
    const messaging = fakeMessaging();
    await social.onReactionWritten(services(messaging), 'c1', 'fan', undefined, { type: 'heart', uid: 'fan' });
    let c = await capsule('c1');
    assert.equal(c.reactionCounts.heart, 1);
    assert.equal(c.reactionTotal, 1);
    assert.equal(messaging.sent.length, 1);
    assert.equal(messaging.sent[0].notification.body, 'Ana reaccionó ❤️ a tu cápsula');
    assert.deepEqual(messaging.sent[0].data.type, 'reaction');
    const notes = await inbox('owner');
    assert.equal(notes.length, 1);
    assert.equal(notes[0].id, 'reaction_c1_fan');
    assert.equal((await users().doc('owner').get()).get('stats.reactionsReceived'), 1);

    // Changing the emoji moves the count but does not notify again.
    await social.onReactionWritten(services(messaging), 'c1', 'fan', { type: 'heart' }, { type: 'fire' });
    c = await capsule('c1');
    assert.equal(c.reactionCounts.heart, 0);
    assert.equal(c.reactionCounts.fire, 1);
    assert.equal(c.reactionTotal, 1);
    assert.equal(messaging.sent.length, 1);

    // Removing it.
    await social.onReactionWritten(services(messaging), 'c1', 'fan', { type: 'fire' }, undefined);
    c = await capsule('c1');
    assert.equal(c.reactionCounts.fire, 0);
    assert.equal(c.reactionTotal, 0);
  });

  test('own reactions, blocked users and switched-off pushes', async () => {
    await addUser('owner', {}, ['o1']);
    await addUser('troll');
    await addCapsule('c1', 'owner');
    await users().doc('owner').collection('blocked').doc('troll').set({ blockedAt: new Date() });
    const messaging = fakeMessaging();
    await social.onReactionWritten(services(messaging), 'c1', 'owner', undefined, { type: 'heart' });
    await social.onReactionWritten(services(messaging), 'c1', 'troll', undefined, { type: 'heart' });
    assert.equal(messaging.sent.length, 0);
    assert.equal((await inbox('owner')).length, 0);
    assert.equal((await capsule('c1')).reactionTotal, 2);

    await addUser('quiet', {}, ['q1']);
    await setSettings('quiet', { notifications: { reactions: false } });
    await addCapsule('c2', 'quiet');
    const result = await social.onReactionWritten(services(messaging), 'c2', 'troll', undefined, { type: 'wow' });
    assert.deepEqual(result.notified, { skipped: 'reactions off' });
    assert.equal((await inbox('quiet')).length, 1, 'the in-app notification is still written');
  });

  test('unknown reaction types are ignored', async () => {
    await addUser('owner');
    await addCapsule('c1', 'owner');
    assert.equal(await social.onReactionWritten(services(), 'c1', 'x', undefined, { type: 'poop' }), null);
  });
});

describe('comments', () => {
  test('count, notify the owner, and the parent author of a reply', async () => {
    await addUser('owner', {}, ['o1']);
    await addUser('ana', {}, ['a1']);
    await addUser('ben', { name: 'Ben' });
    await addCapsule('c1', 'owner');
    const messaging = fakeMessaging();
    await ctx.db.doc('capsules/c1/comments/k1').set({ authorId: 'ana', text: 'Wow' });
    await social.onCommentCreated(services(messaging), 'c1', 'k1', { authorId: 'ana', text: 'Wow' });
    await ctx.db.doc('capsules/c1/comments/k2').set({ authorId: 'ben', text: 'Same!', replyTo: 'k1' });
    await social.onCommentCreated(services(messaging), 'c1', 'k2', { authorId: 'ben', text: 'Same!', replyTo: 'k1' });

    assert.equal((await capsule('c1')).commentCount, 2);
    const ownerNotes = await inbox('owner');
    assert.deepEqual(ownerNotes.map((n) => n.type).sort(), ['comment', 'comment']);
    const anaNotes = await inbox('ana');
    assert.equal(anaNotes.length, 1);
    assert.equal(anaNotes[0].type, 'reply');
    const replyPush = messaging.sent.find((m) => m.token === 'a1');
    assert.equal(replyPush.notification.title, 'New reply');
    assert.equal(replyPush.notification.body, 'Ben: Same!');
    assert.equal((await users().doc('ben').get()).get('stats.commentsWritten'), 1);

    await social.onCommentDeleted(services(), 'c1');
    assert.equal((await capsule('c1')).commentCount, 1);
  });

  test('the owner commenting on their own capsule notifies nobody', async () => {
    await addUser('owner', {}, ['o1']);
    await addCapsule('c1', 'owner');
    const messaging = fakeMessaging();
    await social.onCommentCreated(services(messaging), 'c1', 'k1', { authorId: 'owner', text: 'hi' });
    assert.equal(messaging.sent.length, 0);
    assert.equal((await capsule('c1')).commentCount, 1);
  });
});

describe('friend requests', () => {
  test('the receiver hears about a request, the sender about the acceptance', async () => {
    await addUser('ana', { name: 'Ana' }, ['a1']);
    await addUser('ben', { name: 'Ben' }, ['b1']);
    await setSettings('ben', { language: 'de' });
    const messaging = fakeMessaging();
    const request = { fromUserId: 'ana', toUserId: 'ben', status: 'pending' };
    await social.onFriendRequestCreated(services(messaging), 'ana_ben', request);
    assert.equal(messaging.sent[0].token, 'b1');
    assert.equal(messaging.sent[0].notification.body, 'Ana möchte mit dir befreundet sein');
    assert.equal((await inbox('ben'))[0].type, 'friendRequest');

    // Some other update (resent) does nothing.
    assert.equal(await social.onFriendRequestUpdated(services(messaging), 'ana_ben', request, request), null);

    await social.onFriendRequestUpdated(services(messaging), 'ana_ben', request, { ...request, status: 'accepted' });
    const accepted = messaging.sent.find((m) => m.token === 'a1');
    assert.equal(accepted.notification.body, 'Ben accepted your friend request');
    assert.equal((await users().doc('ana').get()).get('stats.friendsMade'), 1);
    assert.equal((await users().doc('ben').get()).get('stats.friendsMade'), 1);
  });

  test('a request from a blocked user is silent', async () => {
    await addUser('ana', {}, ['a1']);
    await addUser('ben', {}, ['b1']);
    await users().doc('ben').collection('blocked').doc('ana').set({ blockedAt: new Date() });
    const result = await social.onFriendRequestCreated(services(), 'ana_ben', {
      fromUserId: 'ana', toUserId: 'ben', status: 'pending',
    });
    assert.deepEqual(result, { skipped: 'blocked' });
  });
});
