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

func spawn(spawn_pos: Vector2, direction: Vector2, speed: float, damage: int, is_enemy: bool = false, is_homing: bool = false, scale_mult: float = 1.0, p_type: String = "") -> Node2D:
	if _available_pool.is_empty():
		return null # Pool exhausted; drops shot safely instead of causing garbage collector stutter
		
	var bullet: Node2D = _available_pool.pop_back()
	bullet.global_position = spawn_pos
	bullet.show()
	bullet.set_process(true)
	
	if bullet.has_method("initialize"):
		bullet.initialize(direction, speed, damage, self, is_enemy, is_homing, scale_mult, p_type)
	return bullet

func recycle(bullet: Node2D) -> void:
	bullet.set_process(false)
	bullet.hide()
	_available_pool.append(bullet)

func clear_all_active() -> void:
	for child in get_children():
		if child is Node2D and child.visible:
			recycle(child)

func cancel_bullets_to_scrap() -> int:
	var count: int = 0
	var scrap_scene: PackedScene = load("res://src/entities/items/scrap_item.tscn")
	var parent_node := get_parent()
	for child in get_children():
		if child is Node2D and child.visible:
			var pos: Vector2 = child.global_position
			recycle(child)
			count += 1
			# Spawn scrap every 2nd cancelled bullet to reward player without overloading
			if count % 2 == 0 and scrap_scene and parent_node:
				var scrap := scrap_scene.instantiate() as Node2D
				scrap.global_position = pos
				parent_node.call_deferred("add_child", scrap)
	return count
