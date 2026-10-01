# MyShop

A compact Flutter e-commerce portfolio application built to look and behave like a small real storefront while keeping the codebase practical and reviewable.

## Highlights

- Warm premium Material 3 storefront with system light/dark mode
- Home / Categories / Cart / Orders / Account bottom navigation
- Firebase Authentication with persistent sessions
- Product catalog with categories, search, sorting, price/availability filters, stock availability, and swipeable product galleries
- Search and per-user favorites
- User-scoped seller product management
- Cart with quantity controls and availability preflight before checkout
- Full checkout flow
- Saved delivery address book with default address
- Standard / Express shipping with delivery estimates
- Free-shipping threshold
- Promo codes
- Provider-agnostic PaymentGateway architecture
- Cash on Delivery
- Capability-driven card and wallet options that stay disabled until a real gateway is configured
- Per-user order history and visual delivery tracking
- Firebase Realtime Database with versioned ownership rules
- Feature-first checkout architecture
- Feature-first checkout, address-book, and orders architecture
- Repository and data-source boundaries
- Centralized Firebase REST client and backend environment configuration
- Redacted debug networking logs
- Focused checkout, address, and order-domain tests

## Architecture

The app is being migrated incrementally from its original learning-project structure into a feature-first layered architecture.

New commerce flows follow this direction:

```text
Presentation
    |
    v
Domain entities + repository contracts
    ^
    |
Data implementations
    |
    +--> Firebase today
    +--> REST / custom backend tomorrow
    +--> payment gateway adapter
    +--> shipping provider adapter
```

Firebase is an implementation detail, not the UI architecture.

Read the full architecture notes in:

- `docs/ARCHITECTURE.md`
- `docs/COMMERCE_ROADMAP.md`
- `docs/FIREBASE_SCHEMA.md`
- `docs/ENVIRONMENT.md`
- `docs/DESIGN_SYSTEM.md`

## Checkout flow

1. Review cart
2. Continue to checkout
3. Add or edit delivery address
4. Select Standard or Express delivery
5. Select an available payment method
6. Apply an optional promo code
7. Review subtotal, shipping, discount, and final total
8. Place the order
9. Store the order under the authenticated customer
10. Review it later from Orders

Card and wallet methods are intentionally not faked. They remain disabled until a real secure payment gateway is connected.

## Current commerce scope

### Implemented
- authentication
- storefront
- search
- favorites
- product details + multi-image gallery
- cart
- checkout
- saved addresses + default address
- shipping selection
- delivery estimates
- discounts / promo code flow
- Cash on Delivery
- order creation
- order history
- order status filters
- order details + tracking timeline
- user-scoped live order refresh
- category discovery + sorting
- per-user recently viewed products
- price range + in-stock filters
- optional stock tracking with sold-out/low-stock states and cart caps
- seller/catalog state separation
- modern Account hub and bottom navigation

### Planned next
- real card payment gateway adapter + secure server endpoint
- backend/admin-driven order status updates
- verify authenticated Flutter flows against the deployed Firebase rules
- additional attribute filters as product metadata grows
- product variants
- ratings and reviews
- push notifications for order updates

## Tech stack

- Flutter / Dart
- Provider
- GetIt
- Firebase Authentication REST API
- Firebase Realtime Database
- SharedPreferences
- HTTP
- Freezed API result model

## Run locally

Use a recent Flutter SDK compatible with Dart 3.5+.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Realtime Database rules were deployed on 2026-09-30, and live unauthenticated
read/write checks passed. Authenticated ownership regression tests run against
the local Firebase emulator; see `security-tests/README.md` for the commands and
scope. A live authenticated Flutter flow still needs verification.

## Design principle

The project is intentionally not an enterprise commerce platform.

The goal is to demonstrate:
- strong UI quality
- realistic commerce flows
- maintainable architecture
- backend replaceability
- clear dependency boundaries
- honest payment behavior
- enough testability to support future growth

without adding infrastructure only for the sake of complexity.

## Try the sample storefront

After signing in, an empty Home screen offers **Explore sample collection**.
Open it and tap **Add sample collection** to save eight demo listings in the
configured database under the current account. This action is also available
from the sparkle button in Account → Manage products.

The collection covers Home, Accessories, Footwear, and Audio, including low-stock
and sold-out examples. Product photos are remote Unsplash images; prices and
listings are demonstration data. Setup uses stable product IDs and conditional
creates, so retrying adds missing items without replacing existing products,
stock, edits, or ownership. No administrator credentials or custom server are
required, and no data is inserted automatically on app launch.

To try the customer journey, browse a product, save it, add it to the cart, choose
a delivery address, and place a Cash on Delivery order. The order should appear
in Orders. Online payments remain unavailable until a real gateway is configured.
