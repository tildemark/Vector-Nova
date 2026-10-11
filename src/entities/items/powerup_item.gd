# res://src/entities/items/powerup_item.gd
class_name PowerUpItem
extends Area2D

@export var powerup_type: String = "WEAPON_UPGRADE"
@export var base_speed: float = 110.0
@export var wave_frequency: float = 2.5
@export var wave_amplitude: float = 40.0
@export var magnet_radius: float = 160.0

var _time_alive: float = 0.0
var _base_y: float = 0.0
var _target_player: Node2D = null
var _is_collected: bool = false
var _magnet_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("items")
	add_to_group("powerups")
	_base_y = position.y
	area_entered.connect(_on_area_entered)
	
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target_player = players[0]

func _process(delta: float) -> void:
	if _is_collected:
		return
		
	_time_alive += delta
	
	# Pulsating visual breathing scale
	var pulse := 1.0 + sin(_time_alive * 6.0) * 0.12
	scale = Vector2(pulse, pulse)
	
	# Magnetize toward player if close
	if _target_player and is_instance_valid(_target_player):
		var dist := global_position.distance_to(_target_player.global_position)
		if dist <= magnet_radius:
			var pull_dir := (_target_player.global_position - global_position).normalized()
			var pull_speed := lerpf(400.0, 800.0, 1.0 - (dist / magnet_radius))
			_magnet_velocity = _magnet_velocity.move_toward(pull_dir * pull_speed, 1500.0 * delta)
			global_position += _magnet_velocity * delta
			return
			
	# Leftward drift with sine wave
	position.x -= base_speed * delta
	position.y = _base_y + sin(_time_alive * wave_frequency) * wave_amplitude
	
	if global_position.x < -60.0:
		queue_free()

func get_powerup_type() -> String:
	return powerup_type

func _on_area_entered(other: Area2D) -> void:
	if _is_collected:
		return
	if other.is_in_group("player"):
		_collect(other)

func _collect(player_node: Area2D) -> void:
	_is_collected = true
	EventBus.powerup_picked.emit(powerup_type)
	if player_node.has_method("_handle_powerup"):
		player_node._handle_powerup(powerup_type)
		
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
