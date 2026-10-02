# MyShop demo and release handoff

MyShop is a Flutter commerce portfolio project backed by Firebase Authentication
and Realtime Database. The customer journey includes product discovery,
favorites, a persistent account-scoped cart, saved addresses, Cash on Delivery,
and private order history. Catalog, auth, cart, address book, checkout, orders,
and payment capabilities have replaceable contracts.

## Run on the existing Mac checkout

```bash
cd "$HOME/Projects/shop_application"
flutter pub get
flutter run
```

Sign in, then choose **Explore sample collection → Add sample collection** if
Home is empty. Setup adds eight demo listings without overwriting existing ones.
On a populated storefront, setup is available in **Account → Manage products →
Sample collection**. Listings are shared; only their creator can manage them.

## Short live-device check

Use a test account and a test delivery address:

1. Browse a product, save it, and add it to the cart.
2. Close and reopen the app: the unexpired session and cart should restore.
3. Complete checkout with Cash on Delivery. Confirm the order in Orders and
   that the cleared cart remains empty after reopening.
4. Sign out and into another account: the first account's cart, favorites,
   addresses, and orders should not appear.
5. Check keyboard forms, empty/error screens, and larger text on the device.

This creates a real test order in the configured Firebase project. Customer
orders cannot be deleted under the current ownership rules. CI uses fake HTTP
state or the Firebase emulator; it does not complete this device check for you.

## CI demo files

Open the latest **Flutter CI** run in GitHub Actions. It produces:

- **myshop-android-demo-release**: an ARM64 release APK, signed with the existing
  debug key for installation/demo use. Android manifest includes Internet access.
- **myshop-ios-unsigned-release**: a release-mode `Runner.app` for iOS, without
  signing. Device installation/distribution needs your Apple signing setup.
- **myshop-portfolio-screenshots**: actual Flutter-rendered Home, product, cart,
  checkout, and order-history captures with sample photos and fake test data.
  These are UI captures, not evidence of live orders or device verification.

Artifacts are retained for 30 days. Download them when preparing the portfolio.

The screenshots are exported during the existing shopping-journey tests; there
is no second duplicate test suite. To reproduce them locally:

```bash
python3 scripts/prepare_portfolio_images.py
flutter test test/screens/storefront_journey_test.dart --dart-define=EXPORT_PORTFOLIO_SHOTS=true
```

Screenshot output is `build/portfolio-screenshots/`. An APK can be built locally:

```bash
flutter build apk --release --target-platform android-arm64
```

The Android toolchain uses the Flutter 3.41.9 template's Gradle 8.14 / AGP 8.11.1 /
Kotlin 2.2.20 versions, declarative Flutter plugins, and Java 17. Android SDK/NDK
levels follow the installed Flutter SDK.

## Current scope

Online card/wallet payments remain disabled. Post-creation order updates need a
trusted admin/backend flow. Inventory is checked before checkout but is not
reserved/decremented by a server transaction. Ratings, variants, and push
notifications are future work; they are not needed to run the current demo.

## Portfolio description

**MyShop — Flutter commerce application**

Built an end-to-end storefront with account-scoped favorites, persistent cart,
saved delivery addresses, shipping options, Cash on Delivery checkout, and
order history. Refactored the app into feature-first layers with pure domain
entities and replaceable repositories, while keeping Firebase-specific REST
mapping in the data layer. Added ownership rules, focused regression checks,
and CI for Flutter analysis/tests, native builds, and demo artifacts.
