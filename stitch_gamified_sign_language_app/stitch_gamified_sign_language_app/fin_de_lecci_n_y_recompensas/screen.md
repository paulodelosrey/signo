# 1. Screen identity

Folder: `fin_de_lecci_n_y_recompensas` — lesson-complete results/rewards screen. Summarizes XP, precision, speed; celebrates streak; unlocks a reward chest; offers Continue or error review. Shown at the end of a practice session (modal-style: no bottom nav); entered after finishing a lesson.

# 2. Layout blueprint

```
[← Sesión De Práctica]              [avatar]
[     ( progress ring + medal ★ ✨ ) ]
[ 🤟 LSC • MÓDULO 2 COMPLETADO ]
¡Lección Superada!
¡Tus manos tienen ritmo natural! …
[ +35 XP ] [ 96% ] [ 2m 14s ]
[ TOTAL XP ] [ PRECISIÓN ] [ VELOCIDAD ]
[ bar  ] [ Cámara IA ] [ ¡Rápido! ]
[ 🔥 ¡Racha de 15 Días!     shield x2 ]
[ L M X J V S  D✓ ]
[ 💎 Cofre de Recompensas   +15 💎 ]
[       CONTINUAR → ]
[ ↺ Revisar 1 error de dactilología ]
```

# 3. Exact on-screen text

- App bar: `Sesión De Práctica`
- Chip: `LSC • MÓDULO 2 COMPLETADO`
- Title: `¡Lección Superada!`
- Subtitle: `¡Tus manos tienen ritmo natural! Has dominado 4 frases de conversación diaria.`
- Stats: `+35 XP`, `TOTAL XP`; `96%`, `PRECISIÓN`, `Cámara IA`; `2m 14s`, `VELOCIDAD`, `¡Rápido!`
- Streak: `¡Racha de 15 Días!`, `Tu hábito visual se mantiene imparable`, `x2`
- Week initials: `L`, `M`, `X`, `J`, `V`, `S`, `D`
- Chest: `Cofre de Recompensas`, `Bonus diario desbloqueado`, `+15`
- Buttons: `CONTINUAR` (with → icon); `Revisar 1 error de dactilología`

# 4. Components inventory

- Back button: 44px circle, dark, default.
- Progress ring: ~112px, mint arc (~90%) on dark track + mint medal icon — active/near-complete; amber star badge (top-right) and iris sparkles badge (bottom-left) — decorative default.
- Module chip: full-round dark, mint text — completed state.
- Stat cards ×3: ~110×140px rounded-xl, default; XP card contains mint 80% mini progress bar (active).
- Streak tile row: 7 × ~36px rounded-lg; L–S = fire icons (completed), `D` = amber check tile w/ glow (today, active).
- Shield `x2` chip: small pill, iris — active boost.
- Chest row: 48px iris diamond tile + `+15` gem pill — unlocked state.
- `CONTINUAR`: full-width 56px mint pill with 3D rim (`#006847` in HTML) — primary.
- `Revisar…`: full-width 48px dark pill — secondary.

# 5. Color & theming

Bg `#10131A`; mint `#00F0A8` on ring, title, `+35 XP`, CONTINUAR, progress; amber on star badge, `2m 14s`, fire icons, today's check; iris on sparkles badge, chest tile, shield `x2`, `96%`/`Cámara IA`; red not used. Headline/body type matches Space Grotesk / Plus Jakarta Sans. **ANOMALY:** pale iris texts/tile (`#E5DEFF`, `#C9BFFF`) and deep violet `#4720CA` chest tile are iris-family but outside exact `#7B61FF`. **ANOMALY:** CTA rim `#006847` dark green not in Kinetic set.

# 6. Gamification elements

XP gain `+35 XP` with mini progress ring/bar; precision and speed badges; streak `¡Racha de 15 Días!` with 7-day tracker + streak freeze `x2` shield; reward chest `Cofre de Recompensas` granting `+15` gems; module completion chip. No hearts/path nodes on this screen; header omits the usual streak/gems/hearts HUD.

# 7. Accessibility observations

Completion state redundantly encoded (ring + medal + check + bold text). Streak days use fire vs check shape difference, not color alone. Big CTA ≥56px — good target; back button 44px OK. `¡Rápido!` and `x2` provide non-audio reinforcement. Subtitle contrast (`#B9CBBF`-level on dark) is adequate but muted.

# 8. PNG vs HTML discrepancies

- Confetti: HTML spawns 28 animated particles via JS; PNG shows none (likely post-animation static capture) — noted, not missing content.
- Button label: HTML `Continuar` rendered uppercase via CSS → PNG `CONTINUAR` — consistent.
- Stat card bolt icon: PNG reads amber/orange; HTML styles it `text-primary-container` (mint) — **possible mismatch**, see §9.
- No other text/state differences found; all strings match verbatim.

# 9. Uncertainties

- UNCERTAIN: bolt icon hue in `+35 XP` card (amber in PNG vs mint per HTML).
- UNCERTAIN: exact ring completion percentage (HTML `stroke-dashoffset` ≈ 93%; PNG visually ~90%).
- UNCERTAIN: whether star/sparkles badges are static or animated in the live build.
