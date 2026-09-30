# 1. Screen identity

Folder: `ligas_y_tabla_de_clasificaci_n` — weekly league leaderboard. Shows division hero, ranked XP table with promotion/demotion cutoffs, and a community co-op challenge. Reached from the `Ligas` tab; drives competitive retention between lessons.

# 2. Layout blueprint

```
[14][420][5]            [ASL LSC] [avatar]
[ 🏅 DIVISIÓN ÉLITE ✓    ⏱ Termina en 1d 14h ]
[    Liga Zafiro                              ]
[ ↑ ¡Estás en la Zona de Ascenso… (Top 5) ]
[1 Mateo S.  Experto LSC …           1,420 XP]
[2 Elena Ruiz  Práctica Fluida …     1,310 XP]
[3 David Kim  Liga de Oro …          1,195 XP]
[4 Tú (Sofía M.) 14d +65 XP 980 XP +Entrenar]
[5 Carlos V.  En racha de 8 días …    920 XP]
[ —— ↑ Límite de Ascenso —— ]
[6 Nuria Pons  Vocabulario ASL …      870 XP]
[ —— ⚠ ZONA DE DESCENSO (ÚLTIMOS 5) —— ]
[26 Marcos B.  En riesgo de descender 310 XP]
[ DESAFÍO COMUNITARIO 82%  💎100 ]
[ 50,000 señas aprendidas en equipo ]
[ progress 41,000/50,000 …  ¡Meta cercana! ]
[ 🙌 Aportar señas al desafío ]
[ Aprender | Diccionario | Cámara CV | Ligas | Perfil ]
```

# 3. Exact on-screen text

- HUD: `14`, `420`, `5`, `ASL`, `LSC`
- `DIVISIÓN ÉLITE`, `Liga Zafiro`, `Termina en`, `1d 14h`
- `¡Estás en la Zona de Ascenso a Liga Diamante! (Top 5)` (`Zona de Ascenso` emphasized)
- Rows: `1` `Mateo S.` `Experto LSC` `24 lecciones` `1,420` `XP`; `2` `Elena Ruiz` `Práctica Fluida` `1,310` `XP`; `3` `David Kim` `Liga de Oro` `1,195` `XP`; `4` `Tú (Sofía M.)` `14 días` `+65 XP hoy` `980` `XP` `+ Entrenar`; `5` `Carlos V.` `En racha de 8 días` `920` `XP`
- `Límite de Ascenso`
- `6` `Nuria Pons` `Vocabulario ASL` `870` `XP`
- `ZONA DE DESCENSO (ÚLTIMOS 5)`
- `26` `Marcos B.` `En riesgo de descender` `310` `XP`
- `DESAFÍO COMUNITARIO`, `82%`, `50,000 señas aprendidas en equipo`, `100`
- `41,000 / 50,000 señas validadas por IA`, `¡Meta cercana!`
- `Aportar señas al desafío`
- Nav: `Aprender`, `Diccionario`, `Cámara CV`, `Ligas`, `Perfil`

# 4. Components inventory

- Hero card: rounded-xl, iris diamond badge 56px + mint ping dot — active; countdown sub-panel default.
- Promotion callout: mint-tinted bar, arrow icon — informational.
- Rank badges: 32px rounded-lg — #1 amber/gold selected-elite, #2/#3/#5/#6 dark default, #4 mint active/current-user, #26 red-tinted risk.
- Avatars: 44px round; #4 has mint glow ring + check chip (active); #26 uses generic person icon.
- `+ Entrenar`: small mint pill — primary for current user.
- Dividers: mint line (promo) / red line + warning pill (demo) — state markers.
- Challenge CTA: full-width violet pill w/ 3D rim — default/pressed style.
- Bottom nav: `Ligas` active mint.

# 5. Color & theming

Bg `#10131A`; mint `#00F0A8` on #4 badge, promo zone, progress, active nav; amber on #1 badge, `Experto LSC`, challenge label; iris on hero badge/CTA; red on demotion zone. **ANOMALY:** challenge button `#4720CA` and pale texts `#C9BFFF/#E5DEFF` are iris-family but outside exact `#7B61FF`. **ANOMALY:** demotion container `#93000A` deep red vs palette red `#FF3366` (warning text does lean red — exact hue UNCERTAIN).

# 6. Gamification elements

Streak `14` (also row #4 `14 días`), gems `420` + prize `100`, hearts `5`; XP values per rank; `+65 XP hoy`; `+ Entrenar` boost; promotion (`Top 5`) and demotion (`Últimos 5`) zones; league countdown; community goal `82%` / `41,000 / 50,000` progress bar. No chests/nodes/rings.

# 7. Accessibility observations

Current-user row distinguished by glow, mint badge, `Tú` label, and check — not color-only. Demotion uses warning icon + uppercase label + red. Promo zone uses arrow icon + bold phrase. Touch targets: nav OK; `+ Entrenar` pill is small (~24px tall) — below 44px guidance.

# 8. PNG vs HTML discrepancies

- PNG challenge icon tile reads amber; HTML specifies `tertiary-container` (amber family) — consistent.
- PNG heading wraps `50,000 señas / aprendidas en equipo` and caption wraps `…por IA` — same strings as HTML, layout wrap only.
- HTML countdown script only pulses opacity; value `1d 14h` matches PNG.
- No missing/renamed elements found; nav labels match HTML exactly.

# 9. Uncertainties

- UNCERTAIN: whether header includes a left-side logo (PNG shows stats only at left).
- UNCERTAIN: exact XP thousand-separator rendering (`1,420` vs `1.420`) — PNG shows commas.
- UNCERTAIN: precise hue of demotion red vs `#FF3366`.
