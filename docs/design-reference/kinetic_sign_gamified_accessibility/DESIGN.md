---
name: Kinetic Sign & Gamified Accessibility
colors:
  surface: '#10131a'
  surface-dim: '#10131a'
  surface-bright: '#363941'
  surface-container-lowest: '#0b0e15'
  surface-container-low: '#191c23'
  surface-container: '#1d2027'
  surface-container-high: '#272a31'
  surface-container-highest: '#32353c'
  on-surface: '#e0e2ec'
  on-surface-variant: '#b9cbbf'
  inverse-surface: '#e0e2ec'
  inverse-on-surface: '#2d3038'
  outline: '#84958a'
  outline-variant: '#3b4a41'
  surface-tint: '#00e29e'
  primary: '#b7ffd9'
  on-primary: '#003824'
  primary-container: '#00f0a8'
  on-primary-container: '#006847'
  inverse-primary: '#006c4a'
  secondary: '#c9bfff'
  on-secondary: '#2e009c'
  secondary-container: '#4720ca'
  on-secondary-container: '#baaeff'
  tertiary: '#ffedd3'
  on-tertiary: '#412d00'
  tertiary-container: '#ffcb6b'
  on-tertiary-container: '#775400'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#46ffb8'
  primary-fixed-dim: '#00e29e'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#e5deff'
  secondary-fixed-dim: '#c9bfff'
  on-secondary-fixed: '#1a0063'
  on-secondary-fixed-variant: '#441cc8'
  tertiary-fixed: '#ffdea8'
  tertiary-fixed-dim: '#ffba20'
  on-tertiary-fixed: '#271900'
  on-tertiary-fixed-variant: '#5e4200'
  background: '#10131a'
  on-background: '#e0e2ec'
  surface-variant: '#32353c'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.03em
  display-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.03em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '800'
    lineHeight: 14px
    letterSpacing: 0.06em
  stat-counter:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  gutter-desktop: 2rem
  margin: 1.25rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

This design system is crafted for an inclusive, high-energy language learning ecosystem focused on manual and visual languages—principally American Sign Language (ASL) and Catalan Sign Language (LSC / Llengua de Signes Catalana). It targets a diverse demographic ranging from complete beginners and Deaf community allies to deaf and hard-of-hearing learners seeking fluent cross-dialect immersion and real-time computer vision translation.

The visual direction merges **Tactile Gamification** with a **High-Contrast Digital Modernism**. While drawing inspiration from cheerful, micro-rewarding learning loops (chunky interactive targets, physical press states, expressive feedback), it intentionally avoids infantile tropes. The aesthetic leverages deep, glare-free canvas surfaces punctuated by electric neon accents that command visual attention without causing eye fatigue during camera-based gesture recognition sessions. Spatial depth is expressed through solid structural lift, vibrant spatial glows, and tactile physical layering rather than ephemeral realistic skeumorphism. Every touchpoint communicates clarity, empowerment, and kinetic joy.

## Colors

The palette balances joyful visual feedback with strict WCAG AAA compliance for motion-heavy and text-heavy visual environments. The default mode is `dark` to create an optimal, non-glare canvas for real-time video feeds, visual hand-tracking landmarks, and prolonged practice sessions.

### Functional Roles

- **Primary (`#00F0A8` - Electric Kinetic Mint):** Represents kinetic momentum, positive verification, and active learning paths. Its luminous green-cyan tone ensures high visibility against dark backdrops and triggers positive reinforcement.
- **Secondary (`#7B61FF` - Deep Iris Neon):** Applied to grammar units, structural translation elements, modal shells, and ASL/LSC module switchers. Delivers an anchoring, intellectual contrast to the high-energy mint.
- **Tertiary (`#FFB800` - Amber Bolt):** Reserved exclusively for gamification mechanics: active daily streaks, combo meters, double-XP boosts, and gold lesson mastery rings.
- **Gamification Rubies (`#FF3366` - Heart Core):** Dedicated token for remaining hearts/lives and error correction prompts.
- **Gamification Sapphires (`#00D2FF` - Gem Spark):** Dedicated token for user gems, reward unlockables, and translation speed boosts.
- **Neutral Surface Palette:**
  - `neutral-000` (`#0A0C10`): Deep void background behind live camera tracking.
  - `neutral-100` (`#12151C`): Standard base canvas.
  - `neutral-200` (`#1C212D`): Card layers, question decks, and module nodes.
  - `neutral-300` (`#282F3E`): Subtle borders, structural dividers, and inactive state fills.
  - `neutral-800` (`#E6EAF2`): Secondary text and descriptive helper labels.
  - `neutral-900` (`#FFFFFF`): Primary typography and critical visual tokens.

In `light` mode implementations, the neutrals invert to stark architectural canvases (`#F6F8FC` to `#FFFFFF`) with ink-black high-contrast text (`#0C0E14`), while preserving the electric saturation of the interactive functional colors.

## Typography

Typography bridges expressive technical modernity with effortless readability. 

- **Display & Headline Roles (Space Grotesk):** Provides structured geometry, sharp angles, and distinctive technical character. It infuses game modules, celebration screens, and real-time AI recognition states with an advanced, precise feel.
- **Body & Functional Labels (Plus Jakarta Sans):** Chosen for its rounded terminals, generous x-height, and open counters. This ensures immediate clarity at rapid glances, particularly when users transition their visual focus between their physical hand gestures and the screen.
- **Numerical & Stat Counters:** Space Grotesk is leveraged with tabular figures (`tnum`) across streak badges, XP progress meters, gem counters, and real-time hand accuracy percentages to prevent visual jittering during live animations.

## Layout & Spacing

The layout is built upon a fluid 4-column structure on mobile (under 600px), transitioning to an 8-column layout on tablet (600px–1024px), and a 12-column bounded canvas on desktop/web (1024px+ max width: 1200px).

### Architectural Rules
- **Camera Viewport Reserve:** During interactive signing sessions, mobile views lock into a split layout: the top 45% is dedicated to video feed and skeleton-joint overlays, while the lower 55% houses challenge prompts, real-time visual subtitles, and the response interaction deck.
- **The Path Grid:** The core progression path uses a centered single-track meandering layout with node offsets of `-32px`, `0px`, and `+32px` from the vertical center axis, maintaining a constant vertical node gap of `space-xl` (32px).
- **Touch Targets:** Interactive targets maintain an absolute minimum touch zone of 48px x 48px, with interactive path nodes expanded to 64px x 64px to support easy one-handed navigation while signing with the other.

## Elevation & Depth

This system avoids blurred realistic drop shadows in favor of **Tactile Extrusions** and **Radiant Neon Halos**, reinforcing physical feedback and high visibility.

### The Tactile Step (3D Bottom Border Effect)
Interactive buttons, nodes, and action cards feature a crisp lower edge extrusion (a solid inset/downward offset line of 4px) in a darkened shade of the element’s color. On click or tap, the surface translates downward by 3px with the bottom border collapsing to 1px, providing satisfying physical click confirmation without relying solely on auditory feedback—a critical consideration for deaf and hard-of-hearing users.

### Radiant AI Halos
When real-time computer vision is actively analyzing hand shapes and spatial trajectories:
- Correct hand configuration: A subtle, concentrated ambient glow emits from the card perimeter (`0px 0px 20px rgba(0, 240, 168, 0.35)`).
- Error state: A tight red pulse halo (`0px 0px 20px rgba(255, 51, 102, 0.4)`).
- Translation active: Soft Iris aura (`0px 0px 24px rgba(123, 97, 255, 0.3)`).

### Elevation Layers
- **Level 0 (Canvas):** Pure `#12151C`.
- **Level 1 (Card Deck):** `#1C212D` with a crisp 1px border of `#282F3E`.
- **Level 2 (Floating Status Bar & Trays):** `#282F3E` with 12px background blur (`backdrop-filter: blur(12px)`) at 85% opacity, raised with a downward shadow of `0 8px 24px rgba(0, 0, 0, 0.4)`.
- **Level 3 (Modals & Sheet Overlays):** `#1C212D` framed by a 2px primary neon accent border.

## Shapes

The design uses **Rounded** geometry (`roundedness: 2` = base 0.5rem / 8px). This creates an inviting, accessible atmosphere while preserving structural discipline for complex multi-stream video and translation UI.

### Radius Scale
- **Base (8px / 0.5rem):** Input fields, inline tags, auxiliary chips, tooltips.
- **Large (16px / 1rem):** Challenge cards, video preview containers, translation drawer containers, modal dialogues.
- **Extra Large (24px / 1.5rem):** Main curriculum module nodes, reward chests, camera viewport frame.
- **Pill (9999px):** Primary tactile action buttons, streak indicators, currency counters (gems, hearts), audio/mute switches, and camera flip toggles.

## Components

### Buttons
- **Primary 3D Button:** Pill-shaped, background `#00F0A8`, typography `label-lg` in `#0A0C10`. Built with a solid lower rim of `#00B37D` (4px height). Upon tap, element moves 3px along the Y-axis.
- **Secondary Action Button:** Surface of `#1C212D`, border 2px solid `#282F3E`, lower rim 4px solid `#12151C`, text `#FFFFFF`.
- **Ghost/Tertiary Button:** Transparent background, text `#00F0A8`, minimum hit target 48px, no extrusion.

### Gamification Tokens & Badges
- **Streak Pill:** Pill container, dark background (`#1C212D`), bordered in `#FFB800` (15% opacity). Displays flame icon in `#FFB800` followed by streak count in `stat-counter`.
- **Heart Deck:** Pill container displaying animated red heart icons (`#FF3366`) indicating remaining lives. Replaces sound-only cues with a subtle screen-edge heartbeat animation when reduced to 1 life.
- **Gem Counter:** Pill container housing `#00D2FF` diamond glyph with high-contrast numerical tracker.
- **Node Matrix (Learning Map):** Circular nodes (64px x 64px) with dynamic outer rings:
  - *Locked:* Muted `#282F3E` with closed padlock.
  - *Active:* `#00F0A8` base with pulsing outer SVG progress ring indicating module lesson chunks (e.g., 3/5).
  - *Mastered:* `#FFB800` radiant crown finish with star iconography.

### Cards & Lesson Prompts
- **Flash-Sign Cards:** Elevated at Level 1, featuring high-frame-rate looping sign animations or video feeds. Borders highlight to `#00F0A8` upon successful user mimicry.
- **Multi-Choice Sign Tiles:** Grid of 2 or 4 visual video loops per screen. Selected state applies a 2px neon border and an internal mint-check badge.

### Real-Time Translation & Camera Viewport
- **Camera Frame:** Rounded (24px) clipping boundary. Displays 21-point hand mesh skeletal overlays rendered in high-visibility `#00F0A8` (dominant hand) and `#7B61FF` (non-dominant hand).
- **Live Translation Subtitle Box:** Floating bottom sheet pill anchored inside the camera view. Dark glass backdrop (`rgba(18, 21, 28, 0.85)`), text rendered in `headline-md` featuring real-time letter-by-letter predictive typing.
- **Dialect Switcher (ASL / LSC):** Segmented pill control located in the top navigation bar. Active dialect segment fills with `#7B61FF` text `#FFFFFF`, inactive segment displays muted `#8E9AA8`.

### Checkboxes, Radio Buttons & Inputs
- **Interactive Selectors:** Custom 24px rounded-md (6px radius) boxes. When toggled, fills with `#00F0A8` with an extruded 2px check mark.
- **Fingerspelling Input Field:** Large mono-spaced entry tiles (48px wide x 56px tall each). Empty state displays a subtle dashed bottom edge; correct finger-sign triggers automatic text population and green tile fill.