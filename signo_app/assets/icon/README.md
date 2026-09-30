# App icon — source art

`signo_app_logo.png` is the Stitch-generated logo mockup, committed here as the
icon's **source art reference** (origin: `docs/design-reference/signo_app_logo/screen.png`, 150x135 px).

## Status

The Shipaton Next Gen checklist requires a **1024x1024** app icon. This source
art is far below that resolution, so it is committed for reference only — it is
**not** wired into the app and **not** registered in `pubspec.yaml`.

## Next steps (needs a design/device pass — BLOCKED-USER)

1. Recreate or upscale the logo to 1024x1024 px.
2. Add `flutter_launcher_icons` as a dev dependency plus a
   `flutter_launcher_icons.yaml` config.
3. Run `dart run flutter_launcher_icons` to generate all platform icons.
