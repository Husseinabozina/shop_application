# Run one complete MyShop checkout

The GitHub repository is `Husseinabozina/shop_application`. **MyShop** is the app's display name; **shop_application** is its Dart package name. A local directory can be called `shop_application`, `myshop-continuation` or another name without changing the package or creating a dependency on a sibling directory.

## Get the current source

While PR #18 is open, clone its development branch:

```sh
git clone --branch feat/myfatoorah-sandbox-branding https://github.com/Husseinabozina/shop_application.git
cd shop_application
flutter pub get
flutter run
```

After it is merged, the same code is available from `master`. Use a Flutter SDK compatible with Dart 3.5+; the current app was built locally with Flutter 3.38.5. Native SDKs are needed for Android/iOS builds. The existing Firebase configuration can be replaced with the defines in [Environment](ENVIRONMENT.md).

## Two folders on the same Mac

The `myshop-continuation` directory used for this continuation is a **complete, independent clone**. The older `shop_application` directory is a second checkout of the same repository, with its own branch and local changes.

The current checkout has its own `lib/`, assets, native projects, dependency manifest and `.git` directory. Its Dart package resolves to its own root. There are no source symlinks or path dependencies into the older checkout. Both can still connect to the same configured Firebase project; that is a shared backend, not a code dependency.

Choose one working checkout. Open **that directory** as the editor project, and run all Flutter commands from its root. The included **MyShop — current checkout** editor launch configuration uses `workspaceFolder`; it does not point to a hard-coded local folder.

To identify an existing checkout before running it:

```sh
pwd
git remote get-url origin
git branch --show-current
git log -1 --oneline
```

Do not copy source folders between the clones or overwrite another checkout's local changes. If moving development to the older directory, save its local work first, then fetch and switch to the same Git branch.

## iPhone simulator

```sh
flutter devices
flutter run -d <the-iPhone-simulator-id>
```

Native icons and launch screens require a full build/relaunch. Hot reload only updates Flutter widgets. Use `ios/Runner.xcworkspace` if opening Xcode after Flutter has installed the native dependencies. Installing on a physical iPhone needs your Apple signing setup.

The first launch shows the branded splash and three welcome pages. Completing or skipping the tour persists the preference on that installation; signing out does not replay it. A new simulator installation has its own first-use preference.

## Validate the journey

```sh
flutter analyze --no-fatal-infos
flutter test
```

For reproducible Flutter-rendered commerce captures:

```sh
python3 scripts/prepare_portfolio_images.py
flutter test test/screens/startup_flow_test.dart test/screens/storefront_journey_test.dart test/features/payments/sandbox_payment_test.dart --dart-define=EXPORT_PORTFOLIO_SHOTS=true
```

The commerce journey now continues from order history into the order-details screen and purchased items at both normal and compact/large-text sizes. Captures are written to `build/portfolio-screenshots/`. These use fake test data; the README's public showcase uses the owner's separate simulator images and recording.

See [the release handoff](DEMO_RELEASE.md) for CI artifacts and [the payment guide](sandbox-payments.md) for sandbox verification.
