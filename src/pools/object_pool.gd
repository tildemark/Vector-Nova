# res://src/pools/object_pool.gd
class_name ObjectPool
extends Node2D

@export var pool_size: int = 150
@export var bullet_scene: PackedScene

var _available_pool: Array[Node2D] = []

func _ready() -> void:
	if not bullet_scene:
		push_warning("ObjectPool: bullet_scene not assigned!")
		return
	for i in range(pool_size):
		var bullet: Node2D = bullet_scene.instantiate()
		bullet.set_process(false)
		bullet.hide()
		bullet.tree_exited.connect(func(): _available_pool.erase(bullet))
		add_child(bullet)
		_available_pool.append(bullet)

func spawn(spawn_pos: Vector2, direction: Vector2, speed: float, damage: int, is_enemy: bool = false, is_homing: bool = false) -> Node2D:
	if _available_pool.is_empty():
		return null # Pool exhausted; drops shot safely instead of causing garbage collector stutter
		
	var bullet: Node2D = _available_pool.pop_back()
	bullet.global_position = spawn_pos
	bullet.show()
	bullet.set_process(true)
	
	if bullet.has_method("initialize"):
		bullet.initialize(direction, speed, damage, self, is_enemy, is_homing)
	return bullet

func recycle(bullet: Node2D) -> void:
	bullet.set_process(false)
	bullet.hide()
	_available_pool.append(bullet)

func clear_all_active() -> void:
	for child in get_children():
		if child is Node2D and child.visible:
			recycle(child)
