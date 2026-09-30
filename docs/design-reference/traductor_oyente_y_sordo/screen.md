# 1. Screen identity

Folder: `traductor_oyente_y_sordo` — bidirectional accessibility translator. Mode 1 converts hearing speech/text into a synthetic signer video; the lower section offers quick pictogram phrases for deaf users plus a PRO CV upsell. Lives on the `Traductor` tab of the practice/game flow.

# 2. Layout blueprint

```
[logo] [ASL LSC]  [14][420][5] [avatar]
[ ( Oyente ➔ Sordo ) | Sordo ➔ Oyente ]
[chip ¿Cómo estás?] [Mucho gusto] [Necesito un t…]
[ ENTRADA DEL OYENTE      ● Audio Activo ]
[ input: Hola, ¿dónde…  (mic) ]
[ Dialecto: ASL Estándar    Re-traducir ]
[ IA Sign Player      Secuencia: 2/4 ]
[ video + mesh | ✨ Síntesis Neuronal 60 FPS | 360 ]
[ GESTO ACTUAL: "¿DÓNDE?" (Ubicación) + progress ]
[ 0.75x 1x | ⏮ ⏸ ⏭ | ↻ ]
[ MODO RESPUESTAS RÁPIDAS ]
[ Tablero de Pictogramas Libres ] [Voz Instantánea]
[ Ayuda | Hospital ]
[ Gracias | ¿Cuánto es? ]
[ PRO: Cámara Computer Vision con IA ]
[ Desbloquear con PRO ]
[ Aprender | Práctica | Bingo | Traductor | Premium ]
```

# 3. Exact on-screen text

- Header: `ASL`, `LSC`, `14`, `420`, `5`
- Tabs: `Oyente ➔ Sordo`, `Sordo ➔ Oyente`
- Chips: `¿Cómo estás?`, `Mucho gusto`, `Necesito un t…` (truncated)
- `ENTRADA DEL OYENTE`, `Audio Activo`
- Input: `Hola, ¿dónde queda la estación del r…` (truncated by field)
- `Dialecto: ASL Estándar`, `Re-traducir`
- `IA Sign Player`, `Secuencia: 2/4`
- `Síntesis Neuronal 60 FPS`
- `GESTO ACTUAL:`, `"¿DÓNDE?"`, `(Ubicación)`
- Speeds: `0.75x`, `1x`
- `MODO RESPUESTAS RÁPIDAS`, `Tablero de Pictogramas Libres`, `Voz Instantánea`
- Cards: `Ayuda` / `Alerta inmediata`; `Hospital` / `Urgencias`; `Gracias` / `Agradecimiento`; `¿Cuánto es?` / `Consulta precio`
- `PRO`, `Cámara Computer Vision con IA`
- Body: `Apunta tu cámara frontal para traducir lenguaje de señas en tiempo real directamente a voz audible y texto sin pausas.`
- `Desbloquear con PRO`; caption `Incluye reconocimiento bidireccional ASL + LSC`
- Nav: `Aprender`, `Práctica`, `Bingo`, `Traductor`, `Premium`

# 4. Components inventory

- Mode switcher: full-width pill bar; `Oyente ➔ Sordo` selected mint w/ 3D rim; other tab default gray. Active/default.
- Phrase chips: full-round ~32px tall, dark low container, default (row scrolls; 4th chip off-screen).
- Input: rounded-lg dark field + 40px violet mic circle (active/default).
- Player: rounded-xl viewport; mint pause button 48px active; `1x` speed chip selected (dark + mint text), `0.75x` default; loop mint default.
- Pictogram cards: 2-col ~150×110px rounded-xl; `Ayuda` red container state, others default dark; all tappable.
- PRO CTA: full-width pill, violet bg, light text, default/pressed rim.
- Bottom nav: `Traductor` active (mint, bold), others default.

# 5. Color & theming

Bg `#10131A`; mint `#00F0A8` on selected tab, CTA pause, progress, active nav; amber on `Secuencia:`/smiley; iris family on mic, PRO button/glow; red on `Ayuda`. Space Grotesk headlines / Plus Jakarta Sans body evident. **ANOMALY:** `Ayuda` card renders bright red vs HTML `#93000a` (deep error-container); closer to `#FF3366` but exact hue UNCERTAIN. **ANOMALY:** PRO button in PNG is saturated violet with light text; HTML specifies light lavender `#C9BFFF` bg + dark `#2E009C` text. **ANOMALY:** deep violet `#4720CA` (mic/tab) outside exact `#7B61FF`.

# 6. Gamification elements

HUD: streak `14`, gems `420`, hearts `5`. Sequence `2/4` + mint progress bar acts as micro-progress. No path nodes, rings, or chests. Note: gems `420` here vs `480` on the camera screen.

# 7. Accessibility observations

Red `Ayuda` card is visually distinct (good non-audio cue for emergency). Mode tabs ≥44px; chips ~32px tall (small); speed chips small (~28px). `Traductor` active state signaled by color+bold. Mesh overlay, progress bar, and `Audio Activo` pulse dot give visual (non-audio) feedback.

# 8. PNG vs HTML discrepancies

- PRO button colors differ (see §5).
- PNG card icon for `¿Cuánto es?` reads white/gray; HTML uses iris `payments` icon — possible tint mismatch.
- HTML's 4th chip `¿Dónde queda el baño?` is off-screen in PNG (scroll), not missing.
- HTML toast `Reproduciendo voz sintética...`, voice feedback, and Mode-2-only elements are hidden/static — not in PNG (expected).

# 9. Uncertainties

- UNCERTAIN: exact `Ayuda` red hue.
- UNCERTAIN: full text of truncated input/chip (HTML suggests `…del metro?` and `Necesito un taxi`).
- UNCERTAIN: logo rendering — PNG shows a mint hand glyph; HTML uses an image asset.
