# MyShop Design System

MyShop uses a warm premium storefront direction intended to feel credible as a modern customer-facing commerce application rather than a tutorial UI.

## Visual direction

The core palette is built around warm brown, ivory, and neutral surfaces.

- Primary: warm brown
- Light surface: soft ivory
- Dark surface: warm charcoal
- Cards: low-contrast neutral surfaces
- Selected controls: warm primary containers
- Error and semantic colors: Material color roles

Both light and dark modes use the same semantic color roles.

## Navigation

The customer experience uses a five-destination Material 3 bottom navigation:

1. Home
2. Categories
3. Cart
4. Orders
5. Account

The Cart destination displays the active cart count.

Account-specific actions such as Saved Addresses and Manage Products live inside the Account hub instead of competing with primary shopping navigation.

## Storefront hierarchy

### Home

- storefront headline
- real delivery-benefit hero
- product/category search
- horizontal category discovery
- Saved filter
- sorting
- responsive product grid

### Product details

- large product image
- category label
- title and price
- description
- delivery information
- secure-shopping information
- persistent Add to cart CTA

### Checkout

- delivery address
- shipping method and ETA
- payment method
- promo code
- order summary
- final place-order CTA

### Orders

- status filters
- concise order cards
- delivery ETA
- order details
- vertical tracking timeline

## Component rules

- 18–28 px rounded corners for prominent surfaces
- low or zero card elevation
- strong type hierarchy instead of heavy borders
- primary actions use FilledButton
- secondary actions use tonal treatments
- chips are used for compact filtering and status
- empty/error/loading states are first-class UI states

## Product principles

1. Do not fake capabilities.
   Card and wallet options stay unavailable until a real secure gateway is connected.

2. Show useful commerce information early.
   Delivery benefits, ETA, category, price, and order status should be visible without unnecessary taps.

3. Keep customer navigation simple.
   Seller and account administration remain secondary to shopping.

4. Use real business rules in promotional UI.
   The Home delivery hero reflects the checkout free-shipping threshold instead of presenting a fabricated offer.
