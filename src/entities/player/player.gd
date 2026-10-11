# res://src/entities/player/player.gd
class_name Player
extends Area2D

@export var max_health: int = 100
@export var current_health: int = 100
@export var fire_rate: float = 0.12 # Seconds per shot
@export var bullet_speed: float = 1250.0
@export var player_bullet_pool: ObjectPool

@onready var muzzle_point: Marker2D = $MuzzlePoint
@onready var ship_sprite: Sprite2D = $ShipSprite
@onready var thruster_sprite: Sprite2D = $ThrusterSprite

var _fire_timer: float = 0.0
var _active_touch_index: int = -1
var _weapon_level: int = 1
var _thruster_time: float = 0.0
var _target_tilt: float = 0.0

func _ready() -> void:
	add_to_group("player")
	
	# Apply GameState permanent upgrades & boosters
	if has_node("/root/GameState"):
		max_health = 100 + GameState.get_bonus_hp()
		current_health = max_health
		fire_rate = GameState.get_fire_rate_delay()
		_weapon_level = GameState.get_starting_weapon_level()
	else:
		current_health = max_health
		
	area_entered.connect(_on_area_entered)
	EventBus.player_damaged.emit(current_health, max_health)

func _unhandled_input(event: InputEvent) -> void:
	# Relative screen drag touch control
	if event is InputEventScreenTouch:
		if event.pressed and _active_touch_index == -1:
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
		
	# Fallback for mouse dragging during desktop testing
	elif event is InputEventMouseButton and _active_touch_index == -1:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				_target_tilt = 0.0
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and _active_touch_index == -1:
		position += event.relative
		_clamp_to_viewport()
		_target_tilt = clampf(event.relative.y * 0.03, -0.25, 0.25)

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

func _clamp_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var margin_x := 48.0
	var margin_y := 36.0
	position.x = clampf(position.x, margin_x, viewport_size.x - margin_x)
	position.y = clampf(position.y, margin_y, viewport_size.y - margin_y)

func _execute_autofire() -> void:
	if not player_bullet_pool:
		return
		
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

func take_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	EventBus.player_damaged.emit(current_health, max_health)
	_flash_hit()
	
	if current_health <= 0:
		EventBus.player_died.emit()
		# Hide or explode
		hide()
		set_process(false)

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
