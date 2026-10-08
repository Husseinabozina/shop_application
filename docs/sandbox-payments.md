# MyFatoorah hosted Sandbox checkout

This implements the same public V2 REST flow as NOVA (`fashion_e_commerce`).
It is a portfolio demonstration, with **no real charge** and no private account
token. The app uses only MyFatoorah's public documentation test credential at
`https://apitest.myfatoorah.com`. There is no live host or credential override.

## Try it

1. Sign in, add a product, and enter a test delivery address.
2. In Checkout choose **Card payment • Sandbox**. Your full order total is EGP.
3. Continue to test payment. The external browser opens the saved hosted URL
   on `https://demo.myfatoorah.com`; the payment amount is **1.000 KWD**.
   This fixed virtual amount is separate from the basket, not a conversion.
4. Use **5123450000000008**, expiry **01/39**, CVV **100**, name **Test User**.
   If ACS Emulator appears, select successful authentication.
5. Return to MyShop. It checks on resume. **Check payment result** retries
   manually, and **Open test payment** reopens the same saved invoice.
6. A matching Paid result creates one demo order in Orders, labeled
   **Sandbox confirmed • 1 KWD test**. The order total remains EGP.

Pending, declined or offline results keep the cart and saved attempt. Closing
the browser does not mean payment succeeded or was cancelled. A provider-confirmed
cancelled invoice clears the attempt and keeps the cart. One unfinished attempt
per account prevents creating another invoice until the existing one is resolved.
After restart/sign-in, the same account restores and checks its attempt.
If the basket changed while payment was open, its newer contents are kept.

## Exact flow and recovery

- InitiatePayment: InvoiceAmount 1, CurrencyIso KWD.
- Select VISA/MASTER with IsDirectPayment not true; use its returned ID.
- ExecutePayment: InvoiceValue 1, DisplayCurrencyIso KWD, Language AR,
  fictitious CustomerName and an opaque random CustomerReference.
- Persist InvoiceId, reference, hosted URL and the original EGP order snapshot
  locally per Firebase UID before opening the browser.
- GetPaymentStatus: Key is the saved invoice ID as text; KeyType InvoiceId.
- Verify invoice ID, reference, value 1 and KWD/KD display currency, then Paid.
- Save to `order/<uid>/sandbox_myfatoorah_<invoiceId>` with `sandbox_paid`
  and a bounded descriptive receipt. Conditional create-only writes and a
  matching existing-order check prevent duplicate orders after save retries.

No addresses, phone numbers, emails or basket data are sent to MyFatoorah's
shared account. Flutter never collects card details. Customer order snapshots
are stored only on the device and under their private Firebase order path.

Confirmation requires MyShop to be open with internet access. There is no
webhook or server confirmation while closed. Because the token is public and
the merchant shared, these client-verified receipts are **demo metadata**, not
authoritative financial proof. Private merchant keys belong in a backend; the
user's private account activation remains unconfirmed and is not used here.

Ordinary tests/CI use fake HTTP and do not create provider invoices or live
Firebase records. Native builds check packaging; browser-return behavior still
needs the short device walkthrough above.

## Branding

`assets/branding/myshop-icon.png` is the project logo/master icon. Its shopping
bag and cream `m` are generated with the built-in image tool in terracotta and
warm cream, with no faces or photographs. The prompt requested a centered flat
bag mark, generous margins, no external text, and an opaque square background.
Platform-specific sizes are installed for iOS, Android (including adaptive
icons), macOS, Windows and web; sign-in, startup and Home reuse the same mark.

Sources: [NOVA implementation](https://github.com/Husseinabozina/fashion_e_commerce/blob/master/lib/features/checkout/data/services/myfatoorah_sandbox_payments.dart),
[public test token](https://docs.myfatoorah.com/docs/test-token),
[test cards](https://docs.myfatoorah.com/docs/test-cards),
[GetPaymentStatus](https://docs.myfatoorah.com/docs/get-payment-status).
