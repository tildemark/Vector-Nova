# res://src/ui/menus/hangar.gd
extends Control

@onready var scrap_balance_label: Label = $Header/ScrapBalanceLabel

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
@onready var launch_btn: Button = $Footer/LaunchButton
@onready var notice_banner: Label = $NoticeBanner

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	
	hull_btn.pressed.connect(func(): _on_upgrade_pressed("hull"))
	firerate_btn.pressed.connect(func(): _on_upgrade_pressed("fire_rate"))
	magnet_btn.pressed.connect(func(): _on_upgrade_pressed("magnet"))
	
	booster_overclock_btn.pressed.connect(func(): _on_booster_pressed("overclock"))
	booster_shield_btn.pressed.connect(func(): _on_booster_pressed("shield"))
	
	ad_button.pressed.connect(_on_watch_ad_pressed)
	iap_button.pressed.connect(_on_iap_pressed)
	launch_btn.pressed.connect(_on_launch_pressed)
	
	GameState.scrap_balance_changed.connect(func(_val): _refresh_ui())
	GameState.upgrades_updated.connect(_refresh_ui)
	
	_refresh_ui()

func _refresh_ui() -> void:
	if scrap_balance_label:
		scrap_balance_label.text = "TOTAL SCRAP: ⬡ %d" % GameState.total_scrap
		
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
	# Mock Rewarded Ad Hook
	ad_button.disabled = true
	_show_notice("SIMULATING REWARDED AD PLAYBACK...")
	await get_tree().create_timer(1.8).timeout
	GameState.total_scrap += 100
	GameState.scrap_balance_changed.emit(GameState.total_scrap)
	GameState.save_data()
	ad_button.disabled = false
	_show_notice("REWARD CLAIMED: +100 SCRAP!")

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

func _on_launch_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main.tscn")

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
