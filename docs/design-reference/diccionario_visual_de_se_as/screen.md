## Screen identity
`diccionario_visual_de_se_as`: LSC/ASL dictionary — active "Diccionario" tab; precedes sign detail ("Ver").

## Layout blueprint
Status bar → header stats/toggles/avatar → search+trends → dialect bar → category chips → 2×2 cards → CV stats → banner → bottom nav.

## Exact on-screen text
(status/clock/stats) "12:30", "14", "480", "5"; (toggles) "ASL", "LSC"; (placeholder) "Buscar palabra, seña o emoción..."; (label) "TENDENCIAS:"; (chips) "Gracias", "Ayuda", "¿Dónde?"; (segments) "LSC (Colombia)", "ASL (EE. UU.)"; (location) "Bogotá / Med."; (categories) "Más Buscadas", "Emergencias", "Salu".
(card 1: badge/thumb/speed/title/caption/tag/link) "Bucle 3D", "POR FAVOR", "1.0x", "Por Favor", "Palma al pecho circular", "Cortés", "Ver";
(c2) "Vital", "Lateral", "0.5x", "1x", "Hospital", "Cruz 'H' hombro...", "Salud", "Ver";
(c3) "En repaso", "3 pasos", "Familia", "Círculo con letra 'F'", "Básico", "Ver";
(c4) "Gesto facial", "1.0x", "Disculpa", "Puño cerrado en pecho", "Social", "Ver".
(panel heading/pill/body/stats) "Desglose Anatómico CV", "21 PUNTOS", "Cada entrada del diccionario incluye mapeo espacial tridimensional y corrección asistida por cámara en tiempo real.", "1,420+", "Señas 3D", "2 Dialectos", "LSC & ASL", "98.4%", "Precisión CV";
(banner heading/body/buttons) "¿No encuentras una seña?", "Pídela a la comunidad sorda local o genera una demostración inmediata con el Avatar IA de Signo.", "Generar con IA", "Comunidad";
(nav) "Aprender", "Diccionario", "Cámara CV", "Ligas", "Perfil".

## Components inventory
- Stat pills ×3: rounded-full ~28px; amber/teal/red.
- Segments: pills; active iris (ASL, LSC-Colombia).
- Search: pill ~48px, mint icon; mic/tune ~32px.
- Chips: pills; "Más Buscadas" mint-active.
- Cards ×4: rounded-xl; 144px thumb, badges, 28px bookmark, speed pill, title+dot, tag, mint "Ver".
- Banner: iris circle; mint + dark pills.
- Nav: 5 tabs 56×48px; active mint.

## Color & theming
BG ≈#10131A ✓. Mint: active chip/tab, "Ver", CTA. Iris: LSC pill, "En repaso", "2 Dialectos". Amber: streak, "98.4%", pin, "Gesto facial". Red: hearts, "Vital". Space Grotesk/Plus Jakarta Sans ✓. **ANOMALY**: "Salud", hearts text, Hospital dot ≈#FFB4AB, not red #FF3366.

## Gamification elements
Streak "14", gems "480", hearts "5"; pill "21 PUNTOS"; difficulty dots; "En repaso"/"3 pasos". No rings/XP bar/chests.

## Accessibility observations
Nav 56×48px OK; mic/tune ~32px & chips <44px. Mint-on-dark strong; gray captions dimmer (verify AA). Active = mint fill; truncation cues overflow.

## PNG vs HTML discrepancies
code.html present; text/structure match. PNG-only: status bar. HTML off-screen: "Familia", "Comida", "Trabajo" + full "Saludos" (scroller). Gem token #46ffb8 (mint) vs theme cyan (§9).

## Uncertainties
- "Cruz 'H' hombro..." tail UNCERTAIN (clamped); "Med." UNCERTAIN.
- Thumbnail watermarks UNCERTAIN (image content).
- Gem hue cyan-vs-mint UNCERTAIN.
