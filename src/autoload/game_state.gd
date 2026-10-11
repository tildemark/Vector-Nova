# res://src/autoload/game_state.gd
extends Node

signal scrap_balance_changed(new_balance: int)
signal upgrades_updated()

# Persistent state
var total_scrap: int = 150 # Starting allowance for testing
var hull_level: int = 0      # 0 to 5 (+25 HP each)
var fire_rate_level: int = 0 # 0 to 5 (-10% delay each)
var magnet_level: int = 0    # 0 to 5 (+45px radius each)

# Pre-run Boosters
var booster_overclock: bool = false # Start at weapon tier 2
var booster_shield: bool = false    # Start with +40 bonus shield

# Stats & Monetization flags
var high_score: int = 0
var runs_played: int = 0
var is_ad_free: bool = false

# Active Run Temp Data
var run_scrap_earned: int = 0
var run_enemies_killed: int = 0

func _ready() -> void:
	load_data()

func get_bonus_hp() -> int:
	var hp := hull_level * 25
	if booster_shield:
		hp += 40
	return hp

func get_fire_rate_delay() -> float:
	return maxf(0.06, 0.12 - (fire_rate_level * 0.012))

func get_magnet_radius() -> float:
	return 200.0 + (magnet_level * 45.0)

func get_starting_weapon_level() -> int:
	return 2 if booster_overclock else 1

func get_upgrade_cost(type: String) -> int:
	match type:
		"hull":
			return (hull_level + 1) * 60
		"fire_rate":
			return (fire_rate_level + 1) * 75
		"magnet":
			return (magnet_level + 1) * 45
		_:
			return 999

func purchase_upgrade(type: String) -> bool:
	var cost := get_upgrade_cost(type)
	if total_scrap < cost:
		return false
		
	match type:
		"hull":
			if hull_level >= 5: return false
			hull_level += 1
		"fire_rate":
			if fire_rate_level >= 5: return false
			fire_rate_level += 1
		"magnet":
			if magnet_level >= 5: return false
			magnet_level += 1
		_:
			return false
			
	total_scrap -= cost
	scrap_balance_changed.emit(total_scrap)
	upgrades_updated.emit()
	save_data()
	return true

func toggle_booster(type: String) -> bool:
	var cost := 40
	match type:
		"overclock":
			if not booster_overclock and total_scrap >= cost:
				total_scrap -= cost
				booster_overclock = true
			elif booster_overclock:
				total_scrap += cost # Refund
				booster_overclock = false
			else:
				return false
		"shield":
			if not booster_shield and total_scrap >= cost:
				total_scrap -= cost
				booster_shield = true
			elif booster_shield:
				total_scrap += cost # Refund
				booster_shield = false
			else:
				return false
				
	scrap_balance_changed.emit(total_scrap)
	upgrades_updated.emit()
	save_data()
	return true

func add_run_scrap(amount: int) -> void:
	run_scrap_earned += amount

func finalize_run(double_reward: bool = false) -> int:
	var final_amount := run_scrap_earned * 2 if double_reward else run_scrap_earned
	total_scrap += final_amount
	runs_played += 1
	scrap_balance_changed.emit(total_scrap)
	
	# Clear consumed one-time boosters
	booster_overclock = false
	booster_shield = false
	
	save_data()
	var earned := final_amount
	run_scrap_earned = 0
	run_enemies_killed = 0
	return earned

func save_data() -> void:
	var dict := {
		"total_scrap": total_scrap,
		"hull_level": hull_level,
		"fire_rate_level": fire_rate_level,
		"magnet_level": magnet_level,
		"high_score": high_score,
		"runs_played": runs_played,
		"is_ad_free": is_ad_free
	}
	SaveManager.save_game(dict)

func load_data() -> void:
	var dict := SaveManager.load_game()
	if dict.is_empty():
		return
	total_scrap = int(dict.get("total_scrap", 150))
	hull_level = int(dict.get("hull_level", 0))
	fire_rate_level = int(dict.get("fire_rate_level", 0))
	magnet_level = int(dict.get("magnet_level", 0))
	high_score = int(dict.get("high_score", 0))
	runs_played = int(dict.get("runs_played", 0))
	is_ad_free = bool(dict.get("is_ad_free", false))
