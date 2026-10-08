# MyShop live portfolio

Public app showcase: https://husseinabozina.github.io/shop_application/

The website presents the mobile app; it does not run a web checkout. Its gallery contains all three onboarding pages, splash, Home, categories, product details, basket, checkout, order details and the order summary. The original app content is preserved. Chapter tabs, thumbnails, previous/next controls and a keyboard-accessible full-screen viewer work without a frontend framework. The native video player uses the curated recording from `docs/showcase`.

## Preview locally

From this checkout:

```sh
python3 scripts/build_portfolio_site.py
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/portfolio-site
```

Open http://127.0.0.1:8765/. The build copies an explicit list of public source/media assets into the ignored `build/portfolio-site` directory and checks local asset references. App credentials, native project files, simulator data and local recordings are not part of the website output. Fonts, brand imagery and screenshots are hosted locally without analytics or external font requests.

## Publishing

GitHub Pages uses the **GitHub Actions** source. `MyShop Portfolio` validates pull requests targeting `master` and publishes website changes from the default `master` branch. It uploads only `build/portfolio-site`. The workflow can also be dispatched manually.

The public Android APK is an unchanged artifact of the successful Flutter CI run recorded in the GitHub release notes. Replacing a demo release requires obtaining a newer verified artifact and updating its release notes; the portfolio workflow does not silently rebuild or replace the native app. Unsigned iOS builds remain available through Flutter CI and require Apple signing for physical devices.

## Review

- Check desktop and compact mobile widths for horizontal overflow.
- Switch all four gallery chapters, advance screens and choose thumbnails.
- Open the full-screen viewer, use keyboard arrows and close it with Escape.
- Verify that the video loads, plays and can be downloaded.
- Verify the public Android download and the source/build links.
- Keep demo payment and delivery scope accurate.
