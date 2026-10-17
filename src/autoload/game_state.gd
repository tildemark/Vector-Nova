# res://src/autoload/game_state.gd
extends Node

signal scrap_balance_changed(new_balance: int)
signal upgrades_updated()
signal ship_selected(ship_id: String)

const SHIPS_ROSTER := {
	"vanguard": {
		"id": "vanguard",
		"name": "VANGUARD-01",
		"role": "STRIKE ALL-ROUNDER",
		"hp": 100,
		"speed_mult": 1.0,
		"primary_type": "TWIN_PLASMA",
		"secondary_type": "SWARM_MISSILES",
		"secondary_name": "SWARM MISSILES",
		"special_name": "EMP SHOCKWAVE",
		"cost": 0,
		"sprite_path": "res://assets/sprites/player/vanguard-01-512.png",
		"color": Color(0.0, 0.95, 1.0),
		"description": "Standard fleet starfighter. Balanced armor, twin plasma cannons, and 8-missile seeker volley."
	},
	"valkyrie": {
		"id": "valkyrie",
		"name": "VALKYRIE-IX",
		"role": "INTERCEPTOR • SPEED & DPS",
		"hp": 75,
		"speed_mult": 1.35,
		"primary_type": "PIERCING_BEAM",
		"secondary_type": "HYPER_BEAM",
		"secondary_name": "PIERCING HYPER-BEAM",
		"special_name": "CHRONO-STASIS",
		"cost": 350,
		"sprite_path": "res://assets/sprites/player/valkyrie-ix-512.png",
		"color": Color(1.0, 0.25, 0.45),
		"description": "High-velocity interceptor. +35% agility, focused laser lance, and continuous 2-second Hyper-Beam."
	},
	"behemoth": {
		"id": "behemoth",
		"name": "BEHEMOTH-V",
		"role": "SIEGE CRUISER • HEAVY TANK",
		"hp": 160,
		"speed_mult": 0.85,
		"primary_type": "QUAD_FLAK",
		"secondary_type": "PULSE_MORTAR",
		"secondary_name": "SIEGE PULSE MORTAR",
		"special_name": "THERMAL DETONATION",
		"cost": 500,
		"sprite_path": "res://assets/sprites/player/behemoth-v-512.png",
		"color": Color(1.0, 0.75, 0.15),
		"description": "Armored dreadnought breaker. +60% Hull HP, quad flak artillery, and high-explosive radial Pulse Mortar."
	},
	"aegis": {
		"id": "aegis",
		"name": "AEGIS PHANTOM",
		"role": "TACTICAL DEFENSE • SUPPORT",
		"hp": 110,
		"speed_mult": 1.05,
		"primary_type": "HELIX_PLASMA",
		"secondary_type": "DEFLECTOR_BARRIER",
		"secondary_name": "KINETIC DEFLECTOR BARRIER",
		"special_name": "OVERDRIVE MATRIX",
		"cost": 650,
		"sprite_path": "res://assets/sprites/player/aegis-phantom-512.png",
		"color": Color(0.2, 0.95, 0.7),
		"description": "Tactical escort fighter. Dual helix plasma and deployable kinetic barrier that absorbs bullets and rams hulls."
	},
	"apex": {
		"id": "apex",
		"name": "APEX CHRONOS",
		"role": "CHAMELEON PROTOTYPE • SUPPORTER",
		"hp": 110,
		"speed_mult": 1.15,
		"primary_type": "HYBRID_CORE",
		"secondary_type": "GRAV_VORTEX",
		"secondary_name": "SINGULARITY VORTEX",
		"special_name": "COSMIC RIFT",
		"scrap_multiplier": 1.30,
		"cost": 850,
		"sprite_path": "res://assets/sprites/player/apex-chronos-512.png",
		"color": Color(0.85, 0.45, 1.0),
		"description": "Chameleon Supporter Prototype. +30% Scrap Salvage, 100% Hull Chrono-Revive, and mirrors any unlocked ship weapon!"
	}
}

const ESCORT_ROSTER := {
	"specter": {
		"id": "specter",
		"name": "SPECTER-D1",
		"role": "RAPID ASSAULT WINGMAN",
		"cost_scrap": 350,
		"cost_cores": 4,
		"fire_delay": 0.22,
		"damage": 10,
		"max_shield": 3,
		"color": Color(0.2, 0.9, 1.0),
		"sprite_path": "res://assets/sprites/player/specter-d1-512.png",
		"description": "High-velocity strike drone. Twin plasma vulcan with high rate-of-fire support."
	},
	"aegis_drone": {
		"id": "aegis_drone",
		"name": "AEGIS-S2",
		"role": "POINT DEFENSE SENTRY",
		"cost_scrap": 550,
		"cost_cores": 6,
		"fire_delay": 0.35,
		"damage": 12,
		"max_shield": 6,
		"color": Color(0.1, 1.0, 0.6),
		"sprite_path": "res://assets/sprites/player/aegis-s2-512.png",
		"description": "Armored defensive drone. Reinforced kinetic absorption shield (6 bullets) and point defense."
	},
	"goliath": {
		"id": "goliath",
		"name": "GOLIATH-B4",
		"role": "SIEGE ARTILLERY",
		"cost_scrap": 750,
		"cost_cores": 8,
		"fire_delay": 0.55,
		"damage": 30,
		"max_shield": 4,
		"color": Color(1.0, 0.65, 0.1),
		"sprite_path": "res://assets/sprites/player/goliath-b4-512.png",
		"description": "Heavy ordnance drone. Launches high-explosive micro-torpedoes that tear through capital armor."
	},
	"chronos_pod": {
		"id": "chronos_pod",
		"name": "CHRONOS-X",
		"role": "TACHYON HARVESTER",
		"cost_scrap": 950,
		"cost_cores": 12,
		"fire_delay": 0.28,
		"damage": 16,
		"max_shield": 5,
		"color": Color(0.85, 0.35, 1.0),
		"sprite_path": "res://assets/sprites/player/chronos-x-512.png",
		"description": "Tachyon support drone. Screen-wide scrap magnetic vacuum and defensive pulse waves."
	}
}

# Persistent state
var total_scrap: int = 150 # Starting allowance for testing
var hyper_cores: int = 0   # Rewarded ad premium currency
var hull_level: int = 0      # 0 to 5 (+25 HP each)
var fire_rate_level: int = 0 # 0 to 5 (-10% delay each)
var magnet_level: int = 0    # 0 to 5 (+45px radius each)

# Ship Roster state
var selected_ship_id: String = "vanguard"
var unlocked_ships: Array = ["vanguard"]
var apex_mirror_ship_id: String = "vanguard" # Ship mirrored when piloting Apex Chronos

# Escort System state
var escort_license_unlocked: bool = false # Base system unlock (500 scrap / 5 cores)
var escort_dual_slot_unlocked: bool = false # Slot 2 unlock (800 scrap / 8 cores)
var unlocked_escorts: Array = []           # e.g. ["specter"]
var escort_slot_1: String = ""              # equipped escort chassis id
var escort_slot_2: String = ""
var escort_placement_mode: String = "orbit" # "flank", "front", "orbit"

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
	# Apex Chronos +30% Scrap Salvage bonus
	if selected_ship_id == "apex":
		final_amount = int(float(final_amount) * 1.30)
		
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

func get_selected_ship() -> Dictionary:
	var ship: Dictionary = SHIPS_ROSTER.get(selected_ship_id, SHIPS_ROSTER["vanguard"]).duplicate()
	if selected_ship_id == "apex":
		# Mirror secondary weapon of selected unlocked ship
		var mirror_target := apex_mirror_ship_id
		if not is_ship_unlocked(mirror_target):
			mirror_target = "vanguard"
		var target_ship: Dictionary = SHIPS_ROSTER.get(mirror_target, SHIPS_ROSTER["vanguard"])
		ship["secondary_type"] = target_ship.get("secondary_type", "GRAV_VORTEX")
		ship["secondary_name"] = "MIMIC // %s" % target_ship.get("secondary_name", "GRAV VORTEX")
		ship["mirrored_from"] = mirror_target
	return ship

func set_apex_mirror_target(target_id: String) -> bool:
	if SHIPS_ROSTER.has(target_id) and is_ship_unlocked(target_id):
		apex_mirror_ship_id = target_id
		save_data()
		return true
	return false

func is_ship_unlocked(ship_id: String) -> bool:
	return unlocked_ships.has(ship_id)

func unlock_ship(ship_id: String) -> bool:
	if not SHIPS_ROSTER.has(ship_id) or is_ship_unlocked(ship_id):
		return false
	var cost: int = SHIPS_ROSTER[ship_id].get("cost", 9999)
	if total_scrap < cost:
		return false
	total_scrap -= cost
	unlocked_ships.append(ship_id)
	scrap_balance_changed.emit(total_scrap)
	save_data()
	return true

func select_ship(ship_id: String) -> bool:
	if is_ship_unlocked(ship_id):
		selected_ship_id = ship_id
		ship_selected.emit(ship_id)
		save_data()
		return true
	return false

func is_escort_unlocked(escort_id: String) -> bool:
	return unlocked_escorts.has(escort_id)

func unlock_escort_license(use_cores: bool = false) -> bool:
	if escort_license_unlocked:
		return false
	if use_cores:
		if hyper_cores < 5: return false
		hyper_cores -= 5
	else:
		if total_scrap < 500: return false
		total_scrap -= 500
		scrap_balance_changed.emit(total_scrap)
	escort_license_unlocked = true
	save_data()
	return true

func unlock_dual_slot(use_cores: bool = false) -> bool:
	if not escort_license_unlocked or escort_dual_slot_unlocked:
		return false
	if use_cores:
		if hyper_cores < 8: return false
		hyper_cores -= 8
	else:
		if total_scrap < 800: return false
		total_scrap -= 800
		scrap_balance_changed.emit(total_scrap)
	escort_dual_slot_unlocked = true
	save_data()
	return true

func unlock_escort(escort_id: String, use_cores: bool = false) -> bool:
	if not escort_license_unlocked or not ESCORT_ROSTER.has(escort_id) or is_escort_unlocked(escort_id):
		return false
	var data: Dictionary = ESCORT_ROSTER[escort_id]
	if use_cores:
		var cost_cores: int = data.get("cost_cores", 999)
		if hyper_cores < cost_cores: return false
		hyper_cores -= cost_cores
	else:
		var cost_scrap: int = data.get("cost_scrap", 9999)
		if total_scrap < cost_scrap: return false
		total_scrap -= cost_scrap
		scrap_balance_changed.emit(total_scrap)
		
	unlocked_escorts.append(escort_id)
	if escort_slot_1 == "":
		escort_slot_1 = escort_id
	save_data()
	return true

func equip_escort(slot: int, escort_id: String) -> void:
	if slot == 1:
		escort_slot_1 = escort_id
	elif slot == 2 and escort_dual_slot_unlocked:
		escort_slot_2 = escort_id
	save_data()

func set_escort_placement(mode: String) -> void:
	if mode in ["flank", "front", "orbit"]:
		escort_placement_mode = mode
		save_data()

func add_hyper_cores(amount: int) -> void:
	hyper_cores += amount
	save_data()

func save_data() -> void:
	var dict := {
		"total_scrap": total_scrap,
		"hyper_cores": hyper_cores,
		"hull_level": hull_level,
		"fire_rate_level": fire_rate_level,
		"magnet_level": magnet_level,
		"high_score": high_score,
		"runs_played": runs_played,
		"is_ad_free": is_ad_free,
		"selected_ship_id": selected_ship_id,
		"unlocked_ships": unlocked_ships,
		"escort_license_unlocked": escort_license_unlocked,
		"escort_dual_slot_unlocked": escort_dual_slot_unlocked,
		"unlocked_escorts": unlocked_escorts,
		"escort_slot_1": escort_slot_1,
		"escort_slot_2": escort_slot_2,
		"escort_placement_mode": escort_placement_mode,
		"apex_mirror_ship_id": apex_mirror_ship_id
	}
	SaveManager.save_game(dict)

func load_data() -> void:
	var dict := SaveManager.load_game()
	if dict.is_empty():
		return
	total_scrap = int(dict.get("total_scrap", 150))
	hyper_cores = int(dict.get("hyper_cores", 0))
	hull_level = int(dict.get("hull_level", 0))
	fire_rate_level = int(dict.get("fire_rate_level", 0))
	magnet_level = int(dict.get("magnet_level", 0))
	high_score = int(dict.get("high_score", 0))
	runs_played = int(dict.get("runs_played", 0))
	is_ad_free = bool(dict.get("is_ad_free", false))
	selected_ship_id = String(dict.get("selected_ship_id", "vanguard"))
	var loaded_ships = dict.get("unlocked_ships", ["vanguard"])
	if loaded_ships is Array:
		unlocked_ships.clear()
		for s in loaded_ships:
			unlocked_ships.append(str(s))
			
	escort_license_unlocked = bool(dict.get("escort_license_unlocked", false))
	escort_dual_slot_unlocked = bool(dict.get("escort_dual_slot_unlocked", false))
	var loaded_escorts = dict.get("unlocked_escorts", [])
	if loaded_escorts is Array:
		unlocked_escorts.clear()
		for e in loaded_escorts:
			unlocked_escorts.append(str(e))
	escort_slot_1 = String(dict.get("escort_slot_1", ""))
	escort_slot_2 = String(dict.get("escort_slot_2", ""))
	escort_placement_mode = String(dict.get("escort_placement_mode", "orbit"))
	apex_mirror_ship_id = String(dict.get("apex_mirror_ship_id", "vanguard"))
