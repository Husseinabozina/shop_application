# MyShop

A compact Flutter e-commerce portfolio application built to look and behave like a small real storefront while keeping the codebase practical and reviewable.

## Highlights

- Material 3 storefront with system light/dark mode
- Firebase Authentication with persistent sessions
- Product catalog and product details
- Search and per-user favorites
- Cart with quantity controls
- Full checkout flow
- Delivery address collection
- Standard / Express shipping with delivery estimates
- Free-shipping threshold
- Promo codes
- Payment-method architecture
- Cash on Delivery
- Gateway-ready card and wallet options
- Per-user order history
- Firebase Realtime Database
- Feature-first checkout architecture
- Repository and data-source boundaries
- Focused checkout unit tests

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
- product details
- cart
- checkout
- shipping selection
- delivery estimates
- discounts / promo code flow
- Cash on Delivery
- order creation
- order history

### Planned next
- real card payment gateway
- saved address book
- order status tracking timeline
- categories / filters / sorting
- product variants
- ratings and reviews
- recently viewed products
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
