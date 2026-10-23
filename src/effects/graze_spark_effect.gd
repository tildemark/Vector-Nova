# res://src/effects/graze_spark_effect.gd
class_name GrazeSparkEffect
extends Node2D

const GRAZE_TEX = preload("res://assets/sprites/projectiles/graze_spark.png")

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = GRAZE_TEX
	sprite.rotation = randf_range(0.0, TAU)
	sprite.scale = Vector2(0.2, 0.2)
	sprite.modulate = Color(2.5, 2.5, 2.8, 1.0) # High-energy electric cyan flash
	add_child(sprite)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(0.65, 0.65), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

static func create(parent: Node, pos: Vector2) -> GrazeSparkEffect:
	if not parent:
		return null
	var spark := GrazeSparkEffect.new()
	spark.global_position = pos
	parent.add_child(spark)
	return spark
