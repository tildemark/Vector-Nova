# res://src/effects/explosion_effect.gd
class_name ExplosionEffect
extends Node2D

enum ExplosionSize { TINY, SMALL, BIG }

@export var explosion_size: ExplosionSize = ExplosionSize.SMALL

const TINY_TEX = preload("res://assets/sprites/projectiles/tiny_explosion.png")
const SMALL_TEX = preload("res://assets/sprites/projectiles/small_explosion.png")
const BIG_TEX = preload("res://assets/sprites/projectiles/big_explosion.png")

var _sprite: Sprite2D = null

func _ready() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	
	var duration := 0.22
	var start_scale := Vector2(0.3, 0.3)
	var end_scale := Vector2(0.9, 0.9)
	var end_modulate := Color(1.2, 1.2, 1.2, 0.0)
	
	match explosion_size:
		ExplosionSize.TINY:
			_sprite.texture = TINY_TEX
			duration = 0.18
			start_scale = Vector2(0.18, 0.18)
			end_scale = Vector2(0.55, 0.55)
			_sprite.modulate = Color(2.5, 2.2, 1.8, 1.0)
		ExplosionSize.SMALL:
			_sprite.texture = SMALL_TEX
			duration = 0.28
			start_scale = Vector2(0.28, 0.28)
			end_scale = Vector2(0.85, 0.85)
			_sprite.modulate = Color(2.5, 2.0, 1.5, 1.0)
		ExplosionSize.BIG:
			_sprite.texture = BIG_TEX
			duration = 0.48
			start_scale = Vector2(0.4, 0.4)
			end_scale = Vector2(1.5, 1.5)
			_sprite.modulate = Color(3.0, 2.2, 1.6, 1.0)
			
	_sprite.rotation = randf_range(0.0, TAU)
	_sprite.scale = start_scale
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sprite, "scale", end_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "modulate", end_modulate, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

static func create(parent: Node, pos: Vector2, size: ExplosionSize = ExplosionSize.SMALL) -> ExplosionEffect:
	if not parent:
		return null
	var fx := ExplosionEffect.new()
	fx.explosion_size = size
	fx.global_position = pos
	parent.add_child(fx)
	return fx
