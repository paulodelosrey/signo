# Signo — Learn Colombian Sign Language (LSC)

Signo is a Flutter app that teaches **Lengua de Señas Colombiana** through a gamified learning path and translates written Spanish into LSC sign sequences — built for the **RevenueCat Shipaton 2026, Next Gen Award**. It pairs a 175-sign visual dictionary with an offline-first translator, so hearing relatives, teachers, and students can practice with the Colombian Deaf community — even with no internet and no interpreter around.

## Star features

1. **Spanish → LSC translator, offline-first.** A local grammar engine maps any typed sentence to LSC gloss — dropping copulas and connectors, fronting time expressions, reordering verb-final — and plays the matching signs in a sequenced player (`Secuencia n/n`, 0.75×/1× speed, Spanish text-to-speech). It works with zero network. An optional Gemini strategy refines translations when an API key is supplied.
2. **Gamified LSC course.** A four-unit path (Alfabeto y saludos → Números, colores y familia → Tiempo, lugares y acciones → Comida y animales) with recognize and match exercises, hearts, XP, streaks, gem chests, and a review queue seeded from the signs you miss — structured from a certified LSC interpreter's curriculum.

## Feature tour

| Area | What you get |
|------|--------------|
| Learn path | Serpentine 4-unit tree, locked nodes, boss reviews, lesson-end rewards screen |
| Practice | "Repasar" queue built from your failed signs |
| Visual dictionary | Diacritics-insensitive search over all 175 compiled signs, with detail cards |
| Translator | Offline translation, sequence player, picture quick-phrases, TTS |
| Premium | PRO paywall — infinite hearts, unlimited modules, offline copy, certificate teaser |

## Architecture in 60 seconds

- **Feature-first Flutter** — `lib/features/{learn,translator,dictionary,profile,paywall}` over a small core (`lib/core/{lsc_vocab,gloss_mapper,translator,revenuecat,tts}`), state managed with Riverpod.
- **Content is compiled, not parsed at runtime.** A Dart pipeline turns the interpreter's course CSV into a typed `assets/content/vocab.json` (175 signs) plus a grammar-rules asset.
- **Offline-first with keyless seams.** Every external dependency hides behind an interface that degrades safely without configuration:

| Seam | Without config | With config |
|------|----------------|-------------|
| Lesson / translator videos | Text-mode gloss cards | Curated clip playback |
| Gemini strategy | Local matcher only | AI-enhanced translation |
| RevenueCat billing | Keyless demo PRO (sandbox notice) | Real Test Store entitlements |

- **159/159 tests pass** (`flutter test`) across the gloss mapper, translator pipeline, economy rules, billing gates, and key widgets; `flutter analyze` is clean.

## Run it

```bash
cd signo_app
flutter pub get
flutter test    # 159 tests
flutter run
```

Optional configuration (never committed to the repo — always passed at build time):

```bash
flutter run --dart-define=GEMINI_API_KEY=... --dart-define=REVENUECAT_KEY=...
```

## Monetization

The paywall mirrors the product mockup: **USD 49.99/year with a 7-day free trial**, or **USD 9.99/month**. The RevenueCat entitlement `pro` gates infinite hearts, unlimited modules, the offline copy, and the certificate teaser. With no key configured, the app runs a **keyless demo mode**: the paywall renders with a sandbox notice, and a simulated purchase flips the same `pro` seam — reviewers can experience PRO end-to-end with zero setup. **"Powered by RevenueCat"** is always visible on the paywall.

## Accessibility

Accessibility is a first-class toggle set, not an afterthought: **large text** (app-wide 1.3× scaling), **reduced motion** (kinetic animations settle instantly), **48 px minimum touch targets**, and semantic labels across interactive widgets.

## Submission package

- `docs/video-script.md` — demo video script (~90 s, under the 2-minute requirement)
- `screenshots/` — required device shot list
- `signo_app/assets/icon/` — icon source art and wiring plan
- [LICENSE](LICENSE) — MIT

## Built for RevenueCat Shipaton 2026

Signo is built by a solo student developer (UNAD, Colombia) alongside a certified LSC interpreter (curriculum) and a Deaf collaborator (sign videos). Category: **Next Gen Award**.
