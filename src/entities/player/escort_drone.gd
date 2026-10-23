# res://src/entities/player/escort_drone.gd
class_name EscortDrone
extends Area2D

@export var escort_id: String = "specter"
@export var slot_index: int = 1 # 1 or 2

var player_node: Node2D = null
var player_bullet_pool: ObjectPool = null

var fire_delay: float = 0.50
var projectile_damage: int = 3
var max_shield_absorb: int = 3
var current_shield: int = 3
var is_rebooting: bool = false
var reboot_timer: float = 0.0
var reboot_duration: float = 3.5

var _fire_timer: float = 0.0
var _orbit_angle: float = 0.0
var _orbit_speed: float = 3.0
var _orbit_radius: float = 75.0
var _target_pos: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var shield_indicator: Node2D = $ShieldIndicator

func _ready() -> void:
	add_to_group("escorts")
	collision_layer = 16 # Escort layer
	collision_mask = 8   # Enemy bullets layer
	area_entered.connect(_on_area_entered)
	apply_chassis_data()

func apply_chassis_data() -> void:
	if not GameState.ESCORT_ROSTER.has(escort_id):
		escort_id = "specter"
	var data: Dictionary = GameState.ESCORT_ROSTER[escort_id]
	fire_delay = float(data.get("fire_delay", 0.25))
	projectile_damage = int(data.get("damage", 10))
	max_shield_absorb = int(data.get("max_shield", 3))
	current_shield = max_shield_absorb
	
	if sprite:
		var tex_path: String = data.get("sprite_path", "res://assets/sprites/player/drone_specter.svg")
		if ResourceLoader.exists(tex_path):
			var tex: Texture2D = load(tex_path)
			sprite.texture = tex
			if tex:
				var sz := tex.get_size()
				if sz.x > 96.0:
					var target_scale: float = 48.0 / sz.x
					sprite.scale = Vector2(target_scale, target_scale)
				else:
					sprite.scale = Vector2.ONE
			
	# Stagger initial orbit angle based on slot
	_orbit_angle = 0.0 if slot_index == 1 else PI

func _process(delta: float) -> void:
	if not player_node or not is_instance_valid(player_node):
		return
		
	# 1. Update position based on placement mode
	var mode: String = GameState.escort_placement_mode
	match mode:
		"flank":
			var y_offset := -55.0 if slot_index == 1 else 55.0
			var x_offset := -25.0
			_target_pos = player_node.global_position + Vector2(x_offset, y_offset)
			global_position = global_position.lerp(_target_pos, 14.0 * delta)
			rotation = 0.0
		"front":
			var x_offset := 65.0
			var y_offset := -28.0 if slot_index == 1 else 28.0
			_target_pos = player_node.global_position + Vector2(x_offset, y_offset)
			global_position = global_position.lerp(_target_pos, 16.0 * delta)
			rotation = 0.0
		"orbit":
			_orbit_angle += _orbit_speed * delta
			var offset := Vector2(cos(_orbit_angle), sin(_orbit_angle)) * _orbit_radius
			_target_pos = player_node.global_position + offset
			global_position = global_position.lerp(_target_pos, 18.0 * delta)
			rotation = _orbit_angle + (PI / 2.0)
		_:
			_target_pos = player_node.global_position + Vector2(-30, -50 if slot_index == 1 else 50)
			global_position = global_position.lerp(_target_pos, 14.0 * delta)
			
	# 2. Shield reboot recovery
	if is_rebooting:
		reboot_timer -= delta
		modulate.a = 0.35 + sin(reboot_timer * 12.0) * 0.2
		if reboot_timer <= 0:
			is_rebooting = false
			current_shield = max_shield_absorb
			modulate = Color.WHITE
			queue_redraw()
			
	# 3. Auto-fire cycle synchronized with player
	_fire_timer -= delta
	if _fire_timer <= 0 and not is_rebooting:
		_fire_timer = fire_delay
		_execute_escort_attack()
		
	# 4. Chronos vacuum passive
	if escort_id == "chronos_pod":
		_vacuum_nearby_scrap(delta)

func _execute_escort_attack() -> void:
	if not player_bullet_pool:
		return
		
	match escort_id:
		"specter":
			# High-speed twin darts
			player_bullet_pool.spawn(global_position + Vector2(8, -6), Vector2.RIGHT, 750.0, projectile_damage, false, false, 0.9, "laser")
			player_bullet_pool.spawn(global_position + Vector2(8, 6), Vector2.RIGHT, 750.0, projectile_damage, false, false, 0.9, "laser")
		"aegis_drone":
			# Piercing focused laser dart
			player_bullet_pool.spawn(global_position + Vector2(10, 0), Vector2.RIGHT, 820.0, projectile_damage, false, false, 0.9, "helix")
		"goliath":
			# Micro-torpedo with heavy impact
			player_bullet_pool.spawn(global_position + Vector2(12, 0), Vector2.RIGHT, 540.0, projectile_damage, false, true, 1.1, "missile")
		"chronos_pod":
			# Dual stasis vulcan
			player_bullet_pool.spawn(global_position + Vector2(8, -4), Vector2.RIGHT, 700.0, projectile_damage, false, false, 0.9, "plasma")
			player_bullet_pool.spawn(global_position + Vector2(8, 4), Vector2.RIGHT, 700.0, projectile_damage, false, false, 0.9, "plasma")

func _vacuum_nearby_scrap(delta: float) -> void:
	var items := get_tree().get_nodes_in_group("items")
	for item in items:
		if item is Node2D and is_instance_valid(item):
			var dist := global_position.distance_to(item.global_position)
			if dist <= 380.0:
				var pull_dir: Vector2 = (global_position - (item as Node2D).global_position).normalized()
				item.global_position += pull_dir * 520.0 * delta

func _on_area_entered(other: Area2D) -> void:
	# Bullet Absorption mechanic!
	if other.has_method("recycle") and other.get("is_enemy_bullet") == true:
		_absorb_bullet(other)

func _absorb_bullet(bullet: Area2D) -> void:
	# Delete / recycle bullet
	bullet.recycle()
	AudioManager.play_sfx("bullet_absorb", true)
	
	if is_rebooting:
		return
		
	current_shield -= 1
	_flash_absorption()
	
	if current_shield <= 0:
		_enter_reboot()

func _flash_absorption() -> void:
	# Bright energy deflection pulse
	var tween := create_tween()
	modulate = Color(2.5, 2.5, 3.0, 1.0)
	scale = Vector2(1.25, 1.25)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.15)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.15)
	queue_redraw()

func _enter_reboot() -> void:
	is_rebooting = true
	reboot_timer = reboot_duration
	var main := get_parent()
	if main and main.has_method("shake_camera"):
		main.shake_camera(4.0, 0.15)

func _draw() -> void:
	# Draw protective energy ring showing remaining shield absorb charges
	if not is_rebooting and current_shield > 0:
		var ratio := float(current_shield) / float(max_shield_absorb)
		var ring_color := Color(0.2, 0.9, 1.0, 0.45 * ratio)
		draw_arc(Vector2.ZERO, 20.0, 0, TAU * ratio, 24, ring_color, 2.0)
