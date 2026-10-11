# res://src/entities/enemies/boss/boss_core_hitbox.gd
extends Area2D

func take_damage(amount: int) -> void:
	if get_parent().has_method("take_damage"):
		get_parent().take_damage(amount)
