# res://src/entities/player/player.gd
class_name Player
extends Area2D

@export var max_health: int = 100
@export var current_health: int = 100
@export var fire_rate: float = 0.12 # Seconds per shot
@export var bullet_speed: float = 1250.0
@export var player_bullet_pool: ObjectPool

# Secondary Tactical Weapon
@export var max_secondary_energy: float = 100.0
var current_secondary_energy: float = 100.0 # Start fully charged for immediate tactile response
var secondary_cost: float = 25.0 # Consumes 25% energy per salvo (4 salvos per full meter)
var secondary_type: String = "SWARM_MISSILES"

const HyperBeamScene = preload("res://src/effects/hyper_beam.tscn")
const PulseMortarScene = preload("res://src/effects/pulse_mortar.tscn")
const KineticBarrierScene = preload("res://src/effects/kinetic_barrier.tscn")
const GravVortexScene = preload("res://src/effects/grav_vortex.tscn")

@onready var muzzle_point: Marker2D = $MuzzlePoint
@onready var ship_sprite: Sprite2D = $ShipSprite
@onready var thruster_sprite: Sprite2D = $ThrusterSprite

var _fire_timer: float = 0.0
var _active_touch_index: int = -1
var _weapon_level: int = 1
var _thruster_time: float = 0.0
var _target_tilt: float = 0.0

# Double-Tap detection variables
var _last_tap_time: int = 0
var _last_tap_pos: Vector2 = Vector2.ZERO
const DOUBLE_TAP_MAX_DELAY_MS: int = 350
const DOUBLE_TAP_MAX_DISTANCE: float = 90.0

func _ready() -> void:
	add_to_group("player")
	
	# Apply GameState permanent upgrades & boosters
	if has_node("/root/GameState"):
		var ship_info: Dictionary = GameState.get_selected_ship()
		var base_hp: int = int(ship_info.get("hp", 100))
		max_health = base_hp + GameState.get_bonus_hp()
		current_health = max_health
		fire_rate = GameState.get_fire_rate_delay()
		_weapon_level = GameState.get_starting_weapon_level()
		secondary_type = str(ship_info.get("secondary_type", "SWARM_MISSILES"))
		
		# Load ship custom vector sprite
		var sprite_path: String = str(ship_info.get("sprite_path", ""))
		if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			var tex: Texture2D = load(sprite_path)
			if tex and ship_sprite:
				ship_sprite.texture = tex
				var tex_size := tex.get_size()
				if tex_size.x > 128.0:
					var target_scale: float = 96.0 / tex_size.x
					ship_sprite.scale = Vector2(target_scale, target_scale)
				else:
					ship_sprite.scale = Vector2.ONE
	else:
		current_health = max_health
		
	area_entered.connect(_on_area_entered)
	EventBus.energy_core_collected.connect(add_secondary_energy)
	EventBus.player_damaged.emit(current_health, max_health)
	EventBus.secondary_energy_changed.emit(current_secondary_energy, max_secondary_energy)
	
	if has_node("GrazeArea"):
		$GrazeArea.area_entered.connect(_on_graze_area_entered)

func _unhandled_input(event: InputEvent) -> void:
	# Relative screen drag touch control & Double-Tap detection
	var screen_width := get_viewport_rect().size.x
	
	if event is InputEventScreenTouch:
		if event.pressed:
			var now := Time.get_ticks_msec()
			var is_right_half: bool = event.position.x >= (screen_width * 0.5)
			
			if is_right_half and (now - _last_tap_time) <= DOUBLE_TAP_MAX_DELAY_MS and event.position.distance_to(_last_tap_pos) <= DOUBLE_TAP_MAX_DISTANCE:
				fire_secondary_weapon()
				_last_tap_time = 0
			else:
				if is_right_half:
					_last_tap_time = now
					_last_tap_pos = event.position
				else:
					_last_tap_time = 0
				
			if _active_touch_index == -1:
				_active_touch_index = event.index
		elif not event.pressed and event.index == _active_touch_index:
			_active_touch_index = -1
			_target_tilt = 0.0
			
	elif event is InputEventScreenDrag and event.index == _active_touch_index:
		# Directly add relative motion without thumb blocking ship
		position += event.relative
		_clamp_to_viewport()
		
		# Subtle vertical banking tilt
		_target_tilt = clampf(event.relative.y * 0.03, -0.25, 0.25)
		
	# Mouse support (Desktop testing & Double-Click / Right-Click)
	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				fire_secondary_weapon()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				var now := Time.get_ticks_msec()
				var is_right_half: bool = event.position.x >= (screen_width * 0.5)
				if is_right_half and (now - _last_tap_time) <= DOUBLE_TAP_MAX_DELAY_MS and event.position.distance_to(_last_tap_pos) <= DOUBLE_TAP_MAX_DISTANCE:
					fire_secondary_weapon()
					_last_tap_time = 0
				else:
					if is_right_half:
						_last_tap_time = now
						_last_tap_pos = event.position
					else:
						_last_tap_time = 0
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _active_touch_index == -1:
			_target_tilt = 0.0

	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and _active_touch_index == -1:
		position += event.relative
		_clamp_to_viewport()
		_target_tilt = clampf(event.relative.y * 0.03, -0.25, 0.25)

	# Keyboard shortcuts (Spacebar / C)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_C:
			fire_secondary_weapon()

func _process(delta: float) -> void:
	# Smooth banking tilt return
	rotation = lerp_angle(rotation, _target_tilt, 12.0 * delta)
	_target_tilt = lerp(_target_tilt, 0.0, 6.0 * delta)
	
	# Thruster flame pulsating animation
	_thruster_time += delta * 25.0
	if thruster_sprite:
		var scale_pulse := 1.0 + sin(_thruster_time) * 0.15
		thruster_sprite.scale = Vector2(scale_pulse, 1.0 + cos(_thruster_time * 1.5) * 0.1)
	
	# Auto-fire loop
	_fire_timer += delta
	if _fire_timer >= fire_rate:
		_fire_timer = 0.0
		_execute_autofire()
		
	queue_redraw()

func _draw() -> void:
	# Arcade precision dodging hitbox indicator dot
	draw_circle(Vector2.ZERO, 6.0, Color(0.0, 0.95, 1.0, 0.45))
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)

func _on_graze_area_entered(other: Area2D) -> void:
	if other.has_method("recycle") and other.get("is_enemy_bullet") == true:
		add_secondary_energy(1.2)
		EventBus.player_grazed.emit(global_position)

func _clamp_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var margin_x := 48.0
	var margin_y := 36.0
	position.x = clampf(position.x, margin_x, viewport_size.x - margin_x)
	position.y = clampf(position.y, margin_y, viewport_size.y - margin_y)

func _execute_autofire() -> void:
	if not player_bullet_pool:
		return
		
	AudioManager.play_sfx("laser", true)
	var spawn_pos: Vector2 = muzzle_point.global_position if muzzle_point else global_position
	
	match _weapon_level:
		1:
			player_bullet_pool.spawn(spawn_pos, Vector2.RIGHT, bullet_speed, 12, false, false)
		2:
			var offset_up := Vector2(0, -12)
			var offset_down := Vector2(0, 12)
			player_bullet_pool.spawn(spawn_pos + offset_up, Vector2.RIGHT, bullet_speed, 12, false, false)
			player_bullet_pool.spawn(spawn_pos + offset_down, Vector2.RIGHT, bullet_speed, 12, false, false)
		3:
			player_bullet_pool.spawn(spawn_pos, Vector2.RIGHT, bullet_speed, 14, false, false)
			player_bullet_pool.spawn(spawn_pos, Vector2.RIGHT.rotated(deg_to_rad(12)), bullet_speed, 12, false, false)
			player_bullet_pool.spawn(spawn_pos, Vector2.RIGHT.rotated(deg_to_rad(-12)), bullet_speed, 12, false, false)
		_:
			# Level 4: Overcharged spread + 2 homing micro-missiles!
			player_bullet_pool.spawn(spawn_pos + Vector2(0, -8), Vector2.RIGHT, bullet_speed, 15, false, false)
			player_bullet_pool.spawn(spawn_pos + Vector2(0, 8), Vector2.RIGHT, bullet_speed, 15, false, false)
			player_bullet_pool.spawn(spawn_pos, Vector2.RIGHT.rotated(deg_to_rad(14)), bullet_speed, 14, false, false)
			player_bullet_pool.spawn(spawn_pos, Vector2.RIGHT.rotated(deg_to_rad(-14)), bullet_speed, 14, false, false)
			# Homing micro-missiles curving toward enemies
			player_bullet_pool.spawn(spawn_pos + Vector2(-10, -20), Vector2.RIGHT.rotated(deg_to_rad(28)), bullet_speed * 0.75, 25, false, true)
			player_bullet_pool.spawn(spawn_pos + Vector2(-10, 20), Vector2.RIGHT.rotated(deg_to_rad(-28)), bullet_speed * 0.75, 25, false, true)

var _emp_shockwave_scene: PackedScene = preload("res://src/effects/emp_shockwave.tscn")

func trigger_emp() -> void:
	# Spawn shockwave
	if _emp_shockwave_scene:
		var wave := _emp_shockwave_scene.instantiate() as Node2D
		wave.global_position = global_position
		get_parent().add_child(wave)
		
	# Clear all active enemy bullets
	var main_node := get_parent()
	if main_node and main_node.has_node("EnemyBulletPool"):
		main_node.get_node("EnemyBulletPool").clear_all_active()
		
	# Deal massive EMP damage to all active enemies
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(160)
			
	EventBus.special_attack_triggered.emit()

var _revive_used: bool = false

func take_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	EventBus.player_damaged.emit(current_health, max_health)
	_flash_hit()
	
	if current_health <= 0:
		# Check Apex Chronos Supporter Chrono-Revival (100% full hull restart)
		if GameState.selected_ship_id == "apex" and not _revive_used:
			_revive_used = true
			_trigger_chrono_revive()
			return
			
		EventBus.player_died.emit()
		# Hide or explode
		hide()
		set_process(false)

func _trigger_chrono_revive() -> void:
	# 100% Full Hull Chrono-Revive with screen EMP shockwave!
	current_health = max_health
	EventBus.player_damaged.emit(current_health, max_health)
	trigger_emp()
	
	# Visual Time-Stasis Rewind Effect
	if ship_sprite:
		var tween := create_tween()
		ship_sprite.modulate = Color(2.5, 1.0, 3.0, 1.0)
		scale = Vector2(1.8, 1.8)
		tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.4)
		tween.parallel().tween_property(ship_sprite, "modulate", Color.WHITE, 0.4)

func _flash_hit() -> void:
	if not ship_sprite:
		return
	var tween := create_tween()
	ship_sprite.modulate = Color(3.0, 1.0, 1.0, 1.0) # Bright flash
	tween.tween_property(ship_sprite, "modulate", Color.WHITE, 0.15)

func _on_area_entered(other_area: Area2D) -> void:
	if other_area.is_in_group("powerups"):
		if other_area.has_method("get_powerup_type"):
			_handle_powerup(other_area.get_powerup_type())
		other_area.queue_free()
	elif other_area.is_in_group("enemies") and other_area.has_method("get_ram_damage"):
		take_damage(other_area.get_ram_damage())

func _handle_powerup(powerup_type: String) -> void:
	match powerup_type:
		"WEAPON_UPGRADE":
			_weapon_level = mini(_weapon_level + 1, 4)
			EventBus.weapon_upgraded.emit(_weapon_level)
		"SPECIAL_RECHARGE":
			EventBus.special_gauge_changed.emit(1.0)
		"SHIELD_REPAIR":
			current_health = mini(current_health + 35, max_health)
			EventBus.player_damaged.emit(current_health, max_health)

func add_secondary_energy(amount: float) -> void:
	current_secondary_energy = clampf(current_secondary_energy + amount, 0.0, max_secondary_energy)
	EventBus.secondary_energy_changed.emit(current_secondary_energy, max_secondary_energy)

func fire_secondary_weapon() -> bool:
	if current_secondary_energy < secondary_cost:
		return false
		
	current_secondary_energy -= secondary_cost
	EventBus.secondary_energy_changed.emit(current_secondary_energy, max_secondary_energy)
	EventBus.secondary_weapon_fired.emit(secondary_type)
	
	match secondary_type:
		"SWARM_MISSILES":
			_fire_swarm_missiles()
		"HYPER_BEAM":
			_fire_hyper_beam()
		"PULSE_MORTAR":
			_fire_pulse_mortar()
		"DEFLECTOR_BARRIER":
			_fire_deflector_barrier()
		"GRAV_VORTEX":
			_fire_grav_vortex()
		_:
			_fire_swarm_missiles()
	return true

func _fire_swarm_missiles() -> void:
	if not player_bullet_pool:
		return
		
	var spawn_pos: Vector2 = muzzle_point.global_position if muzzle_point else global_position
	# Launch a fan salvo of 8 seeker micro-missiles
	var angles: Array[float] = [-52.0, -36.0, -20.0, -7.0, 7.0, 20.0, 36.0, 52.0]
	for i in range(angles.size()):
		var angle_deg: float = angles[i]
		var dir := Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
		var offset := Vector2(-8, angle_deg * 0.4)
		player_bullet_pool.spawn(spawn_pos + offset, dir, bullet_speed * 0.85, 28, false, true)
		
	_flash_muzzle_secondary()

func _fire_hyper_beam() -> void:
	if not HyperBeamScene:
		return
	var beam: Node2D = HyperBeamScene.instantiate()
	if beam.has_method("setup"):
		beam.setup(self)
	get_parent().add_child(beam)
	_flash_muzzle_secondary()

func _fire_pulse_mortar() -> void:
	if not PulseMortarScene:
		return
	var mortar: Node2D = PulseMortarScene.instantiate()
	mortar.global_position = muzzle_point.global_position if muzzle_point else global_position
	get_parent().add_child(mortar)
	_flash_muzzle_secondary()

func _fire_deflector_barrier() -> void:
	if not KineticBarrierScene:
		return
	var barrier: Node2D = KineticBarrierScene.instantiate()
	if barrier.has_method("setup"):
		barrier.setup(self)
	get_parent().add_child(barrier)
	_flash_muzzle_secondary()

func _fire_grav_vortex() -> void:
	if not GravVortexScene:
		return
	var vortex: Node2D = GravVortexScene.instantiate()
	vortex.global_position = muzzle_point.global_position if muzzle_point else global_position
	get_parent().add_child(vortex)
	_flash_muzzle_secondary()

func _flash_muzzle_secondary() -> void:
	if ship_sprite:
		var tween := create_tween()
		ship_sprite.modulate = Color(1.5, 2.0, 3.0, 1.0) # Electric cyan surge
		tween.tween_property(ship_sprite, "modulate", Color.WHITE, 0.12)
