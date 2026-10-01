import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

// Emulator-only: no live accounts, catalog records, or credentials are used.
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9099');
assert.equal(process.env.FIREBASE_DATABASE_EMULATOR_HOST, '127.0.0.1:9000');
const users = [];
const id = `sample_check_${randomUUID()}`;
const paths = [`products/${id}`, `products/${id}_second`];
async function auth(action, data) {
  const response = await fetch(`http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:${action}?key=fake-api-key`, {
    method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data),
    signal: AbortSignal.timeout(10000),
  });
  assert.equal(response.status, 200);
  return response.json();
}
async function database(path, token, method = 'GET', data, headers = {}) {
  const url = new URL(`http://127.0.0.1:9000/${path}.json`);
  url.searchParams.set('ns', 'demo-myshop-security-default-rtdb');
  if (token) url.searchParams.set('auth', token);
  return fetch(url, {method, headers: {'Content-Type': 'application/json', ...headers},
    ...(data === undefined ? {} : {body: JSON.stringify(data)}), signal: AbortSignal.timeout(10000)});
}
try {
  for (let i = 0; i < 2; i++) {
    users.push(await auth('signUp', {email: `catalog-${id}-${i}@example.com`, password: `Aa1!${randomUUID()}`, returnSecureToken: true}));
  }
  const [owner, other] = users;
  const product = {id, title: 'Sample stool', description: 'Sample collection check', category: 'Home',
    imageUrl: 'https://example.com/stool.jpg', imageUrls: ['https://example.com/stool.jpg'], price: 149,
    creatorId: owner.localId, stockQuantity: 12};
  assert.equal((await database(paths[0], owner.idToken, 'PUT', product, {'if-match': 'null_etag'})).status, 200);
  assert.equal((await database(paths[0], owner.idToken, 'PATCH', {price: 155})).status, 200);
  assert.equal((await database(paths[0], owner.idToken, 'PUT', product, {'if-match': 'null_etag'})).status, 412);
  assert.equal((await (await database(paths[0], owner.idToken)).json()).price, 155);
  console.log('PASS: conditional setup preserves owner edits on retry');
  const race = await database(paths[0], other.idToken, 'PUT', {...product, creatorId: other.localId}, {'if-match': 'null_etag'});
  assert.ok([401, 403, 412].includes(race.status));
  const stored = await (await database(paths[0], other.idToken)).json();
  assert.equal(stored.creatorId, owner.localId);
  assert.equal(stored.price, 155);
  console.log('PASS: setup cannot take over another account’s sample product');
  const writes = await Promise.all([0, 1].map(() => database(paths[1], owner.idToken, 'PUT', product, {'if-match': 'null_etag'})));
  assert.deepEqual(writes.map(r => r.status).sort(), [200, 412]);
  console.log('PASS: simultaneous creates produce one product');
  const url = new URL('http://127.0.0.1:9000/products.json');
  url.searchParams.set('ns', 'demo-myshop-security-default-rtdb');
  url.searchParams.set('auth', owner.idToken);
  url.searchParams.set('shallow', 'true');
  const response = await fetch(url);
  assert.equal(response.status, 200);
  const ids = await response.json();
  assert.equal(ids[id], true);
  console.log('PASS: shallow authenticated catalog lookup returns product IDs');
} finally {
  const cleanup = await database('', undefined, 'PATCH', Object.fromEntries(paths.map(path => [path, null])), {Authorization: 'Bearer owner'});
  assert.equal(cleanup.status, 200);
  for (const user of users) await auth('delete', {idToken: user.idToken});
}
