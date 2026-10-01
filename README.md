# Signo — Learn Colombian Sign Language (LSC)

Signo is a Flutter app that teaches **Lengua de Señas Colombiana** through a gamified learning path and translates written Spanish into LSC sign sequences — built for the **RevenueCat Shipaton 2026, Next Gen Award**. It pairs a visual dictionary of **201 signs, 158 of them with curated video today**, with an offline-first translator, so hearing relatives, teachers, and students can practice with the Colombian Deaf community — even with no internet and no interpreter around.

## Star features

1. **Spanish → LSC translator, offline-first.** A local grammar engine maps any typed sentence to LSC gloss — dropping copulas and connectors, fronting time expressions, reordering verb-final — and plays the matching signs in a sequenced player (`Secuencia n/n`, 0.75×/1× speed, Spanish text-to-speech). It works with zero network. An optional Gemini strategy refines translations when an API key is supplied.
2. **Gamified LSC course.** A five-unit path (**Saludos y expresiones → Números, colores y familia → Tiempo, lugares y acciones → Comida y animales → Abecedario (dactilología)**) with recognize and match exercises, hearts, XP, streaks, gem chests, and a review queue seeded from the signs you miss — structured from a certified LSC interpreter's curriculum. 112 of the 201 signs are playable.

   **Every sign you can practice is a sign you can watch.** One predicate — *this sign has a bundled clip* — gates the learning path, the exercises and the translator, so no screen ever offers a sign it cannot play. Today that admits 158 signs and hides 43, and the gap is real rather than hypothetical: the remaining footage has not been produced yet. Those 43 stay in the dictionary, where the sign says so plainly and names the video production in progress. The dictionary prints its own coverage — "201 señas · 158 con video" — instead of hiding the gap, and both numbers are read from the shipped asset rather than written by hand.

## Feature tour

| Area | What you get |
|------|--------------|
| Learn path | Serpentine 5-unit tree, locked nodes, boss reviews, lesson-end rewards screen |
| Practice | "Repasar" queue built from your failed signs — free to enter, and it refills your hearts |
| Visual dictionary | Diacritics-insensitive search over all 201 compiled signs, with detail cards and a live coverage line |
| Translator | Offline translation, sequence player, picture quick-phrases, TTS |
| Premium | PRO paywall — infinite hearts, unlimited modules, offline copy, certificate teaser |

## Architecture in 60 seconds

- **Feature-first Flutter** — `lib/features/{learn,translator,dictionary,profile,paywall}` over a small core (`lib/core/{lsc_vocab,gloss_mapper,translator,revenuecat,tts}`), state managed with Riverpod.
- **Content is compiled, not parsed at runtime.** A Dart pipeline turns the interpreter's course CSV into a typed `assets/content/vocab.json` (201 signs) plus a grammar-rules asset. Clip bindings are resolved by matching that output against `assets/signs/manifest.json`, so a sign can never claim a video it does not ship.
- **Offline-first with keyless seams.** Every external dependency hides behind an interface that degrades safely without configuration:

| Seam | Without config | With config |
|------|----------------|-------------|
| Lesson / translator videos | Text-mode gloss cards | Curated clip playback |
| Gemini strategy | Local matcher only | AI-enhanced translation |
| RevenueCat billing | Keyless demo PRO (sandbox notice) | Real Test Store entitlements |

- **231/231 tests pass** (`flutter test`) across the gloss mapper, translator pipeline, economy rules, billing gates, and key widgets; `flutter analyze` is clean.

## Run it

```bash
cd signo_app
flutter pub get
flutter test    # 231 tests
flutter run
```

Optional configuration (never committed to the repo — always passed at build time):

```bash
flutter run --dart-define=GEMINI_API_KEY=... --dart-define=REVENUECAT_KEY=...
```

## Monetization

The paywall mirrors the product mockup: **USD 49.99/year with a 7-day free trial**, or **USD 9.99/month**. The RevenueCat entitlement `pro` gates infinite hearts, unlimited modules, the offline copy, and the certificate teaser.

Each plan button buys the plan it names. RevenueCat's hosted paywall is server-configured and lets the buyer pick *any* plan, so a tap on "USD 9.99/month" is routed straight to that package with strict resolution and **no fallback**: if the monthly plan is not in the current offering, the call surfaces an error instead of quietly settling an annual subscription. Selling someone the wrong tier is a wrong charge, not a wrong label.

With no key configured, the app runs a **keyless demo mode**: the paywall renders with a sandbox notice, and a simulated purchase flips the same `pro` seam — reviewers can experience PRO end-to-end with zero setup. **"Powered by RevenueCat"** is always visible on the paywall.

## Accessibility

Accessibility is a first-class toggle set, not an afterthought: **large text** (app-wide 1.3× scaling), **reduced motion** (kinetic animations settle instantly), **48 px minimum touch targets**, and semantic labels across interactive widgets.

## Submission package

- [`docs/`](docs/) — the LSC grammar corpus the translator's rules come from, and the design record of how the screens were built
- [`screenshots/`](screenshots/) — the five required 1179x2556 device shots, with what each one proves
- [`icon-1024.png`](icon-1024.png) — 1024x1024 app icon
- [`MonikLSC/`](MonikLSC/) — the interpreter's course CSV, the source of truth `vocab.json` is compiled from
- [LICENSE](LICENSE) — MIT

## Built for RevenueCat Shipaton 2026

Signo is a **solo student project** by a UNAD (Colombia) developer. Its course content comes from a **certified LSC interpreter** and its 198 sign clips were recorded with a **Deaf collaborator** — the only people who can validate Colombian Sign Language content are the people who work in it. Category: **Next Gen Award**.
