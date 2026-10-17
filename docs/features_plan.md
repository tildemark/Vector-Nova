# Vector Nova: Features Plan & Implementation TODOs

This document tracks all features, architectures, and development phases for **Vector Nova**, adapting classic arcade shmup mechanics from **Aero Fighters**, **1942 / 1943**, and **Varth: Operation Thunderstorm**.

---

## 1. Feature Architecture Overview

### Combat Systems Hierarchy
1. **Primary Weapon:** Infinite ammo, auto-fire loop, upgrades Tier 1–4 via `[P]` Power-Up canisters.
2. **Secondary Tactical Weapon:** Limited resource (Continuous `0% – 100%` Energy Gauge Bar), refuels by collecting scrap & energy cores from destroyed enemies, triggered via **Double-Tap on the right half of the screen** on mobile or **Spacebar / Right-Click** on PC. Distinct weapon behavior per ship.
3. **Emergency Defensive Special:** Screen-clearing EMP / Super Bomb with invulnerability window, slow passive recharge + enemy kills.

### Planned Ship Roster
- **Vanguard-01 (Strike All-Rounder):** Twin Plasma + Swarm Micro-Missiles + EMP Shockwave.
- **Valkyrie-IX (Interceptor / Speed & DPS):** Piercing Beam + Continuous Hyper-Beam + Chrono-Stasis (Time Slow).
- **Behemoth-V (Heavy Siege Cruiser):** Heavy Quad Flak + Siege Pulse Mortar + Thermal Nuke.
- **Aegis Phantom (Tactical Defense):** Dual Helix Plasma + Kinetic Deflector Barrier + Overdrive Matrix.
- **Apex Chronos (5th Ship - Planned):** Experimental Prototype (IAP / Supporter Pack, non-P2W) with Singularity Grav-Vortex & enhanced scrap magnet.

---

## 2. Master Implementation Phases & TODO Tracker

### Phase 0: Foundation & Core Arcade Engine (COMPLETED)
- [x] Relative drag touch controls with vertical banking tilt and viewport clamp.
- [x] High-performance `ObjectPool` for player and enemy projectiles.
- [x] Decoupled `EventBus` singleton for signal management.
- [x] Basic primary auto-fire loop with weapon tiers (single, dual, 3-spread, 4-spread + missiles).
- [x] Screen-clearing EMP shockwave with camera shake and bullet deletion.
- [x] Basic enemies: Scout (`enemy_scout.tscn`) and Interceptor (`enemy_interceptor.tscn`).
- [x] Dreadnought Nova modular boss with destructible weakpoints and enraged core phase.
- [x] Floating scrap drops with sine-wave motion and magnetic attraction.
- [x] Hangar upgrade shop: Hull HP, Fire Rate, Magnet Radius, and pre-run boosters.
- [x] Save/Load state persistence via `SaveManager` (JSON).

---

### Phase 1: Secondary Tactical Weapon, Double-Tap & Gauge HUD (COMPLETED)
- [x] **EventBus Signals:** Register `secondary_energy_changed(current, max)` and `secondary_weapon_fired(type)`.
- [x] **Energy Core & Scrap Integration:** Update `scrap_item.gd` and `player.gd` so collected items replenish secondary energy (+8% per scrap).
- [x] **Double-Tap Gesture Detection:** Implement responsive double-tap touch input in `player.gd` alongside Spacebar / Right-Click desktop triggers.
- [x] **HUD Secondary Energy Gauge:** Add a continuous `0% – 100%` amber/gold energy gauge to `main.tscn` HUD with dynamic ready states.
- [x] **Vanguard-01 Swarm Missiles:** Implement secondary missile salvo logic (8 seeker rockets that track nearest targets with splash damage).
- [x] **Secondary Button Fallback:** Add dedicated HUD button with custom SVG missile icon (`missile_icon.svg`) beside the EMP button.

---

### Phase 2: Title Screen / Main Menu & Hyperspace Loading Transition (COMPLETED)
- [x] **Arcade Title Screen (`title_screen.tscn`):**
  - Animated vector starfield and glowing Vector Nova logo with retro neon aesthetic.
  - "TOUCH ANYWHERE TO ENGAGE" attract prompt transitioning to active menu.
  - Navigation: `[ LAUNCH MISSION ]`, `[ FLEET HANGAR ]`, `[ SYSTEM SETTINGS ]`.
- [x] **Hyperspace Warp Loading Screen (`warp_screen.tscn`):**
  - High-speed star streak acceleration transition (up to 12x warp velocity) between menus and combat.
- [x] **Project Configuration:** Updated `project.godot` to launch to `title_screen.tscn` as the main scene.
- [x] **Hangar & Main Return Navigation:** Added `← TITLE` back button to `hangar.tscn` and routed deployment through `WarpScreen`.

---

### Phase 3: Ship Roster Data & Weapon Implementations (COMPLETED)
- [x] **Ship Configuration Registry:** Created `SHIPS_ROSTER` dictionary in `GameState` with base stats, primary/secondary weapon profiles, and persistence.
- [x] **Secondary Weapon Implementations:**
  - [x] **Piercing Hyper-Beam (Valkyrie-IX):** Continuous 2.0s laser beam cutting through enemies and shields (`hyper_beam.tscn`).
  - [x] **Siege Pulse Mortar (Behemoth-V):** High-explosive plasma mortar with 140px radial shockwave deleting bullets (`pulse_mortar.tscn`).
  - [x] **Kinetic Deflector Barrier (Aegis Phantom):** Forward/rotating energy barrier absorbing bullets and dealing contact damage (`kinetic_barrier.tscn`).
- [x] **Visual Ship Assets:** Generated distinct scalable SVG vector sprites for `ship_valkyrie.svg`, `ship_behemoth.svg`, and `ship_aegis.svg`.

---

### Phase 4: Hangar Ship Selection & Progression (COMPLETED)
- [x] **Interactive Ship Carousel:** 2D ship preview carousel in `hangar.tscn` with `◀` and `▶` buttons and vector SVG rendering.
- [x] **Stat Cards:** Display Armor (HP), Speed, Primary Weapon, Secondary Tactical Weapon, and Description.
- [x] **Scrap Economy Unlocks:** Purchasing ships with Scrap currency (e.g. Valkyrie 350 ⬡, Behemoth 500 ⬡, Aegis 650 ⬡) with disk persistence.
- [x] **Ship Launch Wiring:** Selected chassis automatically applies to player HP, speed, sprite, and secondary weapon on mission launch.

---

### Phase 5: Stage Director, Retro-Arcade Polish (QoL) & 5th Ship (COMPLETED)
- [x] **120-Second Timed Stage Progression:**
  - 0:00–0:25: Red formation opening wave (100% destruction = guaranteed `[P]` drop).
  - 0:25–0:50: Mixed interceptor crossfire waves.
  - 0:50–1:20: Mid-boss Heavy Elite Cruiser (`enemy_heavy_elite.tscn`) with radial attack & bullet cancel on death.
  - 1:20–1:40: Pre-boss fleet gauntlet and power-up refresh.
  - 1:40–2:40: Capital Dreadnought Nova with 60-second enrage countdown.
- [x] **Bullet Canceling (Varth):** Destroying elite enemies and boss turrets converts active bullets into scrap and energy.
- [x] **Player Hitbox Core Dot:** Glowing 3px cyan indicator at player ship center for precise bullet grazing.
- [x] **Graze Detection:** Close-call near-misses grant energy ticks (+1.2%), score (+150 pts), and visual floating spark.
- [x] **Hit-Stop (Micro-Freeze):** 40-60ms engine pause when heavy enemies or turrets explode for arcade impact crunch.
- [x] **Score & Extends System:** Score thresholds (10k, 25k, 50k) award +50 scrap bonus and full EMP recharge.
- [x] **5th Ship Implementation (Apex Chronos - Supporter Chameleon Prototype):**
  - High-tech prototype chassis (`ship_apex.svg`).
  - **Holographic Weapon Mimicry:** Can mirror the tactical secondary weapon of any unlocked ship in the fleet (Vanguard missiles, Valkyrie beam, Behemoth mortar, or Aegis barrier) via the Hangar selector.
  - **Scrap Salvage Bonus:** +30% scrap multiplier applied to all salvage collected at run finalization.
  - **Supporter Chrono-Revival:** Restores to **100% full hull** (instead of standard 50%) with a time-stasis EMP detonation on fatal damage.
  - High speed (520), +35% scrap vacuum magnet, 110 HP.
  - Unlockable in Hangar roster (850 ⬡ / Supporter prototype).

---

### Phase 6: Escort Craft System (Wingmen) & Rewarded Monetization (COMPLETED)
- [x] **Dual Escort Tactical Formations & Bullet Absorption:**
  - Max **2 Escorts** deployed simultaneously (Slot 1 & Slot 2 unlocked separately).
  - Selectable Tactical Placements:
    - **Flank Left / Right:** Wings on player flanks (standard 1942 twin wingman wide screen fire).
    - **Vanguard Front:** Locks ahead of player nose as high-density forward shield & lance fire.
    - **Revolving / Orbiting:** Continuous circular orbit around player (Varth pod defense), actively intercepting bullets.
  - **Bullet Absorption Shielding:** When an enemy bullet contacts an escort drone, the bullet is absorbed/destroyed, and the escort flashes with an energy deflection shield (absorbing up to its durability before a short reboot cooldown).
- [x] **Escort Roster & Independent Feature Unlocks:**
  - Base Escort Bay System: Unlockable license (500 Scrap or 5 Hyper-Cores).
  - Slot 2 Deployment License: Unlocks deploying a second escort simultaneously.
  - Independent Chassis Unlocks:
    - **Specter-D1 (Assault Interceptor):** Rapid twin-vulcan fire.
    - **Aegis-S2 (Point Defense Sentry):** Active laser defense and reinforced bullet absorption shield.
    - **Goliath-B4 (Siege Artillery):** Armor-piercing micro-torpedoes.
    - **Chronos-X (Tachyon Collector):** Screen-wide scrap magnetic vacuum and stasis pulse.
  - Independent Feature/Armament upgrades per escort chassis.
- [x] **Rewarded Ad Currency (Hyper-Cores ⬢):**
  - Zero interruptive UI/interstitial ads.
  - Optional rewarded video viewing generates **Hyper-Cores (⬢)**.
  - Hyper-Cores can unlock escort licenses, slots, drone chassis, and post-run salvage multipliers.
- [x] **Hangar Escort Bay UI:**
  - Integrated drone bay card in Hangar with live preview carousel, chassis stats, and slot equip buttons.
  - Formation selector (Flank, Front, Orbit), chassis equip slots, and armament upgrade cards.

---

### Phase 7: Environmental Obstacles, Retro SFX & Synthwave BGM (COMPLETED)
- [x] **Unbreakable Environmental Debris & Hazards:**
  - **Asteroid Fields & Heavy Station Girders:** Indestructible orbital hazards drifting horizontally across combat corridors.
  - **Tactical Bullet Absorption Cover:** Colliding enemy bullets are immediately absorbed and recycled by obstacles, creating tactical cover for dodging bullet hell patterns.
  - **Hull Collision Hazard:** Colliding with girders or asteroids deals heavy contact hull damage to the player and crushes smaller enemy scouts.
  - Scalable vector assets: `debris_asteroid.svg` and `debris_girder.svg` instantiated in `obstacle_debris.tscn`.
- [x] **Retro-Arcade Sound Effects (SFX) Suite:**
  - 10 custom synthesized 16-bit 44.1kHz sound effects generated via Python audio math synthesizer (`tools/generate_audio.py`):
    - `laser_player.wav` (Chirped pulse laser)
    - `explosion_small.wav` & `explosion_heavy.wav` (Noise bursts with low-frequency rumble)
    - `bullet_absorb.wav` (Resonant high-frequency deflection tone)
    - `graze.wav` (High-frequency near-miss shimmer)
    - `scrap_pickup.wav` & `powerup_pickup.wav` (Arcade reward chords)
    - `emp_detonate.wav` (Deep sub-bass discharge)
    - `missile_launch.wav` (Hissing propulsion burst)
    - `hyper_beam.wav` (Heavy continuous plasma roar)
  - Polyphonic player pool (12 audio channels) with dynamic pitch shifting (`0.92x – 1.08x`) in `AudioManager` singleton.
- [x] **Chiptune & Synthwave Background Music (BGM):**
  - **`bgm_stage1.wav`**: 135 BPM driving synthwave combat loop with arpeggiated bassline, punchy kick-snare pulse, and lead melody.
  - **`bgm_title.wav`**: Ambient cyberpunk arpeggio loop for Title and Hangar menus.
  - Centralized loop management in `AudioManager` connected directly to stage flow and menu transitions.


