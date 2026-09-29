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
- search
- product details
- per-user favorites
- pull to refresh

### Cart
- add to cart
- quantity increase/decrease
- remove item
- subtotal
- empty state

### Checkout
- delivery address form
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

### Orders
- per-user order history
- expandable order details

## Next — high value, still portfolio-sized

### 1. Real payment gateway
The application already models card and wallet payment methods, but does not fake successful payment.

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

### 2. Saved addresses
- address book
- default address
- edit/delete address
- reuse address at checkout
- local cache + remote repository contract

### 3. Order tracking
Target statuses:
- placed
- confirmed
- packed
- shipped
- out for delivery
- delivered
- cancelled

UI:
- status chip in Orders
- order details screen
- visual timeline
- estimated delivery date

### 4. Catalog discovery
- category chips
- filter sheet
- sort by price/newest
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
