# res://src/entities/environment/obstacle_debris.gd
class_name ObstacleDebris
extends Area2D

@export var obstacle_type: String = "asteroid" # "asteroid" or "girder"
@export var drift_speed: float = 120.0
@export var rotation_speed: float = 0.4
@export var ram_damage: int = 40

var _velocity: Vector2 = Vector2.LEFT

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("obstacles")
	# Collision setup:
	# Layer 32: obstacles
	# Mask 1 (Player), 6 (Enemies/Projectiles), 8 (Enemy Bullets)
	collision_layer = 32
	collision_mask = 1 | 2 | 8
	
	area_entered.connect(_on_area_entered)
	_setup_visuals()

func _setup_visuals() -> void:
	if not sprite:
		return
		
	match obstacle_type:
		"asteroid":
			var path := "res://assets/sprites/environment/debris_asteroid.svg"
			if ResourceLoader.exists(path):
				sprite.texture = load(path)
			rotation_speed = randf_range(-0.8, 0.8)
			var s := randf_range(0.85, 1.35)
			scale = Vector2(s, s)
		"girder":
			var path := "res://assets/sprites/environment/debris_girder.svg"
			if ResourceLoader.exists(path):
				sprite.texture = load(path)
			rotation_speed = 0.0 # Fixed structural geometry
			scale = Vector2(1.0, 1.0)

func _process(delta: float) -> void:
	# Move leftwards across the screen
	position.x -= drift_speed * delta
	if rotation_speed != 0.0:
		rotation += rotation_speed * delta
		
	# Despawn when exiting left side of viewport
	if global_position.x < -140.0:
		queue_free()

func _on_area_entered(other: Area2D) -> void:
	# 1. Blocks & Absorbs Enemy Bullets (Tactical Cover for Player!)
	if other.has_method("recycle") and other.get("is_enemy_bullet") == true:
		other.recycle()
		_flash_impact(Color(1.5, 1.5, 2.0))
		return
		
	# 2. Player rams into obstacle
	if other.is_in_group("player") and other.has_method("take_damage"):
		other.take_damage(ram_damage)
		_flash_impact(Color(2.5, 0.5, 0.5))
		
	# 3. Enemy rams into obstacle (destroys weak scouts, damages heavy craft)
	elif other.is_in_group("enemies") and other.has_method("take_damage"):
		other.take_damage(60)
		_flash_impact(Color(2.0, 1.5, 0.5))

func _flash_impact(flash_color: Color) -> void:
	if not sprite:
		return
	var tween := create_tween()
	sprite.modulate = flash_color
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
