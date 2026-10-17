# Vector Nova: Combat Systems, Ship Roster & Secondary Weapons Specification

## 1. Executive Summary

This specification introduces classic arcade mechanics inspired by **Aero Fighters**, **1942**, and **Varth: Operation Thunderstorm** into **Vector Nova**. 

The hallmark additions are:
1. **A Dedicated Secondary Weapon System:** A limited-resource tactical armament distinct from the primary auto-fire and emergency EMP, refueled by collecting energy cores/scrap dropped by destroyed ships.
2. **Ship Roster Architecture:** Distinct starfighters with unique flight characteristics, primary weapon profiles, secondary tactical weapons, and ultimate specials.
3. **Paced Arcade Stage Director:** Timed stage curves (100–130s), red formation guarantees, mid-bosses, and bullet-canceling rewards.
4. **Quality-of-Life (QoL) Enhancements:** Player core hitbox indicator, graze detection, hit-stop impact, and mobile ergonomics.

---

## 2. Combat Resource Hierarchy

The combat loop balances three tiers of offensive and defensive tools:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        COMBAT CAPABILITY TIERS                         │
├─────────────────┬────────────────────┬─────────────────────────────────┤
│ TIER 1: PRIMARY │ TIER 2: SECONDARY  │ TIER 3: EMERGENCY SPECIAL       │
│ Auto-Fire       │ Tactical Weapon    │ Screen-Clearing EMP / Nuke      │
├─────────────────┼────────────────────┼─────────────────────────────────┤
│ • Infinite ammo │ • Limited energy   │ • Slow passive build or 1-2 per │
│ • Upgrades 1-4  │ • Powers up via    │   run                           │
│   via [P] items │   enemy scrap/cores│ • Instant invulnerability       │
│ • Sustained DPS │ • Ship-specific    │ • Clears all screen bullets     │
│                 │ • High-burst impact│ • Massive boss burst damage     │
└─────────────────┴────────────────────┴─────────────────────────────────┘
```

### Secondary Weapon Energy Mechanic & Triggering
- **Capacity & Display:** Continuous **Energy Gauge Bar (0.0% to 100.0%)** on HUD.
- **Trigger Methods:**
  - **Mobile:** **Double-Tap** anywhere on screen (fast, fluid without obstructing ship movement) + optional on-screen HUD button.
  - **Desktop / Gamepad:** Right-click, Spacebar, or Gamepad Trigger (R2/RT).
- **Replenishment:** 
  - Standard minion scrap drop: +6% to +8% Energy.
  - Elite / Interceptor energy core: +20% Energy.
  - Boss weakpoint destruction: +35% Energy.
  - Bullet Graze (near-miss): +1% Energy per graze tick.
- **Consumption:** Fixed chunk per salvo (e.g. 25% for missile volley or mortar blast) or continuous drain (30%/sec for hyper-beam/barrier).

---

## 3. Ship Roster & Weapon Profiles

Vector Nova features 4 standard unlockable chassis plus a planned **5th Experimental Prototype (IAP / Supporter Pack)**:

| Ship Name | Class | Base Stats | Primary Weapon | Secondary Tactical Weapon (Gauge Bar / Double-Tap) | Ultimate Special |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Vanguard-01** | Strike All-Rounder | HP: 100<br>Speed: 1.0x | Twin Plasma Cannons (spreads at high tiers) | **Swarm Micro-Missiles**<br>Fires 8 seeker missiles tracking targets with AoE blast | **EMP Shockwave**<br>Screen-wide EMP clearing bullets & shocking enemies |
| **Valkyrie-IX** | High-Speed Interceptor | HP: 75<br>Speed: 1.35x | Focused High-Frequency Laser | **Piercing Hyper-Beam**<br>Sustained continuous laser that cuts through all ships & shields | **Chrono-Stasis**<br>Slows time and enemy bullets by 80% for 4 seconds |
| **Behemoth-V** | Heavy Siege Cruiser | HP: 160<br>Speed: 0.85x | Heavy Quad Flak Cannon | **Siege Pulse Mortar**<br>High-explosive projectile causing massive radial shockwave | **Thermal Core Detonation**<br>Devastating screen blast with lingering fire damage |
| **Aegis Phantom**| Tactical Defense | HP: 110<br>Speed: 1.05x | Dual Helix Plasma | **Kinetic Deflector Barrier**<br>Deployable front energy barrier absorbing bullets & ramming | **Overdrive Matrix**<br>Instant full shield recharge + double fire rate |
| **Apex Chronos** *(Planned 5th Ship)* | Experimental Prototype *(IAP / Supporter Pack)* | HP: 95<br>Speed: 1.1x | Hybrid Dual Vulcan + Piercing Core | **Singularity Grav-Vortex**<br>Launches a mini black-hole that pulls enemies, swallows bullets, and draws in scrap | **Cosmic Rift**<br>Phases out of reality for 3s (invulnerable) leaving lingering antimatter trails |

> *Note on Apex Chronos:* Designed to offer a distinctive, flashy playstyle and convenient scrap gathering without being pay-to-win (its durability and speed remain balanced relative to standard craft). Implemented as the final ship in the roster roadmap.

---

## 4. Stage Timing & Wave Director

Stages are timed for high-intensity mobile sessions (100–140 seconds total):

```text
 0:00 ──── 0:20 ──── 0:50 ──── 1:10 ──── 1:30 ──── 2:15 ──── 2:30
   │         │         │         │         │         │         └─ Debrief & Hangar
   │         │         │         │         │         └─ Boss Defeat & Hyperspace
   │         │         │         │         └─ Capital Flagship Boss (Phase 1 & 2)
   │         │         │         └─ Pre-Boss Bullet-Cancel Gauntlet
   │         │         └─ Mid-Boss Elite Escort (Guaranteed Energy Drop)
   │         └─ Mixed Formations (Scouts, Crossfire Interceptors)
   └─ Red Formation (100% kill = Guaranteed [P] Power-Up drop)
```

### Retro Rules Adapted
1. **Red Formation (1942):** First wave of each stage consists of distinct red/gold scout units. Destroying all units in the formation guarantees a Weapon Power-Up `[P]`.
2. **Bullet Canceling to Energy/Scrap (Varth):** When an elite enemy or boss part explodes, all bullets fired by that entity turn into scrap and energy cores.
3. **Boss Combat Timer:** 60-second limit before boss initiates an enraged bullet frenzy.

---

## 5. Implementation Roadmap (Phases)

### Phase 1: Secondary Weapon Core, Double-Tap & Gauge HUD
- [ ] Add `secondary_energy_changed(current, max)` and `secondary_weapon_fired(type)` to `EventBus`.
- [ ] Implement Secondary Energy gauge (0-100%) in `main.tscn` HUD.
- [ ] Add **Double-Tap gesture detection** in `player.gd` (with Right-Click/Spacebar on PC and optional HUD button).
- [ ] Update `scrap_item.gd` to replenish both scrap and secondary energy.
- [ ] First functional secondary weapon: Homing Micro-Missile barrage on Vanguard-01.

### Phase 2: Title Screen / Main Menu & Loading Transition
- [ ] Create Title Screen (`title_screen.tscn`) with sci-fi logo animation, "Touch to Start", and menu navigation:
  - `[ LAUNCH MISSION ]`
  - `[ HANGAR / FLEET ]`
  - `[ SETTINGS / CONTROLS ]`
- [ ] Add Hyperspace Warp Loading Screen transition between menu and main combat.
- [ ] Update `project.godot` to launch to `title_screen.tscn`.

### Phase 3: Ship Roster Data & Weapon Implementations
- [ ] Define `ShipData` structure in `GameState` (Vanguard, Valkyrie, Behemoth, Aegis, Apex).
- [ ] Implement the remaining 3 standard secondary weapons:
  - Piercing Hyper-Beam (continuous RayCast/Line2D).
  - Siege Pulse Mortar (slow projectile, massive AoE shockwave).
  - Kinetic Deflector Barrier (orbiting / front barrier destroying bullets).
- [ ] Ship visual sprites and distinct flight/firing parameters.

### Phase 4: Hangar Ship Selection & Progression
- [ ] Interactive Ship Selection Carousel in `hangar.tscn`.
- [ ] Scrap purchasing system for ships + save persistence.
- [ ] Stat preview cards (Armor, Speed, Primary, Secondary).

### Phase 5: Stage Director, Retro-Arcade Polish (QoL) & 5th Ship
- [ ] Wave Director: 120s timed progression with Red Formations and mid-boss.
- [ ] Bullet canceling on elite/boss part death.
- [ ] Player Hitbox core dot and graze detection.
- [ ] Implement 5th Ship: **Apex Chronos** (Singularity Vortex & IAP purchase hook).

- [ ] Bullet graze detection (passing close to bullets generates energy + visual sparks).
- [ ] Hit-stop micro-pauses (30ms engine freeze on high-impact hits).
