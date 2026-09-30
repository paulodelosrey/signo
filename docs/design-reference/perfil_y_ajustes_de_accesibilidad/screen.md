# Screen: perfil_y_ajustes_de_accesibilidad

## 1. Screen identity
- **Folder:** `perfil_y_ajustes_de_accesibilidad`
- **Purpose:** User profile + accessibility/CV sensor settings + account/subscription management.
- **Place in flow:** **Perfil** tab (active in bottom nav); reached after login from the profile avatar.

## 2. Layout blueprint
```
┌ App bar: 🔥14 · 💎480 · ♡5 · [ASL|LSC] toggle · avatar
├ Hero card: avatar (mint ring + verified) · name · PRO chip · handle · level badge
├ Stats grid 2×2: Señas · Racha · Gemas · Liga
├ Insignias Destacadas · Ver todas (12) → horizontal badge carousel
├ Accesibilidad & Sensor CV card: 5 setting rows (4 toggles + dialect select)
├ Cuenta & Membresía: PRO card (Gestionar) · Cerrar Sesión button
└ Bottom nav: Aprender · Diccionario · Cámara CV · Ligas · Perfil
```
No FAB.

## 3. Exact on-screen text
| Text | Role |
|---|---|
| `14`, `480`, `5` | Header streak / gems / hearts |
| `ASL`, `LSC` | Header dialect toggle |
| `Sofía Morales` | Profile name |
| `Signo PRO` | Membership chip |
| `@sofia_signs • Desde nov. 2023` | Handle + join date |
| `Nivel 14 • Políglota de Señas` | Level badge |
| `142` / `Señas Domi…` | Stat card (label truncated) |
| `15 Días` / `Racha Activa` | Streak stat |
| `420` / `Gemas Total…` | Gems stat (label truncated) |
| `#4` / `LigaZafiro` | League stat (appears unspaced — see §9) |
| `Insignias Destacadas` | Section title |
| `Ver todas (12)` | Link button |
| `Dactilólogo` / `Veloz • Nv.3` | Badge 1 |
| `Simón Señas` / `Maestro 🎮` | Badge 2 |
| `Puente Vital` / `Oyente-Sordo` | Badge 3 |
| `Accesibilidad & Sensor CV` | Section title |
| `Vibración y Pulsos Hápticos` / `Siente el tempo y precisión sin audio` | Setting 1 |
| `Suave` / `Fuerte` | Intensity segments (`Fuerte` selected) |
| `Subtítulos Alto Contraste` / `Fondo oscuro reforzado para legibilidad` | Setting 2 |
| `Tamaño de texto` / `A-` / `Normal` / `A+` | Font-size control (`Normal`) |
| `Iluminación Asistida CV` / `Pantalla destella suave en baja luz` | Setting 3 |
| `Alertas Visuales Flash` / `Bordes luminosos al perder o ganar vidas` | Setting 4 |
| `Dialecto de Señas Base` / `Prioriza gramática e IA en lecciones` | Setting 5 |
| `ASL • American Sign Language (EE. UU.;` | Select value (right side clipped in PNG) |
| `Cuenta & Membresía` | Section title |
| `Suscripción Signo PRO` | Subscription title |
| `Renueva: 14 Dic 2024 (Anual)` | Renewal caption |
| `Gestionar` | Button label |
| `Cerrar Sesión` | Button label |
| `Aprender`, `Diccionario`, `Cámara CV`, `Ligas`, `Perfil` | Bottom nav |

## 4. Components inventory
| Element | Shape / approx size | State | Colors |
|---|---|---|---|
| Header stat pills ×3 | Rounded pills ≈h28 | Default | Dark fill; amber flame+14, mint diamond+480, red heart+5 |
| ASL/LSC toggle | Pill group | ASL selected | Iris fill / muted LSC |
| Avatar | Circle ⌀≈80px | Active, glow ring | Mint glow + mint verified badge |
| PRO chip | Small pill | Static | Iris fill, light label |
| Level badge | Rounded rect | Static | Dark chip, amber medal + text |
| Stat cards ×4 | Tiles ≈170×84 | Static | Dark surface; icons mint/amber/iris |
| Badge cards ×3 visible | Tiles ≈108×110 | Earned/unlocked | Mint/iris/amber icon circles |
| Toggles ×4 | Switch ≈48×28 | All ON | Mint track, dark knob right |
| Intensity segmented | 2-segment row | `Fuerte` selected | Selected mint; `Suave` dark |
| Font-size control | Row with 28px square buttons | `Normal` | Active label mint; buttons dark |
| Dialect `<select>` | Full-width ≈h36 | ASL selected | Dark fill, light text, chevron |
| PRO subscription card | Card row | Active | Dark card, iris icon tile |
| `Gestionar` | Small pill | Default | Light lavender fill, dark text |
| `Cerrar Sesión` | Full-width rect ≈h48 | Default | Dark fill, salmon/error label |
| Bottom nav | Bar h≈64px | Perfil active | Active mint; rest muted |

## 5. Color & theming
- **Backgrounds:** `#10131A` body; containers `#191C23`–`#272A31` ladder (Kinetic dark).
- **Mint `#00F0A8`:** header gems value, avatar glow/verified, `Fuerte`/`Normal` selections, ON toggles, badge meta (`Veloz • Nv.3`), active nav `Perfil`.
- **Iris `#7B61FF`-family:** ASL header chip, `Signo PRO` chip, PRO icon tile, `Gestionar` fill, league icon.
- **Amber `#FFB800`:** streak flame/14, level badge, `Racha` stat, `Puente Vital`, `Insignias` section icon.
- **Red `#FF3366`:** hearts `5`, `Alertas Visuales Flash` icon, `Cerrar Sesión` label (rendered salmon `#FFB4AB`-like).
- **ANOMALY:** platform emoji `🎮` in `Maestro 🎮` renders in OS colors outside palette (minor).
- No other off-palette flat fills observed.

## 6. Gamification elements
- Header: streak **14**, gems **480**, hearts **5** (note: gems conflict with stat card — §8/§9).
- Stats: `142` mastered signs, `15 Días` active streak, `420` total gems, league rank `#4`.
- Level badge: `Nivel 14 • Políglota de Señas`.
- Badge carousel: 3 earned badges with tier captions; HTML has a 4th locked badge (not visible in PNG).
- `Ver todas (12)` — total badge count.
- PRO membership chip and subscription card (premium gamification tier).
- No path nodes/progress rings/chests on this screen.

## 7. Accessibility observations
- Settings are the accessibility hub: haptics (audio-free feedback), high-contrast subtitles, font scaling (A-/A+), CV lighting, visual flash alerts for lives — all designed for non-audio feedback.
- Toggles show state via knob position **and** mint/dark fill (position redundancy helps).
- Intensity/font controls expose text state (`Fuerte`, `Normal`), not color alone.
- `Cerrar Sesión` uses error-colored text on dark — readable; destructive action is text+icon.
- Small caption labels (`Señas Domi…`, `Renueva: 14 Dic 2024`) are muted gray — borderline contrast at small size.
- Touch targets: toggles ≈48×28 (height slightly under 44px guideline); A-/A+ buttons ≈28×28 — below recommended 44×44 minimum.

## 8. PNG vs HTML discrepancies
- Header exists in HTML (line inside the minified head/body split) and matches PNG: **480** gems in header vs **420** in the stats card — internal value conflict is present in **both** PNG and HTML (also conflicts with 420 on other screens).
- Stat labels truncated in PNG (`Señas Domi…`, `Gemas Total…`) — matches HTML `truncate` class behavior; full strings `Señas Dominadas` / `Gemas Totales`.
- 4th badge `Traductor CV` / `Bloqueado` exists in HTML but is not visible in PNG (horizontal scroll off-frame).
- Dialect select text visually clipped at right edge: PNG `…(EE. UU.;` vs HTML option `ASL • American Sign Language (EE. UU.)`.
- `LigaZafiro` appears without space in PNG; HTML has `Liga Zafiro` — possible kerning/render artifact (see §9).
- Bottom nav items match this screen's HTML — but differ from the nav on ruta/práctica screens (cross-screen IA inconsistency, not a per-file bug).

## 9. Uncertainties
- `LigaZafiro` vs `Liga Zafiro` spacing in PNG — UNCERTAIN (truncate/rendering).
- Exact clipped character of the dialect select (`)` vs `;`) — UNCERTAIN; likely `)` cut off by container width.
- Renewal date `14 Dic 2024` is in the past relative to project context (2026) — stale mock data, intent UNCERTAIN.
- Header pill styles (material icons, `bg-surface-container-high`) differ from ruta/simón emoji pills — separate authored headers; intent UNCERTAIN.
