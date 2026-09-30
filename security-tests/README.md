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
