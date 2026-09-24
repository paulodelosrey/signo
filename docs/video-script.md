# Signo — Devpost demo video script (~90 s)

Target length: **90 seconds** (Shipaton hard cap: under 2 minutes).
Voiceover: English. On-screen UI: Spanish (the app's language) — the English
narration doubles as the required English translation.

Requirements this script satisfies: public YouTube/Vimeo link, device capture
of the real app, under 2 minutes, English materials.

> Recording is **BLOCKED-USER**: Paulo records after the swot student-email
> verification and gives final sign-off.

## Scene plan

| # | Time | Screen / state | Voiceover (English) |
|---|------|----------------|---------------------|
| 1 | 0:00–0:08 | Cold open on the onboarding title page (logo + "Continuar") | "What if your phone could help you talk with a Deaf friend — in their own language?" |
| 2 | 0:08–0:20 | Swipe through onboarding; tap **"Empezar a aprender"** | "Across Spanish-speaking Latin America, hearing families rarely get to practice LSC, Colombian Sign Language. Courses are scarce, interpreters are busy, and most learning material is static." |
| 3 | 0:20–0:38 | **Aprender** tab: scroll the serpentine 4-unit tree (Alfabeto y saludos → Comida y animales); tap Unit 1; answer one recognize exercise — hearts HUD visible; land on the lesson-end screen (XP, precision, streak, chest) | "Signo teaches LSC like a game: a four-unit path from the alphabet to food and animals, built on a certified interpreter's curriculum. Recognize and match exercises, hearts, XP, streaks — and a review queue that recycles the signs you miss." |
| 4 | 0:38–0:48 | Dictionary: app-bar action on Aprender; type **"hola"**; open a sign detail card | "All 175 signs live in a searchable visual dictionary." |
| 5 | 0:48–1:10 | **Traductor** tab: type **"hola, ¿cómo estás?"**; translate; the sequence player shows Secuencia 1/4 — tap play, tap the 0.75x chip, tap the TTS speaker; then tap a pictogram quick-phrase chip | "The star feature: type any Spanish sentence and Signo translates it into an LSC sign sequence — completely offline. A grammar engine drops copulas, fronts time expressions, and reorders the phrase the way LSC actually works. Each sign plays with progress, speed control, and text-to-speech, and quick-phrase buttons translate common needs instantly." |
| 6 | 1:10–1:25 | **Premium** tab: paywall with the pricing tiles and amber "7 días gratis" badge; scroll to the **"Powered by RevenueCat"** footer; tap **"Empezar 7 días gratis"** — PRO-active card with infinite hearts appears | "Premium unlocks infinite hearts and every module — 49.99 a year with a seven-day free trial, or 9.99 a month, powered by RevenueCat. Entitlements gate the whole experience, and with no key configured the app runs a keyless demo, so you can try PRO right now." |
| 7 | 1:25–1:38 | Profile tab: stats grid; flip the large-text accessibility toggle; end card: repo URL + "MIT licensed" + "Built for RevenueCat Shipaton 2026 — Next Gen Award" | "Signo is built by a student developer with an interpreter-designed curriculum, and it's accessible — large text, reduced motion, big touch targets. It's open source, MIT licensed, and ready to grow. Signo — speak with your hands." |

## Production notes

- **Capture**: 1179x2556 device or emulator, frameless, 30 fps minimum, screen
  recording of a `flutter run` build. Keep every tap deliberate — judges must
  see real interaction.
- **Translator scene honesty**: lesson and translator signs currently render as
  gloss cards (curated video clips land separately). Show the real screen; if
  clips land before recording, the same flow plays video — same script, richer
  demo.
- **Never show API keys.** The demo is keyless by design; the paywall runs in
  demo mode with its sandbox notice visible — show it, it is a feature.
- **End card content**: repo URL, "MIT License", "RevenueCat Shipaton 2026 —
  Next Gen Award", team credit: certified LSC interpreter + Deaf collaborator.

## Requirement checklist

- [ ] Under 2 minutes (script ~90 s)
- [ ] Public YouTube/Vimeo link pasted on Devpost
- [ ] Shows the real app on a device
- [ ] English narration (Spanish UI covered by the translation)
- [ ] Paywall + "Powered by RevenueCat" visible on screen
- [ ] Final recording sign-off by Paulo (BLOCKED-USER)
