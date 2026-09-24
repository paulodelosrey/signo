# Screenshots — required shot list

Shipaton Next Gen requires at least one **1179x2556 frameless** screenshot.
None are committed yet: no device or emulator was attached during development,
and fabricated images are worse than none.

## Shot list

| # | Screen | State to capture |
|---|--------|------------------|
| 1 | Onboarding | First-launch pages, "Empezar a aprender" CTA visible |
| 2 | Learn tree (Aprender) | Serpentine 4-unit path, Unit 1 unlocked |
| 3 | Lesson | Recognize/match exercise with hearts HUD |
| 4 | Lesson end | XP / precision / streak / chest rewards screen |
| 5 | Dictionary | Search results for a query (e.g. "hola") |
| 6 | Translator | Translated sequence (Secuencia 1/n, speed chip, quick phrases) |
| 7 | Profile | Stats grid (XP, streak, gems, hearts) |
| 8 | Paywall (Premium) | Pricing tiles + "Powered by RevenueCat" footer |

## Capture steps (needs a device or emulator — BLOCKED-USER)

1. `flutter run` on a 1179x2556 device (or emulator with the device frame disabled).
2. Capture each state above as a frameless PNG.
3. Commit as `screenshots/NN-name.png`.
