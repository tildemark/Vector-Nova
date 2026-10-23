# res://src/entities/enemies/enemy_scout.gd
class_name EnemyScout
extends BaseEnemy

@export var wave_frequency: float = 3.0
@export var wave_amplitude: float = 60.0
@export var shoot_interval: float = 1.8

var _time_alive: float = 0.0
var _base_y: float = 0.0
var _shoot_timer: float = 0.0

func _ready() -> void:
	super._ready()
	_base_y = position.y
	_shoot_timer = randf() * 0.8 # Stagger shooting across scouts

func _process(delta: float) -> void:
	if _is_dead:
		return
		
	_time_alive += delta
	position.x -= speed * delta
	position.y = _base_y + sin(_time_alive * wave_frequency) * wave_amplitude
	
	# Shooting logic
	_shoot_timer += delta
	if _shoot_timer >= shoot_interval:
		_shoot_timer = 0.0
		_fire_plasma()
		
	# Despawn when exiting left
	if global_position.x < -80.0:
		queue_free()

func _fire_plasma() -> void:
	if not enemy_bullet_pool:
		return
	# Shoot directly to the left with slight lead
	enemy_bullet_pool.spawn(global_position + Vector2(-28, 0), Vector2.LEFT, 500.0, 10, true, false, 1.0, "enemy_orb")
