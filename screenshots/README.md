# Submission screenshots

Device shots for the Devpost submission, captured on a real TECNO CM6
(Android 16) and rescaled to exactly **1179x2556**, the resolution the
Shipaton checklist requires. No device frames are drawn.

| File | Screen | What it proves |
|------|--------|----------------|
| `01-aprender-ruta.png` | Learning path | Unit 1 is **Saludos y expresiones** — the video-only gate renumbers surviving units, so the first unit really is the first |
| `02-diccionario-cobertura.png` | Dictionary | The app states its own coverage: **"201 señas · 59 con video"**, derived from the shipped index rather than hardcoded |
| `03-detalle-video-en-produccion.png` | Sign detail | A sign with no clip says so honestly and tells the user the remaining videos are in production |
| `04-traductor.png` | Translator | "buenas tardes" resolved to a clip-backed sign sequence, with next/previous stepping |
| `05-premium-revenuecat.png` | Paywall | Both plan buttons side by side and **"Powered by RevenueCat"** — no sandbox notice, so the integration is live, not simulated |

## How these were produced

Captured with `adb shell screencap` at the device's native **1080x2436**, then
rescaled to 1179x2556. That is a non-uniform scale (1.0917 x 1.0493); a uniform
scale would have cropped ~4% of the height or added 23px side bars, and the
status bar and tab bar are both part of what a judge reads.

Screens 3 and 5 were captured mid-session rather than as clean entry states:
screen 3 is a search for a genuinely clip-less sign (`TE-QUIERO`), and screen 5
shows the bottom of the paywall where the RevenueCat attribution sits.