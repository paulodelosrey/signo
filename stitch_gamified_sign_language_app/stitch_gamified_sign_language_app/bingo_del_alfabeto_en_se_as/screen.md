# 1. Screen identity

Folder: `bingo_del_alfabeto_en_se_as` — live multiplayer fingerspelling bingo. Players stamp called letters on a 3×3 personal card. Occupies the `Bingo` tab between Práctica and Traductor in the game loop; reinforces alphabet recall under time pressure.

# 2. Layout blueprint

```
[logo] [ASL LSC] [14][420][5] [avatar]
[Ronda Rápida • Sala 3] [● EN VIVO]   [⏱ 00:39]
¡Bingo Dactilológi…
[ CARTA CANTADA           Pulso Háptico ]
[ (M hand circle) Letra M /eme/ ]
[ description… | Previas: A F L B ]
[ ⚡ ¡A 1 seña de BINGO en diagonal!…  x2 Puntos ]
[ Tu Cartón Personal          3 / 9 selladas ]
[  A*  B  L* ]   (* = stamped star overlay)
[  C  M!  D ]    (M = target, ¡TOCA!)
[  E  O*  S ]
[ 🎉 ¡CANTAR BINGO!  1200 XP ]
[ Pistas (-5 💎) ] [ Ver en LSC ]
[ Aprender | Práctica | Bingo | Traductor | Premium ]
```

# 3. Exact on-screen text

- Header: `ASL`, `LSC`, `14`, `420`, `5`
- `Ronda Rápida • Sala 3`, `EN VIVO`, `¡Bingo Dactilológi…` (truncated title), `00:39`
- `CARTA CANTADA`, `Pulso Háptico`
- `Letra M`, `/eme/`
- `Tres dedos doblados sobre el p…` (truncated)
- `Previas:`, letters `A`, `F`, `L`, `B`
- Banner: `¡A 1 seña de BINGO en diagonal!…` (truncated), `x2 Puntos`
- `Tu Cartón Personal`, `3 / 9 selladas`
- Cell letters: `A`, `B`, `L`, `C`, `M`, `D`, `E`, `O`, `S`; `ASL` labels on unstamped cells; `¡TOCA!` on M
- `¡CANTAR BINGO!`, `1200 XP`
- `Pistas (-5 💎)`, `Ver en LSC`
- Nav: `Aprender`, `Práctica`, `Bingo`, `Traductor`, `Premium`

# 4. Components inventory

- Room/live chips: full-round; violet `Ronda…` chip, dark `EN VIVO` chip w/ mint pulse — default.
- Timer pill: full-round dark, `00:39` white — active countdown.
- Caller circle: ~96px, ring + ping halo, mint `M` pill — active/target.
- `Pulso Háptico`: pill toggle, mint dot = on — active.
- Bingo cells: ~square, ~110px, rounded-lg; states: default (dark, `ASL`), stamped (mint-tinted overlay + mint star circle), target (elevated, mint `M`, pulse dot, `¡TOCA!` chip).
- Win banner: rounded-xl amber, `x2 Puntos` chip — informational.
- `¡CANTAR BINGO!`: full-width ~56px amber pill, `1200 XP` chip, lavender under-rim — primary/active.
- `Pistas` / `Ver en LSC`: ~44px pills, default.
- Bottom nav: `Bingo` active mint; others default.

# 5. Color & theming

Bg `#10131A`; mint `#00F0A8` on stamps/target/live dot; amber `#FFB800`-family on banner, CTA, timer accents; iris on `ASL` chip & `Pistas` icon; red not used. **ANOMALY:** CTA under-rim `#BAAEFF` (HTML) is pale iris, outside exact `#7B61FF`. **ANOMALY:** violet room chip `#4720CA` outside exact iris. Emoji glyphs (⏱️, 💎, ⚡, 🎉) mix with Material icons — stylistic mix, not palette-breaking.

# 6. Gamification elements

Streak `14`, gems `420`, hearts `5`; XP reward badge `1200 XP`; gem cost `(-5 💎)`; `x2 Puntos` multiplier; stamped-star progress `3 / 9`; live round timer; previous-calls history. No path nodes/rings/chests.

# 7. Accessibility observations

Target cell uses color + pulse dot + `¡TOCA!` label (strong non-audio cue); stamped cells dim underlying image but keep star token. `Pulso Háptico` toggle explicitly surfaces vibration visually. Touch targets: cells ≥90px good; chips ~30px small. Timer and `EN VIVO` rely on motion — static users get color cues only.

# 8. PNG vs HTML discrepancies

- Timer: PNG `00:39` vs HTML initial `00:42` (HTML counts down each second — expected drift).
- Title truncated in PNG (`¡Bingo Dactilológi…`); HTML string is `¡Bingo Dactilológico!`.
- Caller description truncated in PNG; HTML full text is `Tres dedos doblados sobre el pulgar extendido.`
- HTML success banner (`¡Letra 'M' Sellada con éxito!`) is hidden until interaction — absent in PNG (expected).
- No label/state mismatches otherwise; stamped set A/L/O and target M match HTML.

# 9. Uncertainties

- UNCERTAIN: whether banner emoji `🎉` after "diagonal!" is present (text cut before it).
- UNCERTAIN: full title glyph count at truncation point.
- UNCERTAIN: exact timer frame offset vs HTML seed value.
