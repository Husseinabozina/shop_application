# MyShop Commerce Roadmap

This roadmap keeps MyShop small enough for a portfolio project while making the product feel like a real commerce application.

## Implemented

### Account and session
- email sign in
- account creation
- persistent authenticated session
- sign out

### Catalog
- product grid
- responsive layout
- search across products and categories
- category discovery
- price/name sorting
- product details with delivery information
- per-user favorites
- product ownership metadata
- user-scoped product management
- pull to refresh

### Cart
- add to cart
- quantity increase/decrease
- remove item
- subtotal
- empty state

### Checkout
- delivery address form
- saved address selection
- automatic default address reuse
- Standard and Express shipping options
- delivery estimates
- free-shipping threshold
- promo codes
- payment method selection
- Cash on Delivery
- order summary
- final total
- order creation in Firebase
- order confirmation
- backend-agnostic CheckoutRepository contract

### Address book
- Firebase-backed saved addresses
- add/edit/delete
- default address
- reuse saved address at checkout

### Navigation and account
- five-destination bottom navigation
- cart-count badge
- dedicated Categories experience
- Account hub
- Saved Addresses and seller tools as account subflows

### Orders
- feature-first order data/domain/presentation layers
- per-user order history
- Firebase order IDs preserved
- active/delivered/cancelled filters
- order status model
- status chips
- order tracking details screen
- visual tracking timeline
- estimated delivery window
- shipping/payment/address details
- compatibility with legacy quantity data

### Backend hardening
- centralized Firebase REST client
- typed environment configuration via Dart defines
- user-scoped single-order reads
- privacy-safe debug networking logs
- no request/response body logging
- versioned Realtime Database ownership rules
- creatorId index for seller product queries

### Payments foundation
- PaymentGateway contract
- payment capability model
- safe unconfigured gateway adapter
- checkout derives card/wallet availability from gateway capabilities

## Next — high value, still portfolio-sized

### 1. Real payment gateway
The application already models card and wallet payment methods and now has a provider-agnostic gateway boundary, but it does not fake successful payment.

Target architecture:

```text
CheckoutController
  -> PaymentGateway
      -> Stripe / Paymob / Moyasar adapter
      -> secure server-side payment endpoint
```

Candidate providers depend on target market:
- Stripe for broad international coverage
- Paymob for Egypt-focused payment methods
- Moyasar for Saudi-focused payment flows

A real gateway requires secure server-side handling for secret credentials. Firebase Cloud Functions can be used if Firebase remains the backend.

### 2. Backend-driven order updates
The customer tracking UI and status model are implemented.

Next backend work:
- update order status from an admin/backend workflow
- append status timestamps
- send customer notifications when status changes
- optionally connect carrier tracking

### 3. Firebase production deployment
- deploy the versioned Realtime Database rules to the live Firebase project
- verify live reads/writes with authenticated users
- migrate trusted legacy products to a creatorId before relying on seller editing
- keep backend/Admin SDK responsible for post-creation order status changes

### 4. Catalog depth
- filter sheet for additional attributes
- search history
- recently viewed products

### 5. Product detail depth
- image gallery
- product variants such as size/color
- stock state
- delivery estimate
- ratings summary
- reviews

## Later — only if the project still benefits

### Customer experience
- push notifications for order updates
- wishlist collections
- product sharing
- returns/refunds request flow
- reorder

### Commerce
- backend-managed coupons
- inventory reservation
- taxes
- multi-currency
- localized pricing
- store pickup
- carrier-calculated shipping rates

### Engineering
- migrate remaining legacy folders into feature-first modules
- central app router
- typed environment configuration
- repository contract tests
- CI for analyze/test
- Firebase security-rule review

## What we intentionally do not add now

The project should not become an enterprise commerce platform.

Avoid adding these until they solve a real portfolio or product need:
- microservices
- event buses
- dozens of use-case classes for simple CRUD
- separate abstractions with only one trivial caller
- a custom backend merely to say one exists

The goal is credible engineering, not maximum folder count.
