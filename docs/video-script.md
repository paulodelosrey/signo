# Signo — Devpost demo video script

Target length: **95 seconds**. Shipaton's rule is *less than two minutes*, and
judges are not required to watch beyond two.

Voiceover: English. On-screen UI: Spanish — the app's language. The English
narration doubles as the required English translation.

## How to record

**Record each scene as its own file.** Seven files, 8 to 21 seconds each. The
voice track is merged over the screen capture afterwards, so a line you did not
like costs you twenty seconds to redo, not the whole take.

- Record in the quietest room you have, phone or mic **15–20 cm from your mouth**
- Leave **2 seconds of silence** at the start and end of every file — the merge
  needs room to trim
- Pace: **calm, not rushed.** The word counts below already fit the timing, so if
  you are running long you are going too fast, which is worse than sounding slow
- Slips are fine. Pause, breathe, restart the sentence from its beginning

## Pronunciation

| Written | Say |
|---|---|
| LSC | "el-ese-ce" — do not spell out one letter at a time |
| Colombian Sign Language | "co-lom-BEE-an" (stress on **BI**) |
| MIT licensed | "M-I-T licensed" |
| RevenueCat | "REV-en-you-cat" |
| 49.99 / 9.99 | "forty-nine ninety-nine" / "nine ninety-nine" — never say the dot |

## Scenes

Word counts are exact. Duration is measured at ~130 words per minute, which is a
comfortable documentary pace.

---

### 1 — Cold open · 17 words · **~8 s**

> What if your phone could help you talk with a Deaf friend — in their own
> language?

*Screen: app title, then straight to the Aprender tab.*

---

### 2 — The problem · 28 words · **~13 s**

> Across Latin America, hearing families rarely get to practice LSC — Colombian
> Sign Language. Courses are scarce, interpreters are busy, and most material is
> a static list of words.

*Screen: onboarding pages, tap "Empezar a aprender".*

---

### 3 — The learning path · 37 words · **~17 s** ← *the most important scene*

> Signo teaches LSC like a game, across five units. And every sign you can
> practice is a sign you can watch — one rule decides what reaches the path, so
> a sign with no video never gets taught.

*Screen: show UNIDAD 1 and UNIDAD 2. Tap the active node. **A sign must actually
be playing on screen here.** Hearts HUD visible.*

---

### 4 — The dictionary · 27 words · **~13 s**

> The dictionary holds the whole course and states its own coverage instead of
> hiding the gap. Here is what plays today — and this is what does not.

*Screen: open the dictionary. Let **"201 señas · 158 con video"** sit on screen
for a beat. Then open a clip-less sign.*

**Do not say "158 of 201" out loud.** The screen states the coverage by itself,
and the clip-less signs answer the follow-up on their own — *"Vídeo no
disponible por ahora, estamos produciendo los vídeos restantes."* Raising the
objection in the narration asks a question a 95-second video cannot answer.

---

### 5 — The translator · 46 words · **~21 s**

> The star feature: type any Spanish sentence and Signo turns it into an LSC
> sign sequence, completely offline. A grammar engine drops copulas, fronts time
> expressions and reorders the phrase the way LSC actually works. Each sign plays
> with speed control and text-to-speech.

*Screen: tap the "buenas tardes" quick phrase. The sequence player must be
playing. Try play/pause, the next-sign arrow, the 0.75× chip.*

---

### 6 — Premium · 25 words · **~12 s**

> Premium unlocks infinite hearts — forty-nine ninety-nine a year, or
> nine ninety-nine a month, powered by RevenueCat. Each button buys the plan it
> names.

*Screen: the paywall, both plan tiles, scroll to the "Powered by RevenueCat"
footer.*

---

### 7 — End card · 22 words · **~10 s**

> Open source, M-I-T licensed. Built by a student with a certified interpreter
> and a Deaf collaborator. Signo — speak with your hands.

*Screen: repo URL, MIT license, RevenueCat Shipaton 2026 — Next Gen Award.*

**Keep this credit.** Say "with", never "alongside" or "with a team of" —
"alongside" reads as a multi-person team, and Next Gen is a student-only
category. This framing is honest and it also answers "how do you know this LSC is
real?" before anyone asks.

---

**Total: 202 words · ~95 seconds**

## Production notes

- **Capture at 1080×2436** (the dev build's native size) or 1179×2556. Frameless,
  30 fps if your phone's recorder achieves it.
- **Live RevenueCat, not a sandbox.** The paywall shows the real plans and the
  RevenueCat footer. Nothing in the take may imply a simulated purchase.
- **Do not clear app data before recording.** The path must already show two
  units, otherwise scene 3's "five units" has nothing behind it.
- **Never show API keys.** Injected at build time via `--dart-define`; they live
  in an ignored `secrets.local.json`.
- **No copyrighted music.** Royalty-free or none. Third-party trademarks are
  disallowed in the video.
- Before recording, silence whatever notification keeps pulling the shade down —
  if it appears mid-take it ruins the shot.

## Requirement checklist

- [ ] Seven audio files, under 95 seconds total
- [ ] Public YouTube or Vimeo link
- [ ] Real device footage
- [ ] English narration covering the Spanish UI
- [ ] A sign visibly PLAYING (scene 3) — not a still frame
- [ ] "Powered by RevenueCat" visible on screen (scene 6)
- [ ] Repo URL, MIT license, category on the end card