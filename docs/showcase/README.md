# MyShop showcase media

The public README uses real **iPhone 17 Pro simulator** captures supplied by the project owner on **October 5, 2026**, rather than mock app screenshots.

## Capture map

| Public asset | Source |
|---|---|
| `screens/splash.png` | Simulator screenshot, 04:17:15 |
| `screens/onboarding-discover.png` | Simulator screenshot, 04:17:21 |
| `screens/onboarding-basket.png` | Simulator screenshot, 04:17:24 |
| `screens/onboarding-orders.png` | Simulator screenshot, 04:17:30 |
| `screens/home.png` | Simulator screenshot, 04:18:18 |
| `screens/categories.png` | Simulator screenshot, 04:18:28 |
| `screens/product.png` | Simulator screenshot, 04:18:42 |
| `screens/cart.png` | Simulator screenshot, 04:19:22 |
| `screens/checkout.png` | Simulator screenshot, 04:20:34 |
| `screens/order-details.png` | Frame at 54.9 seconds in the supplied recording |
| `screens/order-summary.png` | Frame at 55.7 seconds in the supplied recording |

The original screenshot names begin `Simulator Screenshot - iPhone 17 Pro - 2026-10-05 at` and end in the time shown above. The recording is `Simulator Screen Recording - iPhone 17 Pro - 2026-10-05 at 04.22.54.mov` (57.15 seconds). [manifest.json](manifest.json) records exact basenames, source hashes and selected video intervals.

Gallery images retain the whole simulator screen and are resized to 900 pixels wide. No interface content was redrawn, text replaced or application state invented. The cover arranges these captures in decorative rounded frames with the existing MyShop brand mark and Lato fonts.

## Motion preview

[myshop-demo.mp4](myshop-demo.mp4) is a 29.2-second selected cut from these source intervals:

- 0.8–7.0 seconds: launch and onboarding;
- 19.3–39.4 seconds: Home, product browsing and basket;
- 54.1–57.0 seconds: order history and details.

Sign-in/password entry and delivery-address entry are excluded. The retained order and checkout views use the owner's visibly fictional test address. Demo delivery estimates and status stages are presentation, not live courier tracking.

The MP4 is H.264, 540 pixels wide, 30 fps, without audio, with fast-start metadata. `preview.gif` is a 10.2-second, 300-pixel-wide, 10-fps excerpt for GitHub's inline image display. The original movie remains outside the repository.

## Reproduce the public assets

Use Python 3.9+, Pillow and an FFmpeg executable with H.264 support. They are media-preparation tools, not Flutter runtime dependencies. Keep the owner's source images and recording in a local capture directory, then run from the repository root:

```sh
python3 scripts/prepare_showcase.py \
  --capture-dir /path/to/captures \
  --recording '/path/to/Simulator Screen Recording - iPhone 17 Pro - 2026-10-05 at 04.22.54.mov' \
  --ffmpeg /path/to/ffmpeg
```

This creates the gallery, cover, GIF, selected MP4 and provenance manifest. The script reads all input captures without modifying them. Check the generated media before committing.

## UI regression captures

Automated Flutter screenshots are a separate source produced by the existing startup, shopping-journey and sandbox-payment tests. They include order details and purchased-item sections. See [development setup](../DEVELOPMENT_SETUP.md) for capture commands. They use local fake HTTP data and do not prove live Firebase or payment acceptance.
