# res://src/entities/items/scrap_item.gd
class_name ScrapItem
extends Area2D

@export var scrap_value: int = 10
@export var base_speed: float = 140.0
@export var wave_frequency: float = 3.5
@export var wave_amplitude: float = 35.0
@export var magnet_radius: float = 200.0

var _time_alive: float = 0.0
var _base_y: float = 0.0
var _target_player: Node2D = null
var _is_collected: bool = false
var _magnet_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("items")
	add_to_group("scrap")
	_base_y = position.y
	_time_alive = randf() * 10.0 # Random initial phase
	area_entered.connect(_on_area_entered)
	
	if has_node("/root/GameState"):
		magnet_radius = GameState.get_magnet_radius()
	
	# Find player reference in scene
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target_player = players[0]

func _process(delta: float) -> void:
	if _is_collected:
		return
		
	_time_alive += delta
	rotation += 3.0 * delta
	
	# Check distance to player for tractor beam / magnetization
	if _target_player and is_instance_valid(_target_player):
		var dist := global_position.distance_to(_target_player.global_position)
		if dist <= magnet_radius:
			# Pull aggressively toward player
			var pull_dir := (_target_player.global_position - global_position).normalized()
			var pull_speed := lerpf(450.0, 900.0, 1.0 - (dist / magnet_radius))
			_magnet_velocity = _magnet_velocity.move_toward(pull_dir * pull_speed, 1800.0 * delta)
			global_position += _magnet_velocity * delta
			return
	
	# Natural sine-wave drift moving left
	position.x -= base_speed * delta
	position.y = _base_y + sin(_time_alive * wave_frequency) * wave_amplitude
	
	# Despawn when off-screen left
	if global_position.x < -60.0:
		queue_free()

func _on_area_entered(other: Area2D) -> void:
	if _is_collected:
		return
	if other.is_in_group("player"):
		_collect()

func _collect() -> void:
	_is_collected = true
	EventBus.scrap_collected.emit(scrap_value)
	EventBus.energy_core_collected.emit(8.0) # Grants secondary weapon energy
	if has_node("/root/GameState"):
		GameState.add_run_scrap(scrap_value)
	
	# Quick pickup pop animation
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
