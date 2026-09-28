# Screen: ruta_de_aprendizaje_asl_y_lsc

## 1. Screen identity
- **Folder:** `ruta_de_aprendizaje_asl_y_lsc`
- **Purpose:** Main gamified learning path (Duolingo-style unit map) for LSC/ASL lessons.
- **Place in flow:** Post-login home under the **Aprender** tab (active in bottom nav); hub from which lessons, boss challenges, and the spaced-repetition review are launched.

## 2. Layout blueprint
```
┌ App bar: logo · ASL/LSC toggle · 🔥14 · 💎420 · ❤️5 · avatar
├ Dialect banner: [🇨🇴 LSC active]  [🇺🇸 ASL ▾]
├ Unit card: UNIDAD 1 · Módulo 1 de 6 · title · chest "Reclamar"
│            Progreso de la unidad 85% (bar)
├ Winding path (SVG connectors, vertical):
│   Node 1 completed → Node 2 completed → Active node (¡COMIENZA AQUÍ!)
│   → Bonus chest → Node 4 locked → BOSS node
├ Spaced-repetition card (Repetición Espaciada) + primary CTA
└ Bottom nav: Aprender · Práctica · Bingo · Traductor · Premium
```
No FAB. No visible modal/overlay.

## 3. Exact on-screen text
| Text | Role |
|---|---|
| `ASL`, `LSC` | Dialect toggle labels |
| `14`, `420`, `5` | Header stats (streak, gems, hearts) |
| `LSC • Señas Colombiana` | Dialect banner title |
| `Enfoque Bogotá / Medellín` | Dialect banner caption |
| `ASL` | Alt dialect button |
| `UNIDAD 1` | Unit badge chip |
| `• Módulo 1 de 6` | Unit meta caption |
| `Alfabeto y Saludos Básicos` | Unit headline |
| `Configuraciones de mano primarias y rasgos manuales` | Unit subtitle |
| `Reclamar` | Chest button label |
| `Progreso de la unidad` / `85%` | Progress caption / value |
| `Vocales en Señas` | Node 1 flyout label |
| `Lección 1` | Node 1 label |
| `Saludos: Hola y Adiós` | Node 2 flyout label |
| `Lección 2` | Node 2 label |
| `¡COMIENZA AQUÍ!` | Active-node pointer bubble |
| `Mi Nombre` | Active node title |
| `Sesión práctica con cámara` | Active node caption |
| `Cofre de Gemas` | Bonus chest title |
| `Toca para abrir` | Bonus chest caption |
| `+50 💎` | Bonus chest reward |
| `Preguntas Frecuentes` | Locked node flyout |
| `Lección 4` | Locked node label |
| `BOSS` | Boss node badge |
| `Desafío Rápido de Señas` | Boss headline |
| `Prueba con detector IA de 60 segundos` | Boss caption |
| `Repetición Espaciada` | Review card title |
| `URGENTE` | Urgency badge |
| `12` | Pending-review counter |
| `Algoritmo de retención visual activo` | Review card subtitle |
| `12 señas en riesgo de olvido` | Review info row |
| `+15 XP` | XP reward chip |
| `Repasar ahora (+15 XP)` | Primary button label |
| `Aprender`, `Práctica`, `Bingo`, `Traductor`, `Premium` | Bottom nav labels |

## 4. Components inventory
| Element | Shape / approx size | State | Colors |
|---|---|---|---|
| Dialect toggle (header) | Pill, h≈36px | ASL chip selected (iris) | `#4720CA`-like bg, light text |
| Stat pills ×3 | Rounded pills, ≈h28 | Default | Dark surface, emoji + number |
| Dialect banner | Full-width pill row | LSC selected (filled) | Iris fill / dark alt |
| Unit chest button | Square tile ≈56px + label | Unclaimed, amber badge dot | Amber icon on dark tile |
| Progress bar | Full-width, h≈12px | 85% filled | Mint fill, glow shadow |
| Completed nodes ×2 | Circle ⌀≈64px, 3D extrusion | Completed (check / wave icon) | Mint body, deep-mint base |
| Star pills | Pill above nodes | 3/3 stars filled | Amber stars on dark pill |
| Active node | Circle ⌀≈64px + ping ring | Active, bouncing bubble | Mint, mint glow |
| Bonus chest | Dashed rounded card ≈220×64 | Claimable | Amber dashed border, gift emoji |
| Locked node | Circle ⌀≈56px | Locked, 75% opacity | Gray surface, lock icon |
| Boss node | Circle ⌀≈80px + gradient halo | Locked/available milestone | Dark center, trophy amber; halo amber→mint→iris |
| Spaced-repetition card | Card, left iris border | Active urgency | Dark card, red badge |
| `Repasar ahora` CTA | Full-width pill, h≈52 | Default/pressable | Mint fill, dark-green label |
| Bottom nav | Bar h≈80px, 5 items | Aprender active | Active mint, rest muted gray |

## 5. Color & theming
- **Background:** near-`#10131A` app surface; raised cards `#1D2027`/`#272A31` family (Kinetic dark ladder).
- **Primary mint `#00F0A8`:** completed/active path nodes, progress bar, CTA, active nav item, path dashed connector, `¡COMIENZA AQUÍ!` bubble.
- **Iris/secondary:** header ASL chip, dialect banner fill, spaced-repetition card left border and `12` counter.
- **Amber `#FFB800`-family:** stars, unit chest, `Reclamar`, bonus chest, `+15 XP`, BOSS trophy/halo.
- **Red `#FF3366`-family:** hearts count, `URGENTE` badge (PNG renders vivid red — see §8).
- **Cyan:** only via 💎 emoji rendering, not a flat token.
- **ANOMALY:** platform emoji glyphs (🔥💎❤️🎁🧠) render in OS colors outside the controlled Kinetic palette (unavoidable with emoji, but not token-matched).

## 6. Gamification elements
- Header: streak **14** (flame), gems **420**, hearts **5**.
- Unit chest with notification dot + `Reclamar`; unit progress ring/bar at 85%.
- Path node states: completed (check, stars ★★★), completed (wave), active (pointer bubble + pulse), locked (lock, dimmed), BOSS milestone.
- Bonus chest: `+50 💎` on tap (HTML interaction; not shown claimed in PNG).
- Spaced-repetition: `URGENTE`, count **12**, `+15 XP` incentive.

## 7. Accessibility observations
- Mint CTA/nav active use dark labels on mint — strong contrast.
- Locked node uses opacity 75% + lock icon (icon redundancy, not color-only).
- Node captions `Lección 4`/`Sesión práctica…` are small (≈11–12px) and low-emphasis — marginal contrast (`on-surface-variant` on dark).
- Nav items: icon + text, min touch area ≈56×44px per HTML — meets target size.
- Stars, chest, and urgency combine icon + label (non-audio feedback is visual only).

## 8. PNG vs HTML discrepancies
- Hidden-by-default HTML layers absent in PNG as expected: dialect dropdown, lesson bottom-sheet modal (`Lección 3` / `Comenzar Lección Interactiva`).
- Chest tap results (`+50 Gemas Reclamadas` toast, alert) not shown — default state matches.
- `URGENTE` badge: PNG looks bright red with white text; HTML tokens are `error-container #93000A` bg + `error #FFB4AB` text — PNG appears brighter than token pair (possible render/snapshot difference).
- All other labels, order, and states match `code.html`.

## 9. Uncertainties
- Exact hue of header heart/gem numbers in PNG: appear near-white; HTML specifies light mint/salmon tokens — UNCERTAIN at screenshot scale.
- Whether the unit `Reclamar` chest is claimable or already partial-rewarded: only the amber dot is visible — UNCERTAIN.
- Avatar/logo are remote images; their intrinsic design vs PNG rendering not verifiable from HTML alone — UNCERTAIN.
