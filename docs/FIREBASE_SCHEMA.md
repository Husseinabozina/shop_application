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
  "imageUrl": "https://example.com/product.jpg",
  "price": 59.99,
  "category": "Electronics",
  "creatorId": "firebase-auth-user-id"
}
```

Legacy products without a category are displayed as `General`.

User-scoped product management queries by `creatorId`. If Firebase rules are versioned later, the products collection should include an index for this field:

```json
{
  "products": {
    ".indexOn": ["creatorId"]
  }
}
```

Product write permissions still need a real seller/admin authorization policy before this is considered production-ready.

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

## Security requirement

Database rules are not currently versioned in this repository, so the live Firebase rules must be verified before the address book is considered production-ready.

At minimum, customer-scoped paths should enforce ownership:

```json
{
  "rules": {
    "addresses": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    },
    "order": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    },
    "userfavorite": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

This snippet is documentation, not a deployed rules file. Existing product/admin access requirements must be reviewed before applying any complete ruleset.

## Production payment note

Never store payment gateway secret keys in the Flutter application or Realtime Database.

A real card or wallet integration should use a trusted server-side environment such as Firebase Cloud Functions or a separate backend behind the payment repository/gateway contract.
