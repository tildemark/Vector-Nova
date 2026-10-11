Act as an expert Godot 4.x game developer, UI/UX designer, and Android mobile game architect. Your goal is to provide the complete code, asset generation, and deployment setup for a 2D horizontal sci-fi shoot 'em up (shmup) game.

**PROJECT OVERVIEW**

- **Game Name:** Vector Nova
- **Developer Name:** Vector4
- **Platform:** Android (Mobile)
- **Engine:** Godot 4.x (using GDScript, Compatibility/Mobile renderer)

**1. GAMEPLAY & MECHANICS**

- **Controls:** Relative drag touch controls (moving the finger moves the ship via offset, preventing the thumb from blocking the ship).
- **Firing:** Auto-fire loop using an object pool to prevent garbage collection stutters.
- **Weapon Upgrades:** A power-up system that transitions the ship from a single laser (Level 1) to dual lasers, spread shots, and homing missiles (Level 4).
- **Special Attack:** A screen-clearing EMP or burst attack triggered by a virtual HUD button with a cooldown/gauge meter.
- **Items:** Floating 'Scrap' (currency) and power-ups moving in a sine-wave pattern.

**2. BOSS ENCOUNTER (Dreadnought Nova)**

- Implement a modular boss using a Finite State Machine (FSM).
- **Structure:** A central Core node with child `Area2D` weak points (top/bottom turrets or wings).
- **Phases:**
  - Phase 1 (Shielded): Core is invulnerable; player must destroy the turrets.
  - Phase 2 (Enraged): Core is exposed and fires dense radial bullet patterns.
  - Phase 3 (Defeated): Explosions and scrap drops.

**3. ARCHITECTURE (Godot 4)**

- **EventBus (Autoload):** Decoupled signal management (e.g., `player_damaged`, `boss_health_updated`, `scrap_collected`).
- **Object Pools:** High-performance pooling for player bullets, enemy bullets, and floating text/particles.
- **Game State (Autoload):** Track active power-ups, scrap count, and current run stats.

**4. ASSETS (Generate as SVG/Code)**

- Provide raw SVG XML code for the player ship, enemy minions, boss parts, projectiles, and UI icons. These must be scalable and cleanly designed to fit a sleek "Vector" sci-fi aesthetic.

**5. MONETIZATION & ECONOMY**

- **Currencies:** 'Scrap' earned during runs.
- **Permanent Upgrades:** A hangar tech tree for hull upgrades, fire rate boosts, and unlocking ship frames.
- **Pre-run Boosters:** Purchasable one-time items like "Plasma Shield" or "Overclock" using Scrap.
- **Ads/IAP UI Logic:** Scaffold placeholder UI hooks for:
  - Rewarded Ad: 1 "Last Stand" revive per run, or 2x Scrap post-run.
  - IAP: $1.99 Ad-Free "Starter Pilot Pack".

**6. HOSTING & DEPLOYMENT (GitHub & GitHub Pages)**

- Generate the necessary GitHub Actions workflow (`.yml`) to automatically export the Godot Android project into an APK and AAB.
- Generate the code (HTML/CSS/JS) for a static Landing Page to be hosted on GitHub Pages.
- The landing page must include:
  - Hero section featuring "Vector Nova by Vector4".
  - A "Download APK" button that links directly to the GitHub Releases page.
  - A "Get it on Google Play" button placeholder.
  - Responsive, mobile-friendly layout matching the sci-fi aesthetic of the game.

Please start by providing the project directory structure, the `project.godot` configuration for Android, and the HTML/CSS for the GitHub Pages landing page.
