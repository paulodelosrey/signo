# 1. Screen identity

Folder: `c_mara_computer_vision_ar_en_vivo` — live computer-vision camera screen. Real-time AR translation of signed speech (LSC/ASL) into text plus TTS for hearing interlocutors. Sits in the main tab flow ("Cámara CV"), after onboarding/lessons; counterpart to the text-first Traductor screen.

# 2. Layout blueprint

```
[HUD stats: 14 | 480 | 5 ]  [ASL LSC] [avatar]
[EN VIVO • 60 FPS]  [Auto LSC / ASL]  [⚡ torch]
[ ===== AR camera viewport (4:5) =====
   top: 98% Seña: "GRACIAS"
   mesh overlay + corner brackets
   bottom: 21 Nodos Rastreados | Laten: 12ms ]
[ TRADUCCIÓN A TEXTO      Copiar ]
[ Mucho gusto… caret ]
[ ▶ Reproducir Voz para Oyente (mint CTA) ]
[ ASL / LSC | Girar | Pausar | Emergencia ]
[ Aprender | Diccionario | Cámara CV | Ligas | Perfil ]
```

# 3. Exact on-screen text

- Stats: `14`, `480`, `5`; toggles `ASL`, `LSC`
- `EN VIVO`, `60 FPS`, `Auto LSC / ASL`
- `98%`, `Seña:`, `"GRACIAS"`
- `21 Nodos Rastreados`, `Laten: 12ms`
- `TRADUCCIÓN A TEXTO`, `Copiar`
- `Mucho gusto en conocerte, ¿cómo estás hoy?` (body + mint caret)
- `Reproducir Voz para Oyente`, `Text-to-Speech instantáneo`
- Buttons: `ASL / LSC`, `Girar`, `Pausar`, `Emergencia` (with `SOS` icon label)
- Nav: `Aprender`, `Diccionario`, `Cámara CV`, `Ligas`, `Perfil`

# 4. Components inventory

- Stat pills (3): full-round, ~90×32px, dark `#272a31` bg; fire=amber, gem=mint, heart=white outline (PNG) — default.
- ASL/LSC segmented: full-round; `ASL` selected on deep-violet `#4720CA`; `LSC` muted default.
- Torch: 36px circle, amber glyph, default.
- Camera frame: ~full-width, 4:5, rounded-2xl, mint corner brackets; live state (animated ping in HTML).
- Confidence banner: full-round, glowing mint border, active.
- `Copiar`: small rounded-8px chip, default.
- CTA: full-width pill (~56px), mint `#00F0A8`, dark text, pressed 3D rim (`#00B37D` in HTML); active.
- 4 control tiles: ~80×64px rounded-2xl, default; `Pausar` amber icon; `Emergencia` red text/icon.
- Bottom nav: 5 items ~56×48px targets; no clearly highlighted active item in PNG (UNCERTAIN).

# 5. Color & theming

Background `#10131A` family; mint `#00F0A8` on CTA/mesh/brackets; amber `#FFB800`-family on fire & pause; cyan-ish gem count `480`; iris `#7B61FF`-family on `ASL` pill, `Auto LSC / ASL` badge, support-hand mesh; red on `Emergencia`. Headline style matches Space Grotesk look. **ANOMALY:** badge violet `#4720CA` (and mesh `#C9BFFF`) are iris-family but outside exact `#7B61FF`. **ANOMALY:** deep shadow/rim `#00B37D` (CTA) is not in the Kinetic set.

# 6. Gamification elements

Top HUD: streak `14` (fire), gems `480`, hearts `5`. No XP counter, path nodes, rings, or chests on this screen. None observed beyond HUD.

# 7. Accessibility observations

Mint-on-dark CTA has strong contrast; `Emergencia` red text on dark may be marginal. Touch targets: nav ≥48px OK; torch 36px and `Copiar` ~28px are below 44px guidance. Non-audio cues: live ping dot, animated caret, glowing confidence pill, skeleton mesh, FPS/latency readouts.

# 8. PNG vs HTML discrepancies

- PNG stat icons look like emoji-style glyphs (🔥/💎/♡) with a white outline heart; HTML uses Material Symbols (`local_fire_department`, `diamond`, `favorite`) in fixed/error tints.
- HTML header/JS include copy→`Listo` and pause→`Reanudar` states; PNG shows default states only (expected for a static capture).
- Bottom nav active state: HTML marks none `aria-current` statically; PNG likewise shows no highlighted tab.
- No other label/state differences found.

# 9. Uncertainties

- UNCERTAIN: whether `Cámara CV` tab is intended-active (PNG shows all nav items equally bright).
- UNCERTAIN: exact heart glyph style (outline in PNG vs filled `favorite` in HTML).
- UNCERTAIN: whether torch is on/off (amber glyph suggests on per HTML logic).
