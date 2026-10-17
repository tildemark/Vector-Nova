# res://src/ui/menus/hangar.gd
extends Control

@onready var scrap_balance_label: Label = $Header/ScrapBalanceLabel
@onready var core_balance_label: Label = $Header/CoreBalanceLabel

# Escort Drone Bay UI references
@onready var license_status_label: Label = $ScrollContainer/Content/EscortBayCard/VBox/LicenseRow/LicenseStatusLabel
@onready var unlock_license_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/LicenseRow/UnlockLicenseButton
@onready var unlock_dual_slot_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/LicenseRow/UnlockDualSlotButton

@onready var orbit_mode_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/PlacementRow/OrbitModeBtn
@onready var flank_mode_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/PlacementRow/FlankModeBtn
@onready var front_mode_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/PlacementRow/FrontModeBtn

@onready var drone_texture_rect: TextureRect = $ScrollContainer/Content/EscortBayCard/VBox/DroneCarouselRow/DronePreviewBox/DroneTexture
@onready var drone_name_label: Label = $ScrollContainer/Content/EscortBayCard/VBox/DroneCarouselRow/DronePreviewBox/DroneNameLabel
@onready var drone_role_label: Label = $ScrollContainer/Content/EscortBayCard/VBox/DroneCarouselRow/DronePreviewBox/DroneRoleLabel
@onready var prev_drone_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/DroneCarouselRow/PrevDroneBtn
@onready var next_drone_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/DroneCarouselRow/NextDroneBtn

@onready var drone_desc_label: Label = $ScrollContainer/Content/EscortBayCard/VBox/DroneDescLabel
@onready var equip_slot1_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/DroneActionRow/EquipSlot1Btn
@onready var equip_slot2_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/DroneActionRow/EquipSlot2Btn
@onready var unlock_drone_btn: Button = $ScrollContainer/Content/EscortBayCard/VBox/DroneActionRow/UnlockDroneBtn

var _drone_ids: Array[String] = ["specter", "aegis_drone", "goliath", "chronos_pod"]
var _current_drone_index: int = 0

# Upgrade buttons & labels
@onready var hull_tier_label: Label = $ScrollContainer/Content/UpgradesCard/HullRow/HullInfo/HullTierLabel
@onready var hull_btn: Button = $ScrollContainer/Content/UpgradesCard/HullRow/HullButton

@onready var firerate_tier_label: Label = $ScrollContainer/Content/UpgradesCard/FireRateRow/FireRateInfo/FireRateTierLabel
@onready var firerate_btn: Button = $ScrollContainer/Content/UpgradesCard/FireRateRow/FireRateButton

@onready var magnet_tier_label: Label = $ScrollContainer/Content/UpgradesCard/MagnetRow/MagnetInfo/MagnetTierLabel
@onready var magnet_btn: Button = $ScrollContainer/Content/UpgradesCard/MagnetRow/MagnetButton

# Boosters
@onready var booster_overclock_btn: Button = $ScrollContainer/Content/BoostersCard/BoosterRow/OverclockButton
@onready var booster_shield_btn: Button = $ScrollContainer/Content/BoostersCard/BoosterRow/ShieldButton

# Monetization Mock Hooks
@onready var ad_button: Button = $ScrollContainer/Content/MonetizationCard/AdRow/AdButton
@onready var iap_button: Button = $ScrollContainer/Content/MonetizationCard/AdRow/IAPButton

# Action
@onready var back_btn: Button = $Header/BackButton
@onready var launch_btn: Button = $Footer/LaunchButton
@onready var notice_banner: Label = $NoticeBanner

# Ship Roster Carousel references
@onready var ship_texture_rect: TextureRect = $ScrollContainer/Content/ShipRosterCard/VBox/CarouselRow/ShipPreviewBox/ShipTexture
@onready var ship_name_label: Label = $ScrollContainer/Content/ShipRosterCard/VBox/CarouselRow/ShipPreviewBox/ShipNameLabel
@onready var ship_role_label: Label = $ScrollContainer/Content/ShipRosterCard/VBox/CarouselRow/ShipPreviewBox/ShipRoleLabel
@onready var prev_ship_btn: Button = $ScrollContainer/Content/ShipRosterCard/VBox/CarouselRow/PrevShipButton
@onready var next_ship_btn: Button = $ScrollContainer/Content/ShipRosterCard/VBox/CarouselRow/NextShipButton
@onready var ship_hp_val: Label = $ScrollContainer/Content/ShipRosterCard/VBox/StatsGrid/HPStat/HPValue
@onready var ship_speed_val: Label = $ScrollContainer/Content/ShipRosterCard/VBox/StatsGrid/SpeedStat/SpeedValue
@onready var ship_weapon_val: Label = $ScrollContainer/Content/ShipRosterCard/VBox/StatsGrid/WeaponStat/WeaponValue
@onready var ship_desc_label: Label = $ScrollContainer/Content/ShipRosterCard/VBox/ShipDescLabel
@onready var mimic_row: HBoxContainer = $ScrollContainer/Content/ShipRosterCard/VBox/MimicSelectorRow
@onready var mimic_btn: Button = $ScrollContainer/Content/ShipRosterCard/VBox/MimicSelectorRow/MimicTargetBtn
@onready var ship_action_btn: Button = $ScrollContainer/Content/ShipRosterCard/VBox/ShipActionButton

var _ship_ids: Array[String] = ["vanguard", "valkyrie", "behemoth", "aegis", "apex"]
var _current_preview_index: int = 0

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_bgm("title")
	
	hull_btn.pressed.connect(func(): _on_upgrade_pressed("hull"))
	firerate_btn.pressed.connect(func(): _on_upgrade_pressed("fire_rate"))
	magnet_btn.pressed.connect(func(): _on_upgrade_pressed("magnet"))
	
	booster_overclock_btn.pressed.connect(func(): _on_booster_pressed("overclock"))
	booster_shield_btn.pressed.connect(func(): _on_booster_pressed("shield"))
	
	ad_button.pressed.connect(_on_watch_ad_pressed)
	iap_button.pressed.connect(_on_iap_pressed)
	launch_btn.pressed.connect(_on_launch_pressed)
	if back_btn:
		back_btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://src/ui/menus/title_screen.tscn")
		)
		
	# Initialize ship carousel index to currently active ship
	var cur_id := GameState.selected_ship_id
	var idx := _ship_ids.find(cur_id)
	_current_preview_index = idx if idx != -1 else 0
	
	if prev_ship_btn:
		prev_ship_btn.pressed.connect(func(): _cycle_ship(-1))
	if next_ship_btn:
		next_ship_btn.pressed.connect(func(): _cycle_ship(1))
	if ship_action_btn:
		ship_action_btn.pressed.connect(_on_ship_action_pressed)
	if mimic_btn:
		mimic_btn.pressed.connect(_on_cycle_mimic_target_pressed)
		
	# Escort Bay UI buttons
	if unlock_license_btn:
		unlock_license_btn.pressed.connect(_on_unlock_escort_license_pressed)
	if unlock_dual_slot_btn:
		unlock_dual_slot_btn.pressed.connect(_on_unlock_dual_slot_pressed)
	if orbit_mode_btn:
		orbit_mode_btn.pressed.connect(func(): _on_placement_selected("orbit"))
	if flank_mode_btn:
		flank_mode_btn.pressed.connect(func(): _on_placement_selected("flank"))
	if front_mode_btn:
		front_mode_btn.pressed.connect(func(): _on_placement_selected("front"))
	if prev_drone_btn:
		prev_drone_btn.pressed.connect(func(): _cycle_drone(-1))
	if next_drone_btn:
		next_drone_btn.pressed.connect(func(): _cycle_drone(1))
	if equip_slot1_btn:
		equip_slot1_btn.pressed.connect(func(): _on_equip_escort_slot(1))
	if equip_slot2_btn:
		equip_slot2_btn.pressed.connect(func(): _on_equip_escort_slot(2))
	if unlock_drone_btn:
		unlock_drone_btn.pressed.connect(_on_unlock_drone_pressed)
	
	GameState.scrap_balance_changed.connect(func(_val): _refresh_ui())
	GameState.upgrades_updated.connect(_refresh_ui)
	
	_refresh_ui()

func _refresh_ui() -> void:
	if scrap_balance_label:
		scrap_balance_label.text = "TOTAL SCRAP: ⬡ %d" % GameState.total_scrap
	if core_balance_label:
		core_balance_label.text = "HYPER-CORES: ⬢ %d" % GameState.hyper_cores
		
	_update_ship_preview()
	_update_escort_preview()
		
	# Hull
	if hull_tier_label:
		hull_tier_label.text = "TIER %d/5 (+%d HP)" % [GameState.hull_level, GameState.hull_level * 25]
		if GameState.hull_level >= 5:
			hull_btn.text = "MAXED"
			hull_btn.disabled = true
		else:
			hull_btn.text = "UPGRADE [%d ⬡]" % GameState.get_upgrade_cost("hull")
			hull_btn.disabled = GameState.total_scrap < GameState.get_upgrade_cost("hull")
			
	# Fire Rate
	if firerate_tier_label:
		firerate_tier_label.text = "TIER %d/5 (-%d%% Delay)" % [GameState.fire_rate_level, GameState.fire_rate_level * 10]
		if GameState.fire_rate_level >= 5:
			firerate_btn.text = "MAXED"
			firerate_btn.disabled = true
		else:
			firerate_btn.text = "UPGRADE [%d ⬡]" % GameState.get_upgrade_cost("fire_rate")
			firerate_btn.disabled = GameState.total_scrap < GameState.get_upgrade_cost("fire_rate")

	# Magnet
	if magnet_tier_label:
		magnet_tier_label.text = "TIER %d/5 (+%dpx Range)" % [GameState.magnet_level, int(GameState.magnet_level * 45)]
		if GameState.magnet_level >= 5:
			magnet_btn.text = "MAXED"
			magnet_btn.disabled = true
		else:
			magnet_btn.text = "UPGRADE [%d ⬡]" % GameState.get_upgrade_cost("magnet")
			magnet_btn.disabled = GameState.total_scrap < GameState.get_upgrade_cost("magnet")

	# Boosters
	if booster_overclock_btn:
		if GameState.booster_overclock:
			booster_overclock_btn.text = "OVERCLOCK: [EQUIPPED]"
			booster_overclock_btn.modulate = Color(1.0, 2.0, 1.0)
		else:
			booster_overclock_btn.text = "OVERCLOCK [40 ⬡]"
			booster_overclock_btn.modulate = Color.WHITE

	if booster_shield_btn:
		if GameState.booster_shield:
			booster_shield_btn.text = "SHIELD: [EQUIPPED]"
			booster_shield_btn.modulate = Color(1.0, 2.0, 1.0)
		else:
			booster_shield_btn.text = "SHIELD [40 ⬡]"
			booster_shield_btn.modulate = Color.WHITE

func _on_upgrade_pressed(type: String) -> void:
	if GameState.purchase_upgrade(type):
		_show_notice("TECH UPGRADE ACQUIRED!")
	else:
		_show_notice("INSUFFICIENT SCRAP!")

func _on_booster_pressed(type: String) -> void:
	if GameState.toggle_booster(type):
		_show_notice("BOOSTER LOADOUT UPDATED")
	else:
		_show_notice("INSUFFICIENT SCRAP!")

func _on_watch_ad_pressed() -> void:
	# Rewarded Ad Hook: Awards Hyper-Cores and Scrap
	ad_button.disabled = true
	_show_notice("SIMULATING REWARDED INTEL BRIEFING...")
	await get_tree().create_timer(1.8).timeout
	GameState.total_scrap += 75
	GameState.add_hyper_cores(1)
	GameState.scrap_balance_changed.emit(GameState.total_scrap)
	ad_button.disabled = false
	_show_notice("REWARD CLAIMED: +1 HYPER-CORE ⬢ & +75 SCRAP!")

func _on_iap_pressed() -> void:
	# Mock IAP Pilot Pack Hook
	iap_button.disabled = true
	_show_notice("CONTACTING APP STORE / GOOGLE PLAY...")
	await get_tree().create_timer(1.5).timeout
	GameState.total_scrap += 500
	GameState.is_ad_free = true
	GameState.scrap_balance_changed.emit(GameState.total_scrap)
	GameState.save_data()
	iap_button.text = "PURCHASED [AD-FREE ACTIVE]"
	_show_notice("STARTER PACK UNLOCKED: +500 SCRAP & AD-FREE!")

const WarpScreenScript = preload("res://src/ui/menus/warp_screen.gd")

func _cycle_ship(dir: int) -> void:
	_current_preview_index = (_current_preview_index + dir) % _ship_ids.size()
	if _current_preview_index < 0:
		_current_preview_index += _ship_ids.size()
	_update_ship_preview()

func _update_ship_preview() -> void:
	if _ship_ids.is_empty() or not has_node("/root/GameState"):
		return
		
	var ship_id: String = _ship_ids[_current_preview_index]
	var ship: Dictionary = GameState.SHIPS_ROSTER.get(ship_id, {})
	if ship.is_empty():
		return
		
	# Name & Role styling
	if ship_name_label:
		ship_name_label.text = str(ship.get("name", "UNKNOWN"))
		ship_name_label.modulate = ship.get("color", Color.WHITE)
	if ship_role_label:
		ship_role_label.text = "// %s //" % str(ship.get("role", ""))
		
	# Sprite Preview
	if ship_texture_rect:
		var path: String = str(ship.get("sprite_path", ""))
		if ResourceLoader.exists(path):
			ship_texture_rect.texture = load(path)
			
	# Stat Readouts
	if ship_hp_val:
		ship_hp_val.text = "%d HP" % int(ship.get("hp", 100))
	if ship_speed_val:
		ship_speed_val.text = "%.2fx" % float(ship.get("speed_mult", 1.0))
	if ship_weapon_val:
		ship_weapon_val.text = str(ship.get("secondary_name", "SWARM MISSILES"))
	if ship_desc_label:
		ship_desc_label.text = str(ship.get("description", ""))
		
	# Action Button state
	var is_unlocked: bool = GameState.is_ship_unlocked(ship_id)
	var is_equipped: bool = GameState.selected_ship_id == ship_id
	
	# Apex Holographic Mimic Target Selector
	if mimic_row:
		if ship_id == "apex" and is_unlocked:
			mimic_row.show()
			var target_id := GameState.apex_mirror_ship_id
			var target_name: String = GameState.SHIPS_ROSTER.get(target_id, {}).get("name", "VANGUARD-01")
			var target_sec: String = GameState.SHIPS_ROSTER.get(target_id, {}).get("secondary_name", "SWARM MISSILES")
			mimic_btn.text = "MIRROR WEAPON: %s (%s)" % [target_name, target_sec]
			if ship_weapon_val:
				ship_weapon_val.text = "MIMIC // %s" % target_sec
		else:
			mimic_row.hide()
	
	if is_equipped:
		ship_action_btn.text = "EQUIPPED [ACTIVE CHASSIS]"
		ship_action_btn.disabled = true
		ship_action_btn.modulate = Color(0.2, 1.0, 0.6)
	elif is_unlocked:
		ship_action_btn.text = "EQUIP THIS CHASSIS"
		ship_action_btn.disabled = false
		ship_action_btn.modulate = Color(0.0, 0.95, 1.0)
	else:
		var cost: int = int(ship.get("cost", 9999))
		ship_action_btn.text = "UNLOCK [%d ⬡]" % cost
		ship_action_btn.disabled = GameState.total_scrap < cost
		ship_action_btn.modulate = Color(1.0, 0.85, 0.3) if GameState.total_scrap >= cost else Color(0.6, 0.6, 0.6)

func _on_cycle_mimic_target_pressed() -> void:
	# Available ships to mirror (must be unlocked other ships)
	var eligible: Array[String] = []
	for sid in GameState.SHIPS_ROSTER.keys():
		if sid != "apex" and GameState.is_ship_unlocked(sid):
			eligible.append(sid)
	if eligible.is_empty():
		eligible.append("vanguard")
		
	var cur_idx := eligible.find(GameState.apex_mirror_ship_id)
	var next_idx := (cur_idx + 1) % eligible.size() if cur_idx != -1 else 0
	var next_target := eligible[next_idx]
	GameState.set_apex_mirror_target(next_target)
	_show_notice("APEX MIMIC CALIBRATED: %s" % GameState.SHIPS_ROSTER[next_target]["name"])
	_refresh_ui()

func _on_ship_action_pressed() -> void:
	var ship_id: String = _ship_ids[_current_preview_index]
	var is_unlocked: bool = GameState.is_ship_unlocked(ship_id)
	
	if is_unlocked:
		GameState.select_ship(ship_id)
		_show_notice("CHASSIS EQUIPPED: %s" % GameState.SHIPS_ROSTER[ship_id]["name"])
	else:
		if GameState.unlock_ship(ship_id):
			GameState.select_ship(ship_id)
			_show_notice("CHASSIS UNLOCKED & EQUIPPED!")
		else:
			_show_notice("INSUFFICIENT SCRAP!")
			
	_refresh_ui()

func _on_launch_pressed() -> void:
	WarpScreenScript.transition_to(get_tree(), "res://src/scenes/main.tscn", "LAUNCHING FROM FLEET HANGAR")

func _cycle_drone(dir: int) -> void:
	_current_drone_index = (_current_drone_index + dir) % _drone_ids.size()
	if _current_drone_index < 0:
		_current_drone_index += _drone_ids.size()
	_update_escort_preview()

func _update_escort_preview() -> void:
	if _drone_ids.is_empty() or not has_node("/root/GameState"):
		return
		
	var drone_id: String = _drone_ids[_current_drone_index]
	var drone: Dictionary = GameState.ESCORT_ROSTER.get(drone_id, {})
	if drone.is_empty():
		return
		
	# License status
	if license_status_label:
		if GameState.escort_license_unlocked:
			license_status_label.text = "BAY STATUS: ONLINE // SLOTS: %s" % ("2 DUAL WINGMEN" if GameState.escort_dual_slot_unlocked else "1 SINGLE WINGMAN")
			license_status_label.modulate = Color(0.2, 1.0, 0.6)
		else:
			license_status_label.text = "BAY STATUS: OFFLINE // LICENSE REQUIRED"
			license_status_label.modulate = Color(1.0, 0.4, 0.4)
			
	if unlock_license_btn:
		unlock_license_btn.visible = not GameState.escort_license_unlocked
	if unlock_dual_slot_btn:
		unlock_dual_slot_btn.visible = GameState.escort_license_unlocked and not GameState.escort_dual_slot_unlocked
		
	# Placement buttons highlight
	var cur_mode: String = GameState.escort_placement_mode
	if orbit_mode_btn:
		orbit_mode_btn.modulate = Color(0.2, 1.0, 0.6) if cur_mode == "orbit" else Color.WHITE
	if flank_mode_btn:
		flank_mode_btn.modulate = Color(0.2, 1.0, 0.6) if cur_mode == "flank" else Color.WHITE
	if front_mode_btn:
		front_mode_btn.modulate = Color(0.2, 1.0, 0.6) if cur_mode == "front" else Color.WHITE
		
	# Drone info & preview
	if drone_name_label:
		drone_name_label.text = str(drone.get("name", ""))
		drone_name_label.modulate = drone.get("color", Color.WHITE)
	if drone_role_label:
		drone_role_label.text = "// %s //" % str(drone.get("role", ""))
	if drone_texture_rect:
		var path: String = str(drone.get("sprite_path", ""))
		if ResourceLoader.exists(path):
			drone_texture_rect.texture = load(path)
	if drone_desc_label:
		drone_desc_label.text = "%s [ABSORBS %d BULLETS]" % [str(drone.get("description", "")), int(drone.get("max_shield", 3))]
		
	# Unlocked & Equipped states
	var is_unlocked: bool = GameState.is_escort_unlocked(drone_id)
	var in_slot1: bool = GameState.escort_slot_1 == drone_id
	var in_slot2: bool = GameState.escort_slot_2 == drone_id
	
	if equip_slot1_btn:
		equip_slot1_btn.visible = GameState.escort_license_unlocked and is_unlocked
		equip_slot1_btn.text = "SLOT 1: EQUIPPED" if in_slot1 else "EQUIP IN SLOT 1"
		equip_slot1_btn.disabled = in_slot1
		equip_slot1_btn.modulate = Color(0.2, 1.0, 0.6) if in_slot1 else Color.WHITE
		
	if equip_slot2_btn:
		equip_slot2_btn.visible = GameState.escort_dual_slot_unlocked and is_unlocked
		equip_slot2_btn.text = "SLOT 2: EQUIPPED" if in_slot2 else "EQUIP IN SLOT 2"
		equip_slot2_btn.disabled = in_slot2
		equip_slot2_btn.modulate = Color(0.2, 1.0, 0.6) if in_slot2 else Color.WHITE
		
	if unlock_drone_btn:
		unlock_drone_btn.visible = GameState.escort_license_unlocked and not is_unlocked
		var c_scrap: int = int(drone.get("cost_scrap", 999))
		var c_cores: int = int(drone.get("cost_cores", 99))
		unlock_drone_btn.text = "UNLOCK [%d ⬡ / %d ⬢]" % [c_scrap, c_cores]
		var can_afford := GameState.total_scrap >= c_scrap or GameState.hyper_cores >= c_cores
		unlock_drone_btn.disabled = not can_afford

func _on_unlock_escort_license_pressed() -> void:
	if GameState.hyper_cores >= 5:
		if GameState.unlock_escort_license(true):
			_show_notice("ESCORT BAY LICENSE UNLOCKED WITH HYPER-CORES!")
	elif GameState.total_scrap >= 500:
		if GameState.unlock_escort_license(false):
			_show_notice("ESCORT BAY LICENSE UNLOCKED WITH SCRAP!")
	else:
		_show_notice("NEED 500 ⬡ SCRAP OR 5 ⬢ HYPER-CORES!")
	_refresh_ui()

func _on_unlock_dual_slot_pressed() -> void:
	if GameState.hyper_cores >= 8:
		if GameState.unlock_dual_slot(true):
			_show_notice("DUAL WINGMAN LICENSE UNLOCKED WITH HYPER-CORES!")
	elif GameState.total_scrap >= 800:
		if GameState.unlock_dual_slot(false):
			_show_notice("DUAL WINGMAN LICENSE UNLOCKED WITH SCRAP!")
	else:
		_show_notice("NEED 800 ⬡ SCRAP OR 8 ⬢ HYPER-CORES!")
	_refresh_ui()

func _on_placement_selected(mode: String) -> void:
	GameState.set_escort_placement(mode)
	_show_notice("FORMATION SET: %s" % mode.to_upper())
	_refresh_ui()

func _on_equip_escort_slot(slot: int) -> void:
	var drone_id: String = _drone_ids[_current_drone_index]
	GameState.equip_escort(slot, drone_id)
	_show_notice("ESCORT %s EQUIPPED IN SLOT %d" % [GameState.ESCORT_ROSTER[drone_id]["name"], slot])
	_refresh_ui()

func _on_unlock_drone_pressed() -> void:
	var drone_id: String = _drone_ids[_current_drone_index]
	var data: Dictionary = GameState.ESCORT_ROSTER[drone_id]
	var c_scrap: int = int(data.get("cost_scrap", 999))
	var c_cores: int = int(data.get("cost_cores", 99))
	
	if GameState.hyper_cores >= c_cores:
		if GameState.unlock_escort(drone_id, true):
			_show_notice("ESCORT UNLOCKED WITH HYPER-CORES!")
	elif GameState.total_scrap >= c_scrap:
		if GameState.unlock_escort(drone_id, false):
			_show_notice("ESCORT UNLOCKED WITH SCRAP!")
	else:
		_show_notice("INSUFFICIENT SCRAP OR HYPER-CORES!")
	_refresh_ui()

func _show_notice(text: String) -> void:
	if not notice_banner:
		return
	notice_banner.text = text
	notice_banner.show()
	notice_banner.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.2)
	t.tween_property(notice_banner, "modulate:a", 0.0, 0.4)
	t.tween_callback(notice_banner.hide)
