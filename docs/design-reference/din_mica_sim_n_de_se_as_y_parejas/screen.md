# Screen: din_mica_sim_n_de_se_as_y_parejas

## 1. Screen identity
- **Folder:** `din_mica_sim_n_de_se_as_y_parejas`
- **Purpose:** Practice screen combining a Simon-style sign sequence game with a sign↔word pairing mini-game.
- **Place in flow:** **Práctica** tab (active in bottom nav); mid-round gameplay (`Ronda 3`) with session progress bar and local hearts.

## 2. Layout blueprint
```
┌ Global app bar: logo · ASL/LSC · 🔥14 · 💎420 · ❤️5 · avatar
├ Session bar: [✕] · mint progress bar (~60%) · ❤️ 4
├ Chip: ⚡ DESAFÍO RÁPIDO
├ H1 + subtitle (centered)
├ Simon wheel: 4 quadrant pads + center hub "ATENTO"
│   [HOLA] [GRACIAS]
│   [POR FAVOR] [AMIGO]
├ Button: Repetir Secuencia Simón
├ Match card: Modo Relacionar Señas + combo badge
│   Left column: SEÑA #1–#3   Right column: Comida/Casa/Familia
├ Full-width CTA: ¡COMPROBAR RESPUESTA!
└ Bottom nav: Aprender · Práctica · Bingo · Traductor · Premium
```

## 3. Exact on-screen text
| Text | Role |
|---|---|
| `ASL`, `LSC` | Header dialect toggle |
| `14`, `420`, `5` | Header streak/gems/hearts |
| `4` | Session hearts count |
| `DESAFÍO RÁPIDO` | Round type chip |
| `Ronda 3: ¡Simón de Señas!` | Screen title |
| `Observa la secuencia de colores y repite las señas en el mismo orden.` | Instruction |
| `HOLA` / `ASL / LSC` | Green quadrant label / caption |
| `GRACIAS` / `Barbilla al frente` | Purple quadrant label / caption |
| `ATENTO` | Center hub status |
| `POR FAVOR` / `Círculo en pecho` | Amber quadrant label / caption |
| `AMIGO` / `Dedos índices` | Red quadrant label / caption |
| `Repetir Secuencia Simón` | Replay button |
| `Modo Relacionar Señas` | Match-game card title |
| `¡Racha x3!` | Combo badge |
| `+20 XP` | XP badge |
| `Toca una seña gráfica y luego su palabra correspondiente para enlazarlas:` | Instruction |
| `SEÑA #1` / `Techo en 'V'` | Sign card 1 |
| `SEÑA #2` / `Mano a la b…` | Sign card 2 (truncated in PNG) |
| `SEÑA #3` / `Círculo con …` | Sign card 3 (truncated in PNG) |
| `Comida`, `Casa`, `Familia` | Word bubbles |
| `¡COMPROBAR RESPUESTA!` | Primary CTA |
| `Aprender`, `Práctica`, `Bingo`, `Traductor`, `Premium` | Bottom nav |

## 4. Components inventory
| Element | Shape / approx size | State | Colors |
|---|---|---|---|
| Close (✕) button | Circle ⌀≈40px | Default | Dark surface, light icon |
| Session progress | Bar h≈14px, ~60% | In progress | Mint fill on dark track |
| Session hearts pill | Pill with ❤️ + `4` | Active, 4 left | Red icon/count on dark pill |
| Round chip | Pill | Default | Dark chip, mint ⚡ + text |
| Simon quadrants ×4 | Petal-shaped quarter pads in circle ⌀≈340px | Idle/default in PNG | Mint-teal, iris purple, amber/olive, red overlays |
| Center hub | Circle ⌀≈80px | Status `ATENTO` (eye icon) | Dark disk, mint icon/text |
| Ambient glow ring | Full circle blur behind wheel | Visible (warm amber in PNG) | Unclear token — see §9 |
| Replay button | Pill ≈h36 | Default | Dark pill, mint replay icon |
| Sign cards ×3 | Rounded rect ≈h64 | Default (none selected) | Dark card, colored icon tiles (mint/amber/iris) |
| Word bubbles ×3 | Rounded rect h≈48px | Default | Dark card, light text + touch icon |
| Combo badge | Pill | Active combo | Amber `¡Racha x3!`, mint `+20 XP` |
| CTA | Full-width pill h≈56 | Default | Mint→lighter mint gradient, dark label |

## 5. Color & theming
- **Backgrounds:** `#10131A` / `#12151C`-family surfaces throughout.
- **Mint `#00F0A8`:** session progress, `DESAFÍO RÁPIDO` text, HOLA pad, `ATENTO` icon, replay icon, `+20 XP`, CTA gradient start, active nav.
- **Iris `#7B61FF`-family:** GRACIAS quadrant, family sign icon.
- **Amber `#FFB800`:** POR FAVOR quadrant tone, racha badge, 🔥.
- **Red `#FF3366`:** AMIGO quadrant, hearts.
- **ANOMALY:** POR FAVOR quadrant renders as a muted olive/khaki (amber at low alpha over gray) — muddy tone that does not cleanly map to `#FFB800`; borderline outside the crisp Kinetic set.
- **ANOMALY:** platform emoji (❤️🔥) render in OS colors outside palette tokens.

## 6. Gamification elements
- Header streak **14**, gems **420**, hearts **5**; session-local hearts **4** (lives consumed).
- Session progress bar (~60%) for the round.
- Combo/streak badge `¡Racha x3!` with `+20 XP` reward teaser on the match card.
- Round framing: `Ronda 3`, `DESAFÍO RÁPIDO`.
- Feedback toasts (success `¡Excelente asociación visual!`, round-clear XP) exist only as hidden HTML states — not visible in PNG.

## 7. Accessibility observations
- Quadrant pads are large (≈150×200px each) — comfortable touch targets.
- Each pad pairs color with a distinct icon + unique text label (color is not the sole cue).
- Center hub gives a non-color status word (`ATENTO`) plus icon.
- Instruction copy is light-on-dark, centered, adequate size (≈16px).
- CTA label is bold uppercase dark-on-mint — high contrast.
- Sign-card captions truncate visually in PNG (`Mano a la b…`) — full text may be inaccessible without an accessible name.

## 8. PNG vs HTML discrepancies
- Center hub: PNG shows eye + `ATENTO`; static HTML default markup is `smart_display` + `Tu Turno`. `Atento` is set only after the JS sequence demo runs — PNG captured the post-demo state, not the HTML initial state.
- Sign card 2/3 captions truncated in PNG (`Mano a la b…`, `Círculo con …`); HTML full strings are `Mano a la boca` and `Círculo con 'F'` (CSS `truncate`).
- Ambient glow ring: HTML default is mint (`primary-container/40`); JS recolors it per pad. PNG shows a warm amber glow — captured mid/post sequence, not the static default.
- Hidden states not shown in PNG (expected): pair-success feedback row, mismatch disk flash, haptic-only effects.
- Nav labels/active tab match HTML.

## 9. Uncertainties
- Exact quadrant background hexes in PNG (heavy overlays) — UNCERTAIN whether they match token alphas as authored.
- Whether session hearts `4` vs header `5` is intentional design (session spend) — plausible but not documented in HTML — UNCERTAIN.
- Glow ring color attribution (yellow pad `#FFBA20` vs leftover state) — UNCERTAIN without animation timing.
