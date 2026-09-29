# MyShop

A compact Flutter e-commerce portfolio app modernized from an older shop project into a cleaner, app-like storefront without adding a custom backend.

## What the app includes

- Email sign in and account creation with Firebase Authentication
- Persistent authenticated sessions
- Product catalog backed by Firebase Realtime Database
- Responsive product grid
- Product search
- Per-user saved/favorite products
- Product details
- Shopping cart with quantity controls
- Order placement and per-user order history
- Product management screens from the original project
- Material 3 design
- System light/dark theme support
- Pull-to-refresh and useful empty/error states

## Tech stack

- Flutter / Dart
- Provider
- GetIt
- Firebase Authentication REST API
- Firebase Realtime Database
- SharedPreferences
- HTTP
- Freezed API result model

## Project direction

The goal of this repository is intentionally practical: make the existing shop project feel like a small modern application while keeping the scope suitable for a portfolio project.

It does **not** introduce a new custom backend, a large domain layer, or unnecessary infrastructure. The existing Firebase services remain the backend.

## Main flow

1. Sign in or create an account.
2. Browse or search products.
3. Save products as favorites.
4. Open a product and add it to the cart.
5. Adjust quantities in the cart.
6. Place an order.
7. Review previous orders from the navigation drawer.

## Run locally

Use a recent Flutter SDK compatible with Dart 3.5+.

```bash
flutter pub get
flutter run
```

The project uses the Firebase configuration already present in the repository. For production use, Firebase credentials, database rules, environment configuration, and release settings should be reviewed separately.

## Scope

This is a deliberately small storefront rather than a full commerce platform. Features such as payment gateways, shipping integrations, inventory systems, and a separate production backend are outside the current scope.
