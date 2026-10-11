# res://src/entities/enemies/base_enemy.gd
class_name BaseEnemy
extends Area2D

@export var max_health: int = 30
@export var scrap_reward: int = 15
@export var ram_damage: int = 25
@export var speed: float = 200.0

var current_health: int = 30
var enemy_bullet_pool: ObjectPool = null

@onready var sprite: Sprite2D = $Sprite2D

var _scrap_scene: PackedScene = preload("res://src/entities/items/scrap_item.tscn")
var _is_dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	area_entered.connect(_on_area_entered)

func take_damage(amount: int) -> void:
	if _is_dead:
		return
		
	current_health = maxi(current_health - amount, 0)
	_flash_hit()
	
	if current_health <= 0:
		_die()

func _flash_hit() -> void:
	if not sprite:
		return
	var tween := create_tween()
	sprite.modulate = Color(3.0, 3.0, 3.0, 1.0) # Bright white flash
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	EventBus.enemy_destroyed.emit("Scout", global_position, scrap_reward)
	
	# Drop scrap crystal
	if _scrap_scene:
		var scrap := _scrap_scene.instantiate() as Node2D
		scrap.global_position = global_position
		get_parent().call_deferred("add_child", scrap)
		
	# Quick death pop
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)

func get_ram_damage() -> int:
	return ram_damage

func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("player"):
		# Player rams enemy
		take_damage(50)
