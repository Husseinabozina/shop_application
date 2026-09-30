# Firebase Realtime Database schema

Firebase is currently the remote implementation behind repository contracts.

The application code should not assume that Firebase is permanent. These paths document the current implementation only.

## Current paths

```text
products/
userfavorite/{userId}/
order/{userId}/{orderId}/
addresses/{userId}/{addressId}/
```

## Product record

New and updated products keep catalog and ownership metadata:

```json
{
  "title": "Wireless Headphones",
  "description": "Product description",
  "imageUrl": "https://example.com/product-main.jpg",
  "imageUrls": [
    "https://example.com/product-main.jpg",
    "https://example.com/product-side.jpg"
  ],
  "price": 59.99,
  "category": "Electronics",
  "creatorId": "firebase-auth-user-id",
  "stockQuantity": 12
}
```

Legacy products without a category are displayed as `General`.

`imageUrls` is optional and supports up to 6 gallery images. `imageUrl` remains the required primary image for backward compatibility and compact storefront cards. Legacy products with only `imageUrl` automatically behave as a one-image gallery.

`stockQuantity` is optional for backward compatibility. If it is omitted, inventory is treated as not tracked. A value of `0` means Sold out; positive values represent the available quantity. The Flutter client prevents obvious over-ordering in the UI, but this is not an authoritative inventory reservation system.

User-scoped product management queries by `creatorId`. The versioned rules now include an index for this field:

```json
{
  "products": {
    ".indexOn": ["creatorId"]
  }
}
```

Product writes are owner-scoped in `database.rules.json`: authenticated users can create products with their own `creatorId`, and can update/delete only products already owned by their UID. Optional `stockQuantity` values are validated as non-negative numbers. Legacy products without `creatorId` therefore remain readable but are intentionally not writable until ownership is migrated.

## Saved address record

```json
{
  "label": "Home",
  "fullName": "Customer Name",
  "phone": "01000000000",
  "addressLine1": "Street and building",
  "addressLine2": "Apartment",
  "city": "Cairo",
  "country": "Egypt",
  "postalCode": "12345",
  "isDefault": true
}
```

The first saved address becomes the default automatically.

Only one address should be marked as default after a default-selection operation.

## Order record

New checkout orders keep legacy-compatible product fields while adding commerce metadata.

```text
order/{userId}/{orderId}
  amount
  datetime
  status
  statusHistory
  paymentStatus
  paymentMethod
  shippingMethod
  shippingAddress
  estimatedDeliveryStart
  estimatedDeliveryEnd
  subtotal
  shippingAmount
  discountAmount
  promoCode
  products
  items
```

Supported order statuses:

```text
placed
confirmed
packed
shipped
out_for_delivery
delivered
cancelled
```

## Security rules

Realtime Database rules are now versioned in `database.rules.json` and referenced by `firebase.json`.

The rules enforce:

- authenticated product reads
- owner-scoped product create/update/delete via `creatorId`
- `creatorId` indexing for seller queries
- per-user favorites
- per-user saved addresses with field validation
- per-user order reads
- create-only customer order writes

Customer clients cannot update or delete orders after creation. Future order-status changes should be performed by a trusted backend/Admin SDK, which is the intended path for tracking updates.

### Deployment state

The rules file is versioned and CI-valid JSON, but the live Firebase project still needs an authenticated deployment/verification step before these rules can be claimed as active in production.

### Legacy product ownership

Products created before `creatorId` was introduced cannot be safely assigned to a user from the client.

Before deploying strict product-write rules to a live database containing legacy products, migrate each trusted legacy product to the correct creator UID with an administrative script or Firebase console operation. Do not infer ownership from the current signed-in client.

## Inventory authority

Tracked stock in the mobile app is currently a storefront/UX feature. Before a real online payment flow is considered production-ready, inventory must be revalidated and reserved in a trusted backend transaction at order/payment time so two customers cannot purchase the same final unit.

## Production payment note

Never store payment gateway secret keys in the Flutter application or Realtime Database.

A real card or wallet integration should use a trusted server-side environment such as Firebase Cloud Functions or a separate backend behind the payment repository/gateway contract.


## GitHub Actions deployment

The repository includes a manual workflow at:

`.github/workflows/firebase_rules_deploy.yml`

It deploys Realtime Database rules only.

Required GitHub secret:

- `FIREBASE_SERVICE_ACCOUNT_JSON` — the complete JSON key for a service account that has permission to deploy Firebase Realtime Database rules.

The workflow defaults to project ID `shopapp-29118`, but the project ID can be changed when manually starting the workflow.

Do not commit the service-account JSON to the repository and do not paste it into source files.
