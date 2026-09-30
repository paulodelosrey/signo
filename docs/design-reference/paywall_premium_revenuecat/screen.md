# Screen: paywall_premium_revenuecat

## 1. Screen identity
- **Folder:** `paywall_premium_revenuecat`
- **Purpose:** Premium subscription paywall (RevenueCat monetization) selling Signo PRO with trial CTA.
- **Place in flow:** Modal/stack screen reached from the **Premium** nav entry or upgrade prompts; has back + close affordances; no bottom nav.

## 2. Layout blueprint
```
┌ App bar: [←] · logo · Premium Paywall · avatar
├ Utility row: RESTAURAR COMPRAS · [✕]
├ Hero: glowing medal badge (+ gem accent) · SIGNO PRO MEMBERSHIP chip
│        H2 · RevenueCat subtitle
├ Feature list ×5 (icon · title ✓ · description)
├ Plans: [🔥 MÁS POPULAR • AHORRA 50%]
│        Anual (selected) $49.99/año · Mensual $9.99/mes
├ CTA: COMENZAR PRUEBA GRATUITA DE 7 DÍAS
│      lock note
└ Legal: cancel copy · Términos de Uso • Política de Privacidad
```
No FAB, no bottom nav.

## 3. Exact on-screen text
| Text | Role |
|---|---|
| `Premium Paywall` | App bar title |
| `RESTAURAR COMPRAS` | Restore button (uppercase) |
| `SIGNO PRO MEMBERSHIP` | Eyebrow chip |
| `Aprende y Comunícate sin Límites` | H2 headline |
| `Potenciado por RevenueCat con acceso total e inmediato a todas las funciones avanzadas.` | Subtitle |
| `Módulos y Dialectos Ilimitados` | Feature 1 title |
| `Acceso sin restricciones a ASL, LSC y catálogo completo de expresiones visuales.` | Feature 1 body |
| `Traducción en Vivo Computer Vision` | Feature 2 title |
| `Cámara inteligente en tiempo real con análisis esquelético de 21 articulaciones.` | Feature 2 body |
| `Vidas y Corazones Infinitos` | Feature 3 title |
| `Equivócate, corrige y practica a turritmo sin interrupciones ni tiempos de espera.` | Feature 3 body (PNG shows `turritmo` — see §8) |
| `Repetición Espaciada con IA` | Feature 4 title |
| `Métricas de fluidez adaptativas que predicen cuándo reforzar cada signo.` | Feature 4 body |
| `Modo Offline Total` | Feature 5 title |
| `Descargalecciones enteras para practicar en viajes, metro o áreas sin cobertura.` | Feature 5 body (PNG appears unspaced — see §8) |
| `MÁS POPULAR • AHORRA 50 %` | Plan highlight badge (space before `%` UNCERTAIN) |
| `Anual` | Plan name (selected) |
| `7 días de prueba gratis` | Annual caption |
| `$49.99 / año` | Annual price |
| `$4.16 / mes` | Effective monthly price |
| `Mensual` | Plan name |
| `Facturación flexible` | Monthly caption |
| `$9.99 / mes` | Monthly price |
| `Sin compromiso` | Monthly note |
| `COMENZAR PRUEBA GRATUITA DE 7 DÍAS` | Primary CTA |
| `Sin cobro hasta terminar el período de prueba` | CTA reassurance |
| `Cancela cuando quieras en App Store / Google Play sin penalizaciones.` | Legal caption |
| `Términos de Uso` | Legal link |
| `Política de Privacidad` | Legal link |

## 4. Components inventory
| Element | Shape / approx size | State | Colors |
|---|---|---|---|
| Back button | Circle ⌀≈44px | Default | Dark surface, light arrow |
| Close (✕) button | Circle ⌀≈40px | Default | Dark surface |
| Restore pill | Pill ≈h32 | Default | Dark pill, mint sync icon, uppercase label |
| Hero medal | Circle ⌀≈96px + inner ⌀64 | Static, pulsing glow | Amber medal on dark; mint gem accent bottom-right |
| Membership chip | Pill | Static | Dark chip, mint dot + mint uppercase text |
| Feature cards ×5 | Full-width cards ≈h76 | Static | Dark surface, emoji tile 40px, mint ✓ badges |
| Annual plan card | Card, highlighted | **Selected** (mint check radio) | Elevated dark card; amber free-trial caption |
| Monthly plan card | Card | Unselected (empty radio) | Flat dark card; radio gray |
| Highlight badge | Pill over annual card | Active | Mint fill, dark uppercase text + 🔥 |
| CTA | Full-width pill h≈56 | Default | Mint fill, dark uppercase label + ⚡ |
| Lock note | Inline row | Static | Light gray text, mint lock |
| Legal links | Underlined text buttons | Default | Light gray, underlined |

## 5. Color & theming
- **Background:** `#10131A` body; cards `#1D2027`/`#272A31` (Kinetic dark ladder).
- **Mint `#00F0A8`:** membership chip, all feature ✓ badges, `MÁS POPULAR` badge, selected radio, CTA, lock icon, restore icon, ambient halo tint.
- **Iris `#7B61FF`-family:** subtle hero halo gradient stop (`secondary-container/20`); no strong iris focal element.
- **Amber `#FFB800`:** hero medal glow, optional badge-dot accents.
- **Red `#FF3366`:** only via ❤️ emoji on the infinite-lives feature.
- **Cyan:** gem accent renders mint-teal (`surface-tint #00E29E` family), not `#00D2FF`.
- **ANOMALY:** feature-row emoji (🔓👁️❤️🧠📶) render in OS palette colors — notably ❤️ red and 📶 orange differ from Kinetic tokens; uncontrolled.
- No other off-palette flat colors observed.

## 6. Gamification elements
- Hero trophy/medal + floating gem — premium reward symbolism.
- Feature selling gamification itself: unlimited hearts (`Vidas y Corazones Infinitos`), spaced repetition, streak-adjacent fluency metrics.
- Savings badge `AHORRA 50 %` with fire icon (urgency motif).
- Trial framing: `7 días de prueba gratis`, `COMENZAR PRUEBA GRATUITA DE 7 DÍAS`.
- No live streak/XP/gem counters in the app bar of this screen.

## 7. Accessibility observations
- CTA is large (h≈56px), uppercase, dark-on-mint — high contrast and clear primary action.
- Plan selection uses check-circle vs empty-circle (shape difference, not color-only).
- Legal links underlined — non-color affordance.
- Feature rows: icon + bold title + body — scannable hierarchy; ✓ seals redundant with titles.
- Restore/close are standard size (≈40–44px) circles — adequate targets.
- `RESTAURAR COMPRAS` is small uppercase tracked text — low-ish emphasis but legible on dark.
- Toast feedback (HTML) is visual-only — consistent with non-audio UX.

## 8. PNG vs HTML discrepancies
- Feature 3 body: PNG reads `practica a turritmo`; HTML has `practica a tu ritmo` — visible spacing/typo divergence in PNG.
- Feature 5 body: PNG reads `Descargalecciones enteras…`; HTML has `Descarga lecciones enteras…` — PNG appears to drop the space.
- Highlight badge: HTML `AHORRA 50%`; PNG appears `AHORRA 50 %` (possible extra space) — minor.
- `$4.16 / mes`: may show a strikethrough-like line in PNG; HTML has no `line-through` — UNCERTAIN if artifact (see §9).
- Hidden toast (`Procesando suscripción...`) not visible in PNG — matches default `opacity-0`.
- App bar (back, title, avatar) and utility row match HTML structure; no bottom nav in either.
- Monthly-plan alternate CTA copy (`Suscribirme por $9.99 USD / Mes`) exists only as JS state — not applicable to PNG.

## 9. Uncertainties
- `$4.16 / mes` strikethrough presence in PNG — UNCERTAIN.
- `turritmo` / `Descargalecciones`: whether PNG truly renders joined glyphs or JPEG-like kerning illusion — transcribed as visible; HTML disagrees — UNCERTAIN on root cause.
- Exact space in `AHORRA 50 %` — UNCERTAIN.
- Hero medal icon: PNG shows an award/rosette; HTML `workspace_premium` — same intent, exact glyph may vary by Material font build — UNCERTAIN.
