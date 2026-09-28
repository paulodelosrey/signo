# Screen: inicio_de_sesi_n_y_onboarding

## 1. Screen identity
- **Folder:** `inicio_de_sesi_n_y_onboarding`
- **Purpose:** Pre-auth landing / onboarding: value prop, optional diagnostic test, goal & daily-commitment selection, and sign-in actions.
- **Place in flow:** First screen of the app (before account creation); no bottom nav — exits into the main tabs after auth.

## 2. Layout blueprint
```
┌ Row: [ASL (American) ● selected | LSC (Catalana/Col)]   [♿ accessibility btn]
├ Hero card: logo tile · Signo · chip · "Gestual & Expresivo" · 100% Visual badge
│            Headline · body · image deck (Sensor 21 Puntos / 60 FPS)
├ Section label row: ¿NO ERES PRINCIPIANTE?  ·  ⚡ 3 minutos
├ Diagnostic card (iris left rail): title, desc, arrow, skill chips
├ Goals card: ¿Cuál es tu objetivo? + 3 chips · Compromiso diario + 3 chips
├ Auth stack: Google · Apple · Iniciar con correo electrónico
├ Feedback pill: Optimize retroalimentación…
├ Legal paragraph (links) 
└ Version row: Signo v2.4.0 • CoreVision Neural Engine • Servidor en línea
```
No FAB, no bottom nav.

## 3. Exact on-screen text
| Text | Role |
|---|---|
| `ASL (American)` | Dialect option (selected) |
| `LSC (Catalana/Col)` | Dialect option |
| `Signo` | Brand title |
| `VISIÓN AI` | Brand chip (appears accented in PNG — see §9) |
| `Gestual & Expresivo` | Brand tagline |
| `100% Visual` | Streak-style badge |
| `Aprende y comunícate en lengua de señas con IA háptica y gamificación.` | Hero headline (`IA háptica` in mint) |
| `Retroalimentación en vivo de tus manos mediante visión artificial, micro-retos táctiles y lecciones adaptativas.` | Hero body |
| `Sensor 21 Puntos Listo` | Image overlay status |
| `60 FPS` | Image overlay chip |
| `¿NO ERES PRINCIPIANTE?` | Section label |
| `3 minutos` | Estimated time |
| `Test de Nivel Diagnóstico` | Card title |
| `Demuestra tus señas frente a la cámara y desbloquea el árbol...` | Card description (clamped) |
| `Dactilología` | Skill chip |
| `Verbos Espaciales` | Skill chip |
| `Clasific` | Skill chip (clipped in PNG) |
| `¿Cuál es tu objetivo?` | Goal prompt |
| `Paso 1 de 2` | Step indicator |
| `Familiares y Amigos` | Goal chip |
| `Trabajo & Inclusión` | Goal chip |
| `Cultura y Curiosidad` | Goal chip |
| `Compromiso diario de práctica` | Habit prompt |
| `15 min / día` | Current selection value |
| `5 min` / `Casual` | Minute chip |
| `15 min` / `Recomendado` | Minute chip (selected) |
| `20 min` / `Intensivo` | Minute chip |
| `Continuar con Google` | Auth button |
| `Continuar con Apple` | Auth button |
| `Iniciar con correo electrónico` | Auth button |
| `Optimizado para retroalimentación visual y vibratoria` | Feedback pill |
| `Al continuar, aceptas los Términos de Servicio y confirmas que has leído la Política de Privacidad de Signo. Desarrollado en colaboración con la comunidad sorda e intérpretes certificados.` | Legal caption (links mint) |
| `Signo v2.4.0` | Version |
| `CoreVision Neural Engine` | Engine info |
| `Servidor en línea` | Status (mint dot) |

## 4. Components inventory
| Element | Shape / approx size | State | Colors |
|---|---|---|---|
| Dialect segmented control | Pill group ≈h40 | ASL selected (filled), LSC default | Selected: iris fill `#4720CA` + mint pulse dot; unselected: gray text |
| Accessibility button | Circle ⌀≈40px | Default | Dark surface, mint icon |
| Brand logo tile | Rounded square ≈56px | Static | Mint fill, dark hand icon |
| `Vision AI` chip | Small pill | Default | Gray surface, light text |
| `100% Visual` badge | Pill h≈32 | Default | Dark pill, amber fire + text |
| Diagnostic card | Full-width card ≈h150 | Default/pressable | Dark card, iris left rail, iris icon tile, iris arrow circle |
| Skill chips ×3 | Small rounded chips | Static/check state | Dark chip, mint check |
| Goal chips ×3 | Vertical tiles ≈h88 | None selected in PNG (all default) | Dark tiles; icons mint / iris / amber |
| Minute chips ×3 | Vertical tiles ≈h72 | `15 min` selected | Selected: iris fill; others dark |
| Google / Apple buttons | Full-width pill h≈56 | Default | Elevated dark surface, light label |
| Email button | Full-width pill h≈56 | Default | Mint fill, dark label |
| Feedback pill | Pill ≈h36 | Static | Dark pill, mint vibration icon |
| Links | Inline text | Default | Light mint, underlined |

## 5. Color & theming
- **Background:** `#10131A` near-black body; cards on `#1D2027`/`#272A31`.
- **Mint `#00F0A8`:** logo tile, `IA háptica` highlight, sensor status, `3 minutos`, goal icon 1, email CTA, legal links, server dot, active nav (n/a here), pulse dot on ASL chip.
- **Iris `#7B61FF`-family:** selected ASL pill, `15 min` selected chip, diagnostic left rail/icon/arrow, `60 FPS` lavender text, section label `¿NO ERES PRINCIPIANTE?`.
- **Amber `#FFB800`:** `100% Visual` fire, `Cultura y Curiosidad` icon, `Compromiso` clock icon.
- **ANOMALY:** Google logo SVG hardcodes brand colors `#EA4335`, `#4285F4`, `#FBBC05`, `#34A853` — outside the Kinetic palette (third-party mark; likely intentional).
- **ANOMALY:** Apple logo uses pure black/white system mark — neutral, noted for completeness only.
- Goal chip icons' multi-colors come from Material icons (mint/iris/amber) — within palette families.

## 6. Gamification elements
- `100% Visual` amber badge (accessibility/streak-adjacent claim, not a numeric streak).
- Diagnostic shortcut framed as speed run: `⚡ 3 minutos`.
- Habit commitment picker with a `Recomendado` default (15 min/day) — retention mechanic.
- Skill chips with checkmarks implying unlocked/known competencies (`Dactilología`, etc.).
- No hearts/gems/XP counters on this screen (pre-auth).

## 7. Accessibility observations
- Dedicated always-visible accessibility button (♿) in the top row — non-audio discoverability.
- Feedback pill explicitly promises visual/vibratory (non-audio) feedback — aligned with deaf/HoH users.
- Mint-on-dark for `IA háptica` link-colored phrase and legal links: strong contrast; underline aids non-color recognition.
- Goal/minute chips: icon + text labels, large tap areas (≈3 cards per row, each ≈110×80px).
- Diagnostic description is line-clamped (`…`) in PNG — content truncated for sighted users.
- Small uppercase section label (`¿NO ERES PRINCIPIANTE?`) is iris on dark — adequate but small (≈12px).

## 8. PNG vs HTML discrepancies
- Third skill chip: PNG shows `Clasific` clipped at card edge; HTML full label is `Clasificadores`.
- Diagnostic description: PNG shows `…desbloquea el árbol...`; HTML continues `…el árbol avanzado directo al vocabulario fluido.` (2-line clamp).
- Brand chip: PNG appears to read `VISIÓN AI` (accented); HTML source is `Vision AI` (would render `VISION AI` uppercase) — possible divergence, see §9.
- No bottom nav in PNG — matches HTML (screen ends at version row).
- All auth/goal/minute labels and default selection (`15 min` iris) match HTML defaults.

## 9. Uncertainties
- `VISIÓN AI` accent presence in PNG — UNCERTAIN (small text); HTML has no accent.
- Whether `100% Visual` wraps to two lines in PNG vs single span in HTML — layout-only, UNCERTAIN.
- Goal chips: HTML `setGoal` would add a selected style on tap; PNG shows none selected — default state, but intended pre-selection is UNCERTAIN.
