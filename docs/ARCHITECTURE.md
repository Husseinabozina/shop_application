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

Current architecture distinguishes payment method selection from payment authorization.

A real card gateway requires a secure server-side component for secret-key operations. When a real provider is connected, its implementation belongs behind the payment/checkout data layer.

Cash on Delivery can be completed without a payment gateway.

## Migration strategy

The repository started as an older Flutter learning project, so migration is incremental.

Priority:
1. new features follow the target architecture
2. existing Firebase services are wrapped behind contracts
3. presentation files are migrated feature-by-feature
4. legacy folders are removed only after their replacement is working

This avoids a risky big-bang rewrite while keeping the final direction consistent.
