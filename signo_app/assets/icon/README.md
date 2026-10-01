# App icon — source art

`signo_app_logo.png` is the master the launcher assets are generated from. Two
hands facing each other in the app's mint, on transparency.

| Asset | Generated from this file |
|---|---|
| `android/.../mipmap-*/ic_launcher.png` | legacy square icon, 48→192 px |
| `android/.../mipmap-*/ic_launcher_foreground.png` | adaptive foreground, 108→432 px |
| `android/.../mipmap-anydpi-v26/ic_launcher.xml` | adaptive icon declaration |
| `android/.../values/colors.xml` | `ic_launcher_background` = `#191C23` |
| `android/.../drawable-nodpi/signo_splash.png` | 1080×2436 launch splash |

The master is kept at 1254×1254 rather than the 48 px the smallest launcher slot
needs, so the assets stay sharp if a density is ever added. The five asset groups
above are committed output, not build steps: nothing regenerates them, so treat
this file as the source of truth and the mipmaps as derived from it.

`assets/icon/` is not listed in `pubspec.yaml` and is not bundled into the app —
the launcher reads the Android resources directly.

**Replacing the mark:** overwrite this file and re-derive all five asset groups
above. Nothing else in the app references the icon, so no Dart change is needed.
