# Signo — Devpost demo video script (~95 s)

Target length: **95 seconds** (Shipaton hard cap: *less than two minutes*; judges
are not required to watch beyond two minutes).
Voiceover: English. On-screen UI: Spanish — the app's language. The English
narration doubles as the required English translation of the Spanish UI.

> Recording is **BLOCKED-USER**: Paulo signs off before the take.

## What changed since the first draft

This script was written when the app shipped 63 clips for 59 signs across three
units, and the production notes below told the camera to shoot a demo **without
video**. That is no longer the app. All three notes are corrected here, because
following the old ones would have filmed the version that hides the point:

- 198 clips are bundled. 201 signs, **158** with a real clip, **5 units**, 112
  playable on the path. Lesson and translator signs **play video**.
- The paywall is **live RevenueCat**. There is **no sandbox notice** and the demo
  must not claim one. "Powered by RevenueCat" is visible on the paywall.

## The one message

> **Every sign you can practice is a sign you can watch.**

**Do not say "158 of 201" out loud.** It invites the question *"and the other
43?"*, which a 95-second video cannot answer, and the denominator is not really
"201 signs" — the course also lists rows that are pictures, not signs. The
screen states the coverage on its own when the dictionary appears, and the app
answers the follow-up by itself: the clip-less signs say *"Vídeo no disponible
por ahora — estamos produciendo los vídeos restantes."* Let the product raise
the objection and answer it; do not raise it in the narration where it is
unanswerable.

## Scene plan

| # | Time | Screen / state | Voiceover (English) |
|---|------|----------------|---------------------|
| 1 | 0:00–0:08 | Cold open: app title, then straight to the Aprender tab | "What if your phone could help you talk with a Deaf friend — in their own language?" |
| 2 | 0:08–0:20 | Onboarding pages 1–2, tap **"Empezar a aprender"** | "Across Spanish-speaking Latin America, hearing families rarely get to practice LSC, Colombian Sign Language. Courses are scarce, interpreters are busy, and most learning material is a static list of words." |
| 3 | 0:20–0:40 | **Aprender**: scroll the serpentine path — show **UNIDAD 1 Saludos y expresiones** and **UNIDAD 2 Números, colores y familia**; tap the active node; the recognize exercise **plays the sign on video**; hearts HUD visible; land on the lesson-end screen (XP, precision, streak, chest) | "Signo teaches LSC like a game: a five-unit path built on a certified interpreter's curriculum. Every sign you can practice is a sign you can watch — one rule decides what reaches the path, and a sign with no video never gets taught. Recognize and match exercises, hearts, XP, streaks, and a review queue that recycles the signs you miss." |
| 4 | 0:40–0:52 | **Dictionary**: open it, let the coverage line **"201 señas · 158 con video"** sit on screen for a beat; then search **"gracias"** and open a detail card that plays | "The dictionary holds the whole course, and it states its own coverage instead of hiding the gap — here is what plays today, and this is what does not." |
| 5 | 0:52–1:14 | **Traductor**: tap the **"buenas tardes"** quick phrase; the sequence player shows **Secuencia 1/1** with the clip playing; tap play/pause, the next-sign arrow, the 0.75× chip and the TTS speaker | "The star feature: type any Spanish sentence and Signo translates it into an LSC sign sequence, completely offline. A grammar engine drops copulas, fronts time expressions and reorders the phrase the way LSC actually works. Each sign plays with progress, speed control and text-to-speech." |
| 6 | 1:14–1:28 | **Premium**: the paywall with both plan tiles, scroll down to the **"Powered by RevenueCat"** footer | "Premium unlocks infinite hearts and every module — forty-nine ninety-nine a year with a seven-day trial, or nine ninety-nine a month, powered by RevenueCat. Each button buys the plan it names: the hosted paywall is server-configured, so the monthly tap resolves to the monthly package or fails loudly, never quietly billing an annual." |
| 7 | 1:28–1:38 | End card: repo URL, "MIT licensed", "RevenueCat Shipaton 2026 — Next Gen Award" | "Signo is open source and MIT licensed. I built it as a solo student project — the course content comes from a certified interpreter, and the clips were recorded with a Deaf collaborator. Signo — speak with your hands." |

## Production notes

- **The video is the product.** The single most important shot is scene 3: a
  sign actually moving on the phone. Judges may judge on the video alone. Do not
  rush it and do not let a tap land somewhere accidental.
- **Capture at 1179×2556**, frameless, 30 fps minimum. The dev build runs on a
  real TECNO CM6 at 1080×2436; the submission screenshots were rescaled to
  exactly 1179×2556, so the video can match them.
- **Live RevenueCat, not a sandbox.** The paywall shows the real plans and the
  RevenueCat footer. Nothing in the take should imply a simulated purchase.
- **Scene 3 needs the path to show two units**, so keep the earlier progress
  state — do not clear app data before recording, or the path opens on a single
  unit and the "five-unit" narration has nothing behind it.
- **Never show API keys.** They are injected at build time with `--dart-define`
  and live in an ignored `secrets.local.json`.
- **Credit on the end card**: keep it, and keep the framing. Say *the course
  content comes from* and *the clips were recorded with* — those are the sources
  of the material. Avoid "built alongside" or "co-founded": that phrasing reads
  as a multi-person team, and Next Gen is a student-only category. The app, the
  compiler and the whole pipeline are one student's work; the interpreter and the
  Deaf collaborator are what make the content trustworthy.
- **No copyrighted music.** Royalty-free or none. Third-party trademarks are
  disallowed in the video.

## Requirement checklist

- [ ] Under 2 minutes (script ~95 s)
- [ ] Public YouTube or Vimeo link, uploaded and unlisted/private cleared
- [ ] Real device footage of the app
- [ ] English narration covering the Spanish UI
- [ ] A sign visibly PLAYING (scene 3) — not a still frame
- [ ] "Powered by RevenueCat" visible on screen (scene 6)
- [ ] Repo URL, MIT license and category on the end card
- [ ] Final sign-off by Paulo (BLOCKED-USER)