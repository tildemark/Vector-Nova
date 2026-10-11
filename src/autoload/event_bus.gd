# res://src/autoload/event_bus.gd
extends Node

## Centralized EventBus for decoupled global signaling across entities, pools, and UI

# Player & Combat Signals
signal player_damaged(current_hp: int, max_hp: int)
signal player_died()
signal special_gauge_changed(ratio: float)
signal special_attack_triggered()
signal weapon_upgraded(tier: int)

# Enemies & Boss Signals
signal enemy_destroyed(enemy_type: String, global_pos: Vector2, scrap_value: int)
signal boss_spawned(boss_name: String, max_hp: int)
signal boss_health_updated(current_hp: int)
signal boss_defeated()

# Economy & Drops Signals
signal scrap_collected(amount: int)
signal powerup_picked(powerup_type: String)

# System / Wave Signals
signal wave_started(wave_num: int)
signal game_paused(is_paused: bool)
signal score_updated(score: int)
