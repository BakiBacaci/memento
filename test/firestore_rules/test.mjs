import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { doc, setDoc, getDoc, updateDoc, deleteDoc, writeBatch, increment, serverTimestamp } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-memento',
  firestore: { rules: readFileSync('../../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
});

const user = (u) => ({ uid: u, username: u, username_lower: u, display_name: '', bio: '', link: '', photo_url: null,
  karma: 0, quote_count: 0, follower_count: 0, following_count: 0 });

await env.withSecurityRulesDisabled(async (c) => {
  const db = c.firestore();
  for (const u of ['alice', 'bob', 'eve']) await setDoc(doc(db, 'users', u), user(u));
  await setDoc(doc(db, 'quotes', 'q1'), { text: 'Bob sözü', author: 'bob', privacy: 'Herkese Açık', user_id: 'bob', owner_username: 'bob', likes: 0 });
});

const A = env.authenticatedContext('alice').firestore();
const B = env.authenticatedContext('bob').firestore();
const E = env.authenticatedContext('eve').firestore();
let pass = 0, fail = 0;
async function t(name, p) { try { await p; console.log('OK  ', name); pass++; } catch (e) { console.log('FAIL', name, e.message?.slice(0, 160)); fail++; } }

// --- Takip
const follow = (db, me, target) => {
  const b = writeBatch(db);
  b.set(doc(db, `users/${me}/following/${target}`), { uid: target, created_at: serverTimestamp() });
  b.update(doc(db, `users/${me}`), { following_count: increment(1), following_src: target });
  b.set(doc(db, `users/${target}/followers/${me}`), { uid: me, created_at: serverTimestamp() });
  b.update(doc(db, `users/${target}`), { follower_count: increment(1) });
  return b.commit();
};
await t('alice bob\'u takip eder', assertSucceeds(follow(A, 'alice', 'bob')));
await t('eve takip etmeden sayaç şişiremez', assertFails(updateDoc(doc(E, 'users/bob'), { follower_count: increment(1) })));

// --- Bildirim
const actor = (u) => ({ actor_uid: u, actor_username: u, actor_photo_url: null, created_at: serverTimestamp(), read: false });
await t('alice takip bildirimi yazar', assertSucceeds(setDoc(doc(A, 'users/bob/notifications/follow_alice'), { ...actor('alice'), type: 'follow' })));
await t('aynı takip bildirimi tekrar yazılamaz', assertFails(setDoc(doc(A, 'users/bob/notifications/follow_alice'), { ...actor('alice'), type: 'follow' })));
await t('eve takip etmeden takip bildirimi yazamaz', assertFails(setDoc(doc(E, 'users/bob/notifications/follow_eve'), { ...actor('eve'), type: 'follow' })));
await t('eve başkası adına bildirim yazamaz', assertFails(setDoc(doc(E, 'users/bob/notifications/follow_alice'), { ...actor('alice'), type: 'follow' })));
await t('eve sahte kullanıcı adıyla yazamaz', assertFails(setDoc(doc(E, 'users/bob/notifications/follow_eve'), { ...actor('eve'), actor_username: 'admin', type: 'follow' })));
await t('alice bob\'un bildirimlerini okuyamaz', assertFails(getDoc(doc(A, 'users/bob/notifications/follow_alice'))));
await t('bob kendi bildirimini okur', assertSucceeds(getDoc(doc(B, 'users/bob/notifications/follow_alice'))));
await t('bob okundu işaretler', assertSucceeds(updateDoc(doc(B, 'users/bob/notifications/follow_alice'), { read: true })));
await t('bob bildirim içeriğini değiştiremez', assertFails(updateDoc(doc(B, 'users/bob/notifications/follow_alice'), { actor_username: 'x' })));

// Beğeni + bildirim
const like = (db, me) => {
  const b = writeBatch(db);
  b.set(doc(db, `quotes/q1/likes/${me}`), { user_id: me, created_at: serverTimestamp() });
  b.update(doc(db, 'quotes/q1'), { likes: increment(1) });
  b.update(doc(db, 'users/bob'), { karma: increment(1), karma_src: 'q1' });
  return b.commit();
};
await t('eve beğenmeden beğeni bildirimi yazamaz', assertFails(setDoc(doc(E, 'users/bob/notifications/like_q1_eve'), { ...actor('eve'), type: 'like', quote_id: 'q1', quote_text: 'Bob sözü' })));
await t('alice q1\'i beğenir', assertSucceeds(like(A, 'alice')));
await t('alice beğeni bildirimi yazar', assertSucceeds(setDoc(doc(A, 'users/bob/notifications/like_q1_alice'), { ...actor('alice'), type: 'like', quote_id: 'q1', quote_text: 'Bob sözü' })));
await t('yanlış kimlikli beğeni bildirimi reddedilir', assertFails(setDoc(doc(A, 'users/bob/notifications/like_zzz'), { ...actor('alice'), type: 'like', quote_id: 'q1', quote_text: 'Bob sözü' })));

// --- Takipçi çıkarma (bob, alice'i çıkarır)
const removeFollower = (db, me, f) => {
  const b = writeBatch(db);
  b.delete(doc(db, `users/${me}/followers/${f}`));
  b.update(doc(db, `users/${me}`), { follower_count: increment(-1), follower_src: f });
  b.delete(doc(db, `users/${f}/following/${me}`));
  b.update(doc(db, `users/${f}`), { following_count: increment(-1), following_src: me });
  return b.commit();
};
await t('eve, bob adına alice\'i çıkaramaz', assertFails(removeFollower(E, 'bob', 'alice')));
await t('bob alice\'i takipçilerinden çıkarır', assertSucceeds(removeFollower(B, 'bob', 'alice')));
await t('bob takipçi değilken sayaç düşüremez', assertFails(updateDoc(doc(B, 'users/bob'), { follower_count: increment(-1), follower_src: 'alice' })));
await t('bob alice\'in takip sayacını boşuna düşüremez', assertFails(updateDoc(doc(B, 'users/alice'), { following_count: increment(-1), following_src: 'bob' })));

await env.withSecurityRulesDisabled(async (c) => {
  const db = c.firestore();
  const a = (await getDoc(doc(db, 'users/alice'))).data(), b = (await getDoc(doc(db, 'users/bob'))).data();
  console.log('sayaçlar → alice following:', a.following_count, ' bob followers:', b.follower_count);
});

// Yeniden takip + bırakma
await t('alice yeniden takip eder', assertSucceeds(follow(A, 'alice', 'bob')));
const unfollow = (db, me, target) => {
  const b = writeBatch(db);
  b.delete(doc(db, `users/${me}/following/${target}`));
  b.update(doc(db, `users/${me}`), { following_count: increment(-1), following_src: target });
  b.delete(doc(db, `users/${target}/followers/${me}`));
  b.update(doc(db, `users/${target}`), { follower_count: increment(-1) });
  return b.commit();
};
await t('alice takibi bırakır', assertSucceeds(unfollow(A, 'alice', 'bob')));

// --- Kart rengi
const q = (c) => ({ text: 'Renkli', author: 'alice', privacy: 'Herkese Açık', lang: 'tr', user_id: 'alice',
  owner_username: 'alice', owner_photo_url: null, likes: 0, created_at: serverTimestamp(), ...(c === undefined ? {} : { color: c }) });
const mk = (db, id, c) => { const b = writeBatch(db); b.set(doc(db, 'quotes/' + id), q(c));
  b.update(doc(db, 'users/alice'), { quote_count: increment(1), quote_src: id }); return b.commit(); };
await t('renksiz söz yazılır', assertSucceeds(mk(A, 'c0')));
await t('renk 3 ile söz yazılır', assertSucceeds(mk(A, 'c3', 3)));
await t('renk 9 reddedilir', assertFails(mk(A, 'c9', 9)));
await t('renk yazı olarak reddedilir', assertFails(mk(A, 'cs', 'kırmızı')));
await t('sahibi rengi değiştirir', assertSucceeds(updateDoc(doc(A, 'quotes/c3'), { color: 5 })));
await t('başkası rengi değiştiremez', assertFails(updateDoc(doc(E, 'quotes/c3'), { color: 1 })));
await t('renkli söz sabitlenir', assertSucceeds(updateDoc(doc(A, 'users/alice'), { pinned: { id: 'c3', text: 'Renkli', author: 'alice', color: 5 } })));

// --- Profil fotoğrafı (Firestore avatarı)
const jpg = '/9j/' + 'A'.repeat(4000);
await t('alice kendi avatarını yazar', assertSucceeds(setDoc(doc(A, 'avatars/alice'), { data: jpg, updated_at: serverTimestamp() })));
await t('eve alice\'in avatarını yazamaz', assertFails(setDoc(doc(E, 'avatars/alice'), { data: jpg })));
await t('jpeg olmayan veri reddedilir', assertFails(setDoc(doc(A, 'avatars/alice'), { data: 'PHN2Zz48c2NyaXB0Pg' + 'A'.repeat(200) })));
await t('çok büyük avatar reddedilir', assertFails(setDoc(doc(A, 'avatars/alice'), { data: '/9j/' + 'A'.repeat(220000) })));
await t('herkes avatarı okur', assertSucceeds(getDoc(doc(E, 'avatars/alice'))));
await t('alice photo_url işaretçisini yazar', assertSucceeds(updateDoc(doc(A, 'users/alice'), { photo_url: 'avatar:alice:1795200000000' })));
await t('alice başkasının avatarını gösteremez', assertFails(updateDoc(doc(A, 'users/alice'), { photo_url: 'avatar:bob:1795200000000' })));

// --- Memento defteri
const jq = { id: 'local_ab12', text: 'Yedi kere düş, sekiz kere kalk.', author: 'Japon Atasözü', lang: 'tr', likes: 0, privacy: 'Herkese Açık' };
await t('alice defterine yazar', assertSucceeds(setDoc(doc(A, 'users/alice/journal/2026-11-21'), { quote: jq, note: 'Sınav öncesi iyi geldi.', created_at: serverTimestamp() })));
await t('alice bugünün sayfasını değiştirir', assertSucceeds(setDoc(doc(A, 'users/alice/journal/2026-11-21'), { quote: jq, note: '' })));
await t('eve alice\'in defterini okuyamaz', assertFails(getDoc(doc(E, 'users/alice/journal/2026-11-21'))));
await t('eve alice\'in defterine yazamaz', assertFails(setDoc(doc(E, 'users/alice/journal/2026-11-22'), { quote: jq, note: '' })));
await t('yanlış gün anahtarı reddedilir', assertFails(setDoc(doc(A, 'users/alice/journal/yarin'), { quote: jq, note: '' })));
await t('çok uzun not reddedilir', assertFails(setDoc(doc(A, 'users/alice/journal/2026-11-20'), { quote: jq, note: 'x'.repeat(300) })));
await t('fazladan alan reddedilir', assertFails(setDoc(doc(A, 'users/alice/journal/2026-11-20'), { quote: jq, note: '', puan: 99 })));

console.log(`\n${pass} geçti, ${fail} kaldı`);
await env.cleanup();
process.exit(fail ? 1 : 0);
