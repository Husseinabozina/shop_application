#!/usr/bin/env node
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync, mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// Explicit modes prevent a plain invocation from writing to a real project.
const mode = process.argv[2];
if (!['--live', '--emulator'].includes(mode) || process.argv.length !== 3) {
  console.error('Usage: node scripts/firebase_live_smoke.mjs --live|--emulator');
  process.exit(1);
}
const emulated = mode === '--emulator';
const project = emulated ? 'demo-myshop-security' : 'shopapp-29118';
const instance = `${project}-default-rtdb`;
if (!emulated && (process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FIREBASE_DATABASE_EMULATOR_HOST)) {
  throw new Error('Unset Firebase emulator variables before running --live.');
}
if (emulated && (process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' ||
    process.env.FIREBASE_DATABASE_EMULATOR_HOST !== '127.0.0.1:9000')) {
  throw new Error('Emulator mode requires the loopback Auth and Database emulators.');
}
const config = readFileSync(new URL('../lib/core/config/app_environment.dart', import.meta.url), 'utf8');
const key = emulated ? 'fake-api-key' : config.match(/firebaseWebApiKey[\s\S]*?defaultValue:\s*'([^']+)'/)?.[1];
assert.ok(key, 'Missing configured Firebase Web API key.');
const authBase = emulated
  ? 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1'
  : 'https://identitytoolkit.googleapis.com/v1';
const dbBase = emulated ? 'http://127.0.0.1:9000' : `https://${instance}.firebaseio.com`;
const runId = randomUUID().replaceAll('-', '');
const productId = `smoke_${runId}`;
const users = [];
const paths = new Set([`products/${productId}`]);
let checked = 0;

function cli(...args) {
  try {
    return execFileSync('firebase', [...args, '--project', project, '--instance', instance,
      '--non-interactive'], { encoding: 'utf8', timeout: 60000, stdio: ['ignore', 'pipe', 'pipe'] });
  } catch {
    throw new Error('Firebase CLI failed. Check local login and database permissions.');
  }
}
async function request(url, method = 'GET', data, headers = {}) {
  let response;
  try {
    response = await fetch(url, { method, headers: { 'Content-Type': 'application/json', ...headers },
      ...(data === undefined ? {} : { body: JSON.stringify(data) }), signal: AbortSignal.timeout(20000) });
  } catch {
    throw new Error(`Network request failed (${method}); no credentials have been logged.`);
  }
  const body = await response.json();
  return { status: response.status, body };
}
async function auth(action, data) {
  const response = await request(`${authBase}/accounts:${action}?key=${encodeURIComponent(key)}`, 'POST', data);
  assert.equal(response.status, 200, `Firebase Auth ${action} failed (HTTP ${response.status}).`);
  return response.body;
}
function database(path, token, method = 'GET', data, admin = false) {
  const url = new URL(`${dbBase}/${path}.json`);
  if (emulated) url.searchParams.set('ns', instance);
  if (token) url.searchParams.set('auth', token);
  return request(url, method, data, admin ? { Authorization: 'Bearer owner' } : {});
}
async function allowed(label, responsePromise) {
  const response = await responsePromise;
  assert.equal(response.status, 200, `${label} failed (HTTP ${response.status}).`);
  checked += 1;
  console.log(`PASS: ${label}`);
  return response.body;
}
async function denied(label, responsePromise) {
  const response = await responsePromise;
  assert.ok([401, 403].includes(response.status), `${label}: expected access denied.`);
  assert.equal(response.body?.error, 'Permission denied', `${label}: unexpected denial reason.`);
  checked += 1;
  console.log(`PASS: ${label}`);
}
async function createUser(label) {
  const email = `myshop-smoke-${runId}-${label}@example.com`;
  const password = `Aa1!${randomBytes(24).toString('hex')}`;
  const user = await auth('signUp', { email, password, returnSecureToken: true });
  assert.match(user.localId, /^[A-Za-z0-9_-]+$/);
  users.push(user);
  const claims = JSON.parse(Buffer.from(user.idToken.split('.')[1], 'base64url').toString());
  assert.equal(claims.aud, project, 'API key belongs to a different Firebase project.');
  for (const collection of ['addresses', 'userfavorite', 'order']) paths.add(`${collection}/${user.localId}`);
  const signedIn = await auth('signInWithPassword', { email, password, returnSecureToken: true });
  assert.equal(signedIn.localId, user.localId);
  user.idToken = signedIn.idToken;
  checked += 1;
  console.log(`PASS: ${label} signup and sign-in`);
  return user;
}

// Verify administrator cleanup access before creating any accounts or records.
if (!emulated) {
  assert.equal(JSON.parse(cli('database:get', `/${[...paths][0]}`)), null);
  cli('database:update', '/', '--data', JSON.stringify({ [`products/${productId}`]: null }), '--force');
}
let failed = false;
try {
  console.log(`Firebase REST smoke test: ${project} (${mode})`);
  const owner = await createUser('owner');
  const other = await createUser('other');
  const uid = owner.localId;
  const token = owner.idToken;
  const productPath = `products/${productId}`;
  const addressPath = `addresses/${uid}/smoke_address`;
  const favoritePath = `userfavorite/${uid}/${productId}`;
  const orderPath = `order/${uid}/smoke_order`;
  const product = { title: 'SMOKE TEST - temporary shirt', description: 'Temporary integration test',
    imageUrl: 'https://example.com/shirt.jpg', imageUrls: ['https://example.com/shirt.jpg'],
    price: 30, category: 'Clothing', creatorId: uid, stockQuantity: 3 };
  const address = { label: 'Test', fullName: 'Test Customer', phone: '01000000000',
    addressLine1: 'Test Street', city: 'Cairo', country: 'Egypt', isDefault: true };
  await denied('guest catalog read', database('products'));
  await allowed('create owned product', database(productPath, token, 'PUT', product));
  const fetchedProduct = await allowed('catalog read', database(productPath, other.idToken));
  assert.equal(fetchedProduct.creatorId, uid);
  await allowed('save address', database(addressPath, token, 'PUT', address));
  assert.deepEqual(await allowed('read saved address', database(addressPath, token)), address);
  await allowed('save favorite', database(favoritePath, token, 'PUT', true));
  assert.equal(await allowed('read favorite', database(favoritePath, token)), true);
  const item = { id: productId, title: product.title, quantity: 1, price: 30 };
  const placedAt = new Date().toISOString();
  const order = { amount: 30, subtotal: 30, shippingAmount: 0, discountAmount: 0,
    datetime: placedAt, status: 'placed', statusHistory: { placed: placedAt },
    products: [item], items: [{ productId, title: product.title, quantity: 1, unitPrice: 30, total: 30 }],
    shippingAddress: address, paymentStatus: 'cash_on_delivery',
    shippingMethod: { id: 'standard', title: 'Standard', description: 'Test shipping',
      price: 0, minDeliveryDays: 3, maxDeliveryDays: 5 },
    estimatedDeliveryStart: new Date(Date.now() + 3 * 86400000).toISOString(),
    estimatedDeliveryEnd: new Date(Date.now() + 5 * 86400000).toISOString(),
    paymentMethod: { id: 'cod', type: 'cashOnDelivery', title: 'Cash on Delivery', description: 'Pay on delivery' } };
  await allowed('place cash-on-delivery order', database(orderPath, token, 'PUT', order));
  const history = await allowed('read order history', database(`order/${uid}`, token));
  assert.equal(history.smoke_order.amount, order.amount);
  assert.equal(history.smoke_order.products[0].id, productId);
  for (const [label, path] of [['address', addressPath], ['favorites', favoritePath], ['orders', orderPath]]) {
    await denied(`other user cannot read ${label}`, database(path, other.idToken));
  }
  await denied('other user cannot edit product', database(productPath, other.idToken, 'PATCH', { title: 'Changed' }));
  await denied('other user cannot write address', database(addressPath, other.idToken, 'PUT', address));
  await denied('customer cannot change order status', database(orderPath, token, 'PATCH', { status: 'delivered' }));
  await denied('customer cannot delete order', database(orderPath, token, 'DELETE'));
} catch (error) {
  failed = true;
  console.error(`FAIL: ${error.message}`);
} finally {
  // Cleanup is an atomic PATCH containing only IDs generated by this run.
  const patch = Object.fromEntries([...paths].map(path => [path, null]));
  const directory = mkdtempSync(join(tmpdir(), 'myshop-smoke-cleanup-'));
  const patchFile = join(directory, 'cleanup.json');
  writeFileSync(patchFile, JSON.stringify(patch), { mode: 0o600 });
  let clean = true;
  try {
    if (emulated) {
      const response = await database('', undefined, 'PATCH', patch, true);
      assert.equal(response.status, 200, 'Emulator record cleanup failed.');
    }
    else cli('database:update', '/', patchFile, '--force');
    for (const user of users) {
      for (const collection of ['addresses', 'userfavorite', 'order']) {
        const response = await database(`${collection}/${user.localId}`, user.idToken);
        assert.equal(response.status, 200, 'Could not verify cleared test namespace.');
        assert.equal(response.body, null, 'Temporary records still exist.');
      }
    }
    if (users.length) {
      const response = await database(`products/${productId}`, users[0].idToken);
      assert.equal(response.status, 200, 'Could not verify product cleanup.');
      assert.equal(response.body, null, 'Temporary product still exists.');
    }
    console.log('PASS: temporary records removed');
  } catch {
    clean = false;
    failed = true;
    console.error(`Cleanup failed. Scoped cleanup file retained at: ${patchFile}`);
  }
  for (const user of users) {
    try { await auth('delete', { idToken: user.idToken }); }
    catch { failed = true; console.error(`Could not remove temporary Auth user UID: ${user.localId}`); }
  }
  if (clean) rmSync(directory, { recursive: true, force: true });
  if (!failed) console.log(`Firebase authenticated REST smoke test passed (${checked} checks); temporary users removed.`);
}
process.exitCode = failed ? 1 : 0;
