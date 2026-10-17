### 1. High-Level System Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        CORE GLOBAL AUTOLOADS                           │
│  [EventBus] (Signals)   [GameState] (Scrap, Run)   [SaveManager] (I/O) │
└───────────────────▲────────────────────────────────▲───────────────────┘
                    │                                │
┌───────────────────┴────────────────────────────────┴───────────────────┐
│                       MAIN GAME WORLD (World2D)                        │
│                                                                        │
│   ┌────────────────────┐   Spawns Items   ┌────────────────────────┐   │
│   │   SpawnerManager   ├─────────────────►│   PowerUpPool (Pool)   │   │
│   └─────────┬──────────┘                  └────────────────────────┘   │
│             │                                                          │
│             │ Spawns Ships/Boss                                        │
│             ▼                                                          │
│   ┌────────────────────┐   Collisions/    ┌────────────────────────┐   │
│   │    Enemies/Boss    │◄────────────────►│   Player (Area2D)      │   │
│   │ (Modular Weakspots)│     Damage       │  - Relative Drag       │   │
│   └─────────┬──────────┘                  │  - Auto-Fire System    │   │
│             │ Fires Enemy Bullets         └───┬────────────────────┘   │
│             ▼                                 │ Fires Lasers           │
│   ┌────────────────────┐                      ▼                        │
│   │  EnemyBulletPool   │                  ┌────────────────────────┐   │
│   └────────────────────┘                  │    PlayerBulletPool    │   │
│                                           └────────────────────────┘   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Updates HUD & Overlay
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       UI LAYER (CanvasLayer)                           │
│  - Virtual Drag Zone   - Special Attack Button   - Boss Health Bar     │
│  - Pause/Revive Modal  - Currency/Scrap Counter  - Pre-run Booster HUD │
└────────────────────────────────────────────────────────────────────────┘

```

---

### 2. Project Directory Structure

```text
res://
├── assets/
│   ├── audio/              # SFX & background music
│   ├── fonts/              # Sci-fi typography (.ttf)
│   ├── sprites/
│   │   ├── player/         # Ships, drones, thruster plumes
│   │   ├── enemies/        # Minions, modular boss parts
│   │   ├── projectiles/    # Lasers, missiles, plasma spheres
│   │   └── ui/             # Virtual buttons, icons, frames
├── src/
│   ├── autoload/           # Global singletons
│   │   ├── event_bus.gd    # Decoupled signal communication
│   │   ├── game_state.gd   # Soft currency, active modifiers
│   │   └── save_manager.gd # Encrypted player progression
│   ├── entities/
│   │   ├── player/
│   │   │   ├── player.tscn
│   │   │   └── player.gd
│   │   ├── enemies/
│   │   │   ├── base_enemy.gd
│   │   │   └── boss/
│   │   │       ├── boss_dreadnought.tscn
│   │   │       ├── boss_dreadnought.gd
│   │   │       └── boss_weakspot.gd
│   │   └── items/
│   │       └── powerup_item.gd
│   ├── pools/
│   │   ├── object_pool.gd  # Generic pool manager
│   │   └── projectile.gd   # Base reusable bullet
│   ├── managers/
│   │   ├── spawner_manager.gd
│   │   └── sound_manager.gd
│   └── ui/
│       ├── hud.tscn
│       ├── hud.gd
│       ├── menus/          # Main menu, hangar upgrades
│       └── components/     # Special fire button, revive dialog
└── project.godot

```

---

### 3. Core Engine Subsystems

#### A. Decoupled Signal Bus (`event_bus.gd`)

Avoid hard references between bullets, UI, and boss entities. Centralize run events through an autoloaded `EventBus`:

```gdscript
# res://src/autoload/event_bus.gd
extends Node

# Player & Combat
signal player_damaged(current_hp: int, max_hp: int)
signal player_died()
signal special_gauge_changed(ratio: float)
signal weapon_upgraded(tier: int)
signal secondary_energy_changed(current_energy: float, max_energy: float)
signal secondary_weapon_fired(weapon_type: String)

# Enemies & Boss
signal enemy_destroyed(enemy_type: String, global_pos: Vector2, scrap_value: int)
signal boss_spawned(boss_name: String, max_hp: int)
signal boss_health_updated(current_hp: int)
signal boss_defeated()

# Economy & Drops
signal scrap_collected(amount: int)
signal energy_core_collected(amount: float)
signal powerup_picked(powerup_type: String)

```

---

#### B. High-Performance Object Pooling (`object_pool.gd`)

Instantiating bullets at 60–120 FPS on Android triggers garbage collector stutter. Re-use objects instead:

```gdscript
# res://src/pools/object_pool.gd
class_name ObjectPool
extends Node2D

@export var pool_size: int = 150
@export var bullet_scene: PackedScene

var _available_pool: Array[Node2D] = []

func _ready() -> void:
 for i in range(pool_size):
  var bullet: Node2D = bullet_scene.instantiate()
  bullet.set_process(false)
  bullet.hide()
  bullet.tree_exited.connect(func(): _available_pool.erase(bullet))
  add_child(bullet)
  _available_pool.append(bullet)

func spawn(spawn_pos: Vector2, direction: Vector2, speed: float, damage: int) -> Node2D:
 if _available_pool.is_empty():
  return null # Pool exhausted; drops shot safely instead of lagging
  
 var bullet: Node2D = _available_pool.pop_back()
 bullet.global_position = spawn_pos
 bullet.set_process(true)
 bullet.show()
 
 if bullet.has_method("initialize"):
  bullet.initialize(direction, speed, damage, self)
 return bullet

func recycle(bullet: Node2D) -> void:
 bullet.set_process(false)
 bullet.hide()
 _available_pool.append(bullet)

```

---

#### C. Mobile Player Controller with Relative Drag (`player.gd`)

Using relative screen drag keeps the player's thumb from obscuring the ship:

```gdscript
# res://src/entities/player/player.gd
extends Area2D

@export var fire_rate: float = 0.12 # Seconds per shot
@export var bullet_speed: float = 1200.0
@export var player_bullet_pool: ObjectPool
@export var muzzle_point: Marker2D

var _fire_timer: float = 0.0
var _active_touch_index: int = -1
var _weapon_level: int = 1

func _ready() -> void:
 area_entered.connect(_on_area_entered)

func _unhandled_input(event: InputEvent) -> void:
 # Relative drag touch handler
 if event is InputEventScreenTouch:
  if event.pressed and _active_touch_index == -1:
   _active_touch_index = event.index
  elif not event.pressed and event.index == _active_touch_index:
   _active_touch_index = -1
   
 elif event is InputEventScreenDrag and event.index == _active_touch_index:
  # Directly add relative movement with viewport bounds clamp
  position += event.relative
  var viewport_size: Vector2 = get_viewport_rect().size
  position.x = clamp(position.x, 32.0, viewport_size.x - 32.0)
  position.y = clamp(position.y, 32.0, viewport_size.y - 32.0)

func _process(delta: float) -> void:
 # Auto-fire loop
 _fire_timer += delta
 if _fire_timer >= fire_rate:
  _fire_timer = 0.0
  _execute_autofire()

func _execute_autofire() -> void:
 match _weapon_level:
  1:
   player_bullet_pool.spawn(muzzle_point.global_position, Vector2.RIGHT, bullet_speed, 10)
  2:
   var offset_up := Vector2(0, -12)
   var offset_down := Vector2(0, 12)
   player_bullet_pool.spawn(muzzle_point.global_position + offset_up, Vector2.RIGHT, bullet_speed, 10)
   player_bullet_pool.spawn(muzzle_point.global_position + offset_down, Vector2.RIGHT, bullet_speed, 10)
  _:
   # Level 3+: Spread shot
   player_bullet_pool.spawn(muzzle_point.global_position, Vector2.RIGHT, bullet_speed, 10)
   player_bullet_pool.spawn(muzzle_point.global_position, Vector2.RIGHT.rotated(deg_to_rad(12)), bullet_speed, 10)
   player_bullet_pool.spawn(muzzle_point.global_position, Vector2.RIGHT.rotated(deg_to_rad(-12)), bullet_speed, 10)

func _on_area_entered(other_area: Area2D) -> void:
 if other_area.is_in_group("powerups"):
  _handle_powerup(other_area.powerup_type)
  other_area.queue_free()

func _handle_powerup(type: String) -> void:
 match type:
  "WEAPON_UPGRADE":
   _weapon_level = mini(_weapon_level + 1, 4)
   EventBus.weapon_upgraded.emit(_weapon_level)
  "SPECIAL_RECHARGE":
   EventBus.special_gauge_changed.emit(1.0)

```

---

#### D. Modular Boss Pattern (Finite State Machine)

The boss is a composite entity: a core hull with child weak points (turrets, wings). The core cannot take damage until sub-systems are destroyed.

```gdscript
# res://src/entities/enemies/boss/boss_dreadnought.gd
extends Node2D

enum BossPhase { SHIELDED_TURRETS, ENRAGED_CORE, DEFEATED }

@export var max_health: int = 1500
@onready var weakpoints: Array[Node] = $WeakPoints.get_children()

var current_phase: BossPhase = BossPhase.SHIELDED_TURRETS
var current_health: int = 1500
var active_turrets: int = 0

func _ready() -> void:
 active_turrets = weakpoints.size()
 for wp in weakpoints:
  wp.destroyed.connect(_on_weakpoint_destroyed)
 
 EventBus.boss_spawned.emit("Dreadnought Nova", max_health)

func _on_weakpoint_destroyed() -> void:
 active_turrets -= 1
 if active_turrets <= 0:
  _transition_to_enraged()

func _transition_to_enraged() -> void:
 current_phase = BossPhase.ENRAGED_CORE
 $ShieldSprite.hide()
 $CoreHitbox.monitoring = true
 $CoreHitbox.monitorable = true
 # Trigger enraged bullet patterns or beam attacks

func take_damage(amount: int) -> void:
 if current_phase != BossPhase.ENRAGED_CORE:
  return
  
 current_health = maxi(current_health - amount, 0)
 EventBus.boss_health_updated.emit(current_health)
 
 if current_health <= 0:
  current_phase = BossPhase.DEFEATED
  EventBus.boss_defeated.emit()
  queue_free()

```

---

### 4. Android Configuration Checklist

In `project.godot`:

* **Display Settings:**
* `display/window/size/viewport_width = 1280`
* `display/window/size/viewport_height = 720`
* `display/window/stretch/mode = "canvas_items"`
* `display/window/stretch/aspect = "expand"` (handles 16:9, 18:9, and modern 20:9 ultrawide phone screens cleanly)
* `display/window/handheld/orientation = "sensor_landscape"`

* **Touch Emulation:**
* Enable `input_devices/pointing/emulate_touch_from_mouse = true` for easy desktop testing.

* **Rendering Method:**
* Use **Mobile** (Vulkan Mobile) or **Compatibility** (OpenGL ES 3.0). For a 2D shmup, **Compatibility** ensures maximum framerate consistency across entry-level Android chipsets.
