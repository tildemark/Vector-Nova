# res://src/autoload/event_bus.gd
extends Node

## Centralized EventBus for decoupled global signaling across entities, pools, and UI

# Player & Combat Signals
signal player_damaged(current_hp: int, max_hp: int)
signal player_died()
signal special_gauge_changed(ratio: float)
signal special_attack_triggered()
signal secondary_energy_changed(current_energy: float, max_energy: float)
signal secondary_weapon_fired(weapon_type: String)
signal weapon_upgraded(tier: int)

# Enemies & Boss Signals
signal enemy_destroyed(enemy_type: String, global_pos: Vector2, scrap_value: int)
signal boss_spawned(boss_name: String, max_hp: int)
signal boss_health_updated(current_hp: int)
signal boss_weakpoint_health_updated(id_name: String, current_hp: int, max_hp: int)
signal boss_defeated()

# Economy & Drops Signals
signal scrap_collected(amount: int)
signal energy_core_collected(amount: float)
signal powerup_picked(powerup_type: String)

# System / Wave / Retro Signals
signal wave_started(wave_num: int)
signal game_paused(is_paused: bool)
signal score_updated(score: int)
signal hit_stop_triggered(duration_ms: float)
signal bullet_cancel_triggered()
signal player_grazed(pos: Vector2)
signal boss_timer_updated(seconds_left: int)
signal formation_completed(formation_type: String)
