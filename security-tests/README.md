# Realtime Database security tests

These tests load the repository's actual `database.rules.json` into the Firebase
Realtime Database emulator and exercise owner, other-user, and signed-out access.
They cover the storefront and seller query, product ownership, gallery limits,
stock validation, favorites, address CRUD/default selection, and create-only orders.

Run from the repository root with Node 22 and Java 21 available:

```bash
npm ci --prefix security-tests
npm test --prefix security-tests
```

No Firebase login or service-account key is needed. The test runner always uses
`demo-myshop-security` with the database on `127.0.0.1:9000`. Tests never access
the live `shopapp-29118` project. Data is reset between tests in the emulator only.

GitHub Actions runs the same suite on pull requests and pushes to `master`.
An emulator pass verifies the versioned rules, not the deployed project's state
or a complete Flutter UI flow.

## Authenticated REST smoke test

Rehearse real Auth signup/sign-in and database REST requests locally:

```bash
npm run test:smoke --prefix security-tests
```

The same script has an explicit live mode for `shopapp-29118`:

```bash
node scripts/firebase_live_smoke.mjs --live
```

Live mode requires Node 18+ and a locally authenticated Firebase CLI with database
read/update permissions. It reads the public Web API key already configured in
`AppEnvironment`, verifies the token's project, creates two randomly named
temporary accounts, and tests product/address/favorite/order access and isolation.
Passwords and tokens stay in memory and are not printed. Existing Auth users are
not used or modified. The order is synthetic and uses Cash on Delivery; no payment
gateway or delivery service is called.

Cleanup runs on success or a caught failure. An administrative multi-path update
removes only the generated product ID and the namespaces of accounts created by
this run, then the script verifies those records are gone and deletes those Auth
accounts. If database cleanup fails, it retains a private temporary file containing
the exact scoped cleanup paths and exits unsuccessfully. A force kill or interrupted
network response can prevent cleanup; check the CLI output for any remaining IDs.

This verifies Auth/Database REST integration. It does not run Flutter widgets,
device navigation, cart calculations, or the application's Dart repositories, and
it must not be reported as a complete UI checkout verification.
