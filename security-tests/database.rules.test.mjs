import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';

// A demo ID and loopback host keep every test off the live Firebase project.
const projectId = 'demo-myshop-security';
let environment;
let owner;
let other;
let guest;

const product = (changes = {}) => ({
  title: 'Test T-shirt', description: 'Cotton shirt',
  imageUrl: 'https://example.com/shirt.jpg', price: 30,
  category: 'Clothing', creatorId: 'owner', stockQuantity: 3,
  imageUrls: ['https://example.com/shirt.jpg'], ...changes,
});
const address = (changes = {}) => ({
  label: 'Home', fullName: 'Test Customer', phone: '01000000000',
  addressLine1: 'Test Street', city: 'Cairo', country: 'Egypt',
  isDefault: true, ...changes,
});
const order = (changes = {}) => ({
  amount: 30, datetime: '2026-09-30T17:00:00.000Z', status: 'placed',
  products: [{ id: 'p1', title: 'Test T-shirt', price: 30, quantity: 1 }],
  paymentMethod: 'cash_on_delivery', ...changes,
});

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    database: {
      host: '127.0.0.1', port: 9000,
      rules: readFileSync(new URL('../database.rules.json', import.meta.url), 'utf8'),
    },
  });
  owner = environment.authenticatedContext('owner').database();
  other = environment.authenticatedContext('other').database();
  guest = environment.unauthenticatedContext().database();
});
beforeEach(async () => {
  await environment.clearDatabase();
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.database().ref().set({
      products: { p1: product(), legacy: product({ creatorId: null }) },
      addresses: { owner: { a1: address(), a2: address({ isDefault: false }) } },
      userfavorite: { owner: { p1: true } },
      order: { owner: { o1: order() } },
    });
  });
});
after(async () => { if (environment) await environment.cleanup(); });

test('guests cannot read the catalog or private collections', async () => {
  for (const path of ['products', 'addresses/owner', 'userfavorite/owner', 'order/owner']) {
    await assertFails(guest.ref(path).get());
  }
});
test('guests cannot write any application collection', async () => {
  for (const [path, value] of [
    ['products/new', product()], ['addresses/owner/new', address()],
    ['userfavorite/owner/p1', true], ['order/owner/new', order()],
  ]) await assertFails(guest.ref(path).set(value));
});
test('authenticated users can read the storefront and query their products', async () => {
  await assertSucceeds(other.ref('products').get());
  await assertSucceeds(owner.ref('products').orderByChild('creatorId').equalTo('owner').get());
});
test('owners can create, edit, and delete their products', async () => {
  await assertSucceeds(owner.ref('products/new').set(product()));
  await assertSucceeds(owner.ref('products/new').update({ title: 'Updated shirt' }));
  await assertSucceeds(owner.ref('products/new').remove());
});
test('users cannot create a product for another owner', async () => {
  await assertFails(other.ref('products/new').set(product()));
});
test('other users cannot edit, delete, or take over a product', async () => {
  await assertFails(other.ref('products/p1').update({ title: 'Changed' }));
  await assertFails(other.ref('products/p1').remove());
  await assertFails(other.ref('products/p1').update({ creatorId: 'other' }));
});
test('owners cannot transfer a product to another UID', async () => {
  await assertFails(owner.ref('products/p1').update({ creatorId: 'other' }));
});
test('legacy products remain readable but cannot be claimed or deleted', async () => {
  await assertSucceeds(owner.ref('products/legacy').get());
  await assertFails(owner.ref('products/legacy').update({ creatorId: 'owner' }));
  await assertFails(owner.ref('products/legacy').remove());
});
for (const [label, changes] of [
  ['missing title', { title: null }], ['empty description', { description: '' }],
  ['nonpositive price', { price: 0 }], ['negative stock', { stockQuantity: -1 }],
  ['string stock', { stockQuantity: '3' }],
  ['seventh gallery image', { imageUrls: Array(7).fill('https://example.com/image.jpg') }],
  ['invalid gallery key', { imageUrls: { extra: 'https://example.com/image.jpg' } }],
  ['nonstring gallery image', { imageUrls: [123] }],
]) test(`invalid product rejected: ${label}`, async () => {
  await assertFails(owner.ref('products/new').set(product(changes)));
});
test('legacy single-image products and a six-image gallery remain supported', async () => {
  await assertSucceeds(owner.ref('products/new').set(product({ imageUrls: null, stockQuantity: null })));
  await assertSucceeds(owner.ref('products/new').update({
    imageUrls: Array(6).fill('https://example.com/image.jpg'),
  }));
});
test('favorites are private and boolean values are required', async () => {
  await assertSucceeds(owner.ref('userfavorite/owner').get());
  await assertSucceeds(owner.ref('userfavorite/owner/p1').set(false));
  await assertFails(owner.ref('userfavorite/owner/p1').set('yes'));
  await assertFails(other.ref('userfavorite/owner').get());
  await assertFails(other.ref('userfavorite/owner/p1').set(false));
});
test('owners can save, edit, and delete addresses', async () => {
  await assertSucceeds(owner.ref('addresses/owner').get());
  await assertSucceeds(owner.ref('addresses/owner/new').set(address()));
  await assertSucceeds(owner.ref('addresses/owner/new').update({ city: 'Damietta' }));
  await assertSucceeds(owner.ref('addresses/owner/new').remove());
});
test('default-address multi-path update remains allowed', async () => {
  await assertSucceeds(owner.ref('addresses/owner').update({
    'a1/isDefault': false, 'a2/isDefault': true,
  }));
});
test('other users cannot read, edit, or delete an address', async () => {
  await assertFails(other.ref('addresses/owner').get());
  await assertFails(other.ref('addresses/owner/a1').update({ city: 'Changed' }));
  await assertFails(other.ref('addresses/owner/a1').remove());
});
test('invalid and incomplete addresses are rejected', async () => {
  await assertFails(owner.ref('addresses/owner/new').set(address({ fullName: null })));
  await assertFails(owner.ref('addresses/owner/new').set(address({ city: '' })));
  await assertFails(owner.ref('addresses/owner/new').set(address({ isDefault: 'true' })));
});
test('customers can create and read their own orders', async () => {
  await assertSucceeds(owner.ref('order/owner/new').set(order()));
  await assertSucceeds(owner.ref('order/owner').get());
  await assertSucceeds(owner.ref('order/owner/new').get());
});
test('customers cannot update, overwrite, or delete an existing order', async () => {
  await assertFails(owner.ref('order/owner/o1').update({ status: 'delivered' }));
  await assertFails(owner.ref('order/owner/o1').set(order()));
  await assertFails(owner.ref('order/owner/o1').remove());
});
test('other users cannot read or create orders in another user namespace', async () => {
  await assertFails(other.ref('order/owner').get());
  await assertFails(other.ref('order/owner/o1').get());
  await assertFails(other.ref('order/owner/new').set(order()));
});
test('order creation requires initial placed status and nonnegative numeric amount', async () => {
  await assertFails(owner.ref('order/owner/new').set(order({ status: 'delivered' })));
  await assertFails(owner.ref('order/owner/new').set(order({ amount: -1 })));
  await assertFails(owner.ref('order/owner/new').set(order({ amount: '30' })));
  await assertFails(owner.ref('order/owner/new').set(order({ products: null })));
});
test('root reads and undeclared paths stay closed even after sign-in', async () => {
  await assertFails(owner.ref().get());
  await assertFails(owner.ref('unknown').set({ value: true }));
});
