# MyShop Architecture

## Goal

MyShop is intentionally a compact commerce app, but its codebase should still look credible to an engineering team and remain easy to evolve.

The main architectural rule is simple:

> UI code depends on application/domain contracts. External systems such as Firebase, REST APIs, payment gateways, local storage, and shipping providers live behind implementations of those contracts.

This keeps Firebase replaceable instead of making it the application architecture.

## Architectural style

The target structure is feature-first with lightweight layered boundaries:

```text
lib/
  app/
    app.dart
    app_dependencies.dart

  core/
    config/
    firebase/
    network/
    theme/
    session/
    result/

  features/
    auth/
      data/
      domain/
      presentation/

    catalog/
      data/
      domain/
      presentation/

    payments/
      data/
      domain/

    address_book/
      data/
      domain/
      presentation/

    cart/
      domain/
      presentation/

    checkout/
      data/
      domain/
      presentation/

    orders/
      data/
      domain/
      presentation/
```

Not every feature needs every layer. Small UI-only features should stay small.

## Dependency direction

```text
Presentation
    |
    v
Domain contracts / entities
    ^
    |
Data implementations
    |
    +--> Firebase
    +--> REST API
    +--> Local storage
    +--> Payment provider
    +--> Shipping provider
```

Presentation must not import Firebase-specific classes or construct URLs.

## Responsibilities

### Presentation

Contains screens, reusable feature widgets, and controllers/view models.

Responsibilities:
- render state
- handle user intent
- call domain/repository contracts
- expose loading/error/success states

It should not:
- construct Firebase URLs
- parse remote JSON
- contain payment or shipping provider logic

### Domain

Contains application-facing entities and repository contracts.

Examples:
- CheckoutAddress
- ShippingMethod
- PaymentMethodOption
- CheckoutOrder
- CheckoutRepository

The domain layer must remain independent from Firebase and HTTP.

### Data

Contains implementations of domain contracts and external integrations.

Examples:
- FirebaseCheckoutRemoteDataSource
- CheckoutRepositoryImpl
- StripePaymentGateway
- LocalAddressDataSource

Replacing Firebase with a custom backend should primarily affect this layer.

A centralized `FirebaseRestClient` owns Firebase REST URL construction and auth query handling. Feature services receive that client rather than embedding Firebase URLs.

## State management

Provider / ChangeNotifier remains acceptable for this project because the app is intentionally medium-small.

Rules:
- one controller/provider per feature flow
- controllers expose state, not widgets
- widgets do not execute raw HTTP/Firebase calls
- repository classes remain the source of truth for remote application data

## Dependency injection

GetIt is used only as a composition tool.

Rules:
- register interfaces to implementations
- keep registration in one composition root
- never call GetIt from random widgets
- inject dependencies into controllers/repositories

## Orders architecture

Order history and tracking now follow the same feature-first direction:

```text
OrdersScreen / OrderDetailsScreen
   |
OrderController
   |
OrderRepository
   |
OrderRepositoryImpl
   |
OrderRemoteDataSource
   |
FirebaseRestClient
```

Single-order refresh is user-scoped at `order/{uid}/{orderId}`, matching the ownership model expected by database security rules.

## Backend configuration

Firebase database URL and Firebase Web API key are centralized in `AppEnvironment` and can be overridden with Dart defines.

HTTP debug logging redacts auth tokens, API keys, passwords, ID tokens, refresh tokens and access tokens. Networking logs are disabled in release mode.

## Checkout architecture

Checkout is the first feature implemented fully with the target structure.

```text
CheckoutScreen
   |
CheckoutController
   |
CheckoutRepository
   |
CheckoutRepositoryImpl
   |
CheckoutRemoteDataSource
   |
Firebase REST today
Custom API tomorrow
```

Shipping and payment are modeled as contracts rather than hard-coded UI assumptions.

This allows future implementations such as:
- carrier-calculated shipping
- store pickup
- Stripe
- Paymob
- Moyasar
- Apple Pay / Google Pay
- a custom backend

without rewriting the checkout screen.

## Payments

A payment UI must never pretend a card payment succeeded.

Checkout depends on the provider-agnostic `PaymentGateway` contract.

```text
CheckoutRepository
   |
PaymentGateway
   |
   +--> UnconfiguredPaymentGateway today
   +--> Paymob / Stripe / Moyasar adapter later
```

Gateway capabilities decide whether Card and Wallet options are enabled. The current adapter intentionally exposes no online-payment capabilities, so Cash on Delivery remains the only executable method until a secure real provider is connected.

A real card gateway requires a trusted server-side component for secret-key operations. Secret credentials must never be bundled in Flutter.

## Catalog state

Customer catalog state and seller-managed inventory are kept separately.

This prevents a user-scoped seller query from replacing the global storefront catalog in memory.

Product records support:

- category
- creator ownership
- favorites
- title/description/image/price

Legacy records without a category map to `General`.

## Navigation and design

Primary customer navigation is Home / Categories / Cart / Orders / Account.

Account-specific and seller-specific tools remain secondary subflows.

The visual system is documented in `docs/DESIGN_SYSTEM.md` and uses a warm brown/ivory Material 3 palette with equivalent dark-mode roles.

## Migration strategy

The repository started as an older Flutter learning project, so migration is incremental.

Priority:
1. new features follow the target architecture
2. existing Firebase services are wrapped behind contracts
3. presentation files are migrated feature-by-feature
4. legacy folders are removed only after their replacement is working

This avoids a risky big-bang rewrite while keeping the final direction consistent.

## Sample catalog setup

The explicit sample-collection action follows:

`SampleCatalogScreen → SampleCatalogController → AddSampleCatalog → SampleCatalogRepository`.

The domain fixtures and use case are independent of Flutter and Firebase. The
Firebase repository implements authenticated shallow ID reads and conditional
creates (`if-match: null_etag`) through the central REST client. Stable IDs let
setup resume after a partial failure while preserving existing listings and
owners, including concurrent setup attempts. The sample collection is shared;
only the account that creates a listing can manage that listing under the
existing rules. The screen refreshes storefront and managed-product state after
an attempt so successfully saved products are usable immediately.


## Catalog boundaries

The catalog now follows `CatalogController → ProductRepository →
ProductRepositoryImpl → ProductRemoteDataSource → FirebaseRestClient`.
`Product` is an immutable Dart entity; it has no Flutter notifier, JSON parsing,
repository reference, or network actions. `ProductMapper` owns legacy record
compatibility in the data layer and treats the database record key as the
canonical ID. Repository create/update methods return domain products, so the
controller never sees Firebase push-response DTOs.

Favorite state belongs to the account's private collection and is never written
into shared listings by product create/update. `CatalogController` owns
optimistic favorites, per-product pending guards, rollback and actionable errors.
Both storefront and managed lists receive the same favorite updates; refreshes
started before an action cannot overwrite its result. Product details render the
current catalog snapshot. Disposed controllers ignore late request completions.

Architectural checks keep the catalog domain free of Flutter, Firebase, HTTP,
and data/presentation imports, and prevent catalog controllers from importing
network implementations. Auth and cart now follow the same feature-first dependency direction.


## Auth and cart

`AuthController → AuthRepository → AuthRepositoryImpl` composes an authenticated
remote data source with the `SessionStore` contract. `AuthSession` is a pure Dart
entity. Existing `UserData` cache records remain compatible; expired/malformed
sessions are cleared and require sign-in, preserving the current expiry behavior.
Firebase REST error mapping stays in the data layer. Controller disposal cancels
its session timer. Changing accounts resets secondary navigation routes.

`CartController → CartRepository → LocalCartRepository` stores immutable `CartItem`
snapshots locally under a key for each user. Writes retain their account scope,
are serialized, and include an immediate in-memory snapshot so switching accounts
cannot expose another cart or restore an older queued version. Checkout clearing
also saves an empty cart. Corrupt local entries are skipped individually, and
storage failures are visible in the cart. Catalog stock is still rechecked before
checkout; local cart data is not an inventory reservation.

The app composition root supplies persistent cart storage. Isolated cart tests
can use an ephemeral controller without storage; no backend is needed for cart
persistence. Existing Firebase paths and security rules are unchanged.
