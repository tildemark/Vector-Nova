# res://src/scenes/main.gd
extends Node2D

@onready var player: Player = $Player
@onready var player_bullet_pool: ObjectPool = $PlayerBulletPool
@onready var enemy_bullet_pool: ObjectPool = $EnemyBulletPool
@onready var spawner_manager: Node2D = $SpawnerManager
@onready var camera: Camera2D = $Camera2D

# UI references
@onready var fps_label: Label = $UI/HUD/TopBar/FPSLabel
@onready var scrap_label: Label = $UI/HUD/TopBar/ScrapContainer/ScrapLabel
@onready var hp_bar: ProgressBar = $UI/HUD/TopBar/HPContainer/HPBar
@onready var weapon_label: Label = $UI/HUD/TopBar/WeaponContainer/WeaponLabel
@onready var wave_banner: Label = $UI/HUD/WaveBanner
@onready var touch_hint: Label = $UI/HUD/CenterHint
@onready var hangar_btn: Button = $UI/HUD/TopBar/HangarButton
@onready var settings_btn: Button = $UI/HUD/TopBar/SettingsButton
@onready var settings_modal: PanelContainer = $UI/HUD/SettingsModal
@onready var sfx_check: CheckBox = $UI/HUD/SettingsModal/VBox/SFXRow/SFXCheck
@onready var sfx_slider: HSlider = $UI/HUD/SettingsModal/VBox/SFXVolRow/SFXSlider
@onready var bgm_check: CheckBox = $UI/HUD/SettingsModal/VBox/BGMRow/BGMCheck
@onready var bgm_slider: HSlider = $UI/HUD/SettingsModal/VBox/BGMVolRow/BGMSlider
@onready var close_settings_btn: Button = $UI/HUD/SettingsModal/VBox/CloseSettingsButton

# EMP Special Button references
@onready var emp_button: Button = $UI/HUD/EMPContainer/EMPButton
@onready var emp_charge_bar: TextureProgressBar = $UI/HUD/EMPContainer/EMPChargeBar
@onready var emp_status_label: Label = $UI/HUD/EMPContainer/EMPStatusLabel

# Secondary Tactical Weapon references
@onready var sec_button: Button = $UI/HUD/SecondaryContainer/SecondaryButton
@onready var sec_gauge_bar: TextureProgressBar = $UI/HUD/SecondaryContainer/SecondaryGaugeBar
@onready var sec_status_label: Label = $UI/HUD/SecondaryContainer/SecondaryStatusLabel

# Boss HUD references
@onready var boss_container: VBoxContainer = $UI/HUD/BossContainer
@onready var boss_name_label: Label = $UI/HUD/BossContainer/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $UI/HUD/BossContainer/BossHPBar
@onready var boss_timer_label: Label = $UI/HUD/BossContainer/BossTimerLabel
@onready var top_wing_hp_bar: ProgressBar = $UI/HUD/BossContainer/WeakpointBarsRow/TopWingBox/TopWingHPBar
@onready var top_turret_hp_bar: ProgressBar = $UI/HUD/BossContainer/WeakpointBarsRow/TurretTopBox/TopTurretHPBar
@onready var bottom_turret_hp_bar: ProgressBar = $UI/HUD/BossContainer/WeakpointBarsRow/TurretBotBox/BottomTurretHPBar
@onready var bottom_wing_hp_bar: ProgressBar = $UI/HUD/BossContainer/WeakpointBarsRow/BottomWingBox/BottomWingHPBar
@onready var score_label: Label = $UI/HUD/TopBar/ScoreContainer/ScoreLabel

var _total_scrap: int = 0
var _current_score: int = 0
var _extend_thresholds: Array[int] = [10000, 25000, 50000, 100000]
var _claimed_extends: Array[int] = []
var _hit_stop_active: bool = false
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _camera_origin: Vector2 = Vector2.ZERO
var _hint_timer: float = 4.0

var _emp_charge: float = 50.0 # 0.0 to 100.0
var _emp_ready: bool = false
var _emp_pulse_tween: Tween = null

var _sec_energy: float = 0.0
var _sec_max_energy: float = 100.0

func _ready() -> void:
	# Enforce landscape horizontal orientation for mobile devices
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	
	if camera:
		_camera_origin = camera.position
		
	AudioManager.play_bgm("stage1")
		
	if player and player_bullet_pool:
		player.player_bullet_pool = player_bullet_pool
		
	if spawner_manager and enemy_bullet_pool:
		spawner_manager.enemy_bullet_pool = enemy_bullet_pool
		
	_spawn_active_escorts()
		
	if emp_button:
		emp_button.pressed.connect(_on_emp_button_pressed)
		
	if sec_button:
		sec_button.pressed.connect(_on_secondary_button_pressed)
		
	if hangar_btn:
		hangar_btn.pressed.connect(func():
			GameState.finalize_run(false)
			get_tree().change_scene_to_file("res://src/ui/menus/hangar.tscn")
		)
		
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_button_pressed)
		
	if close_settings_btn:
		close_settings_btn.pressed.connect(_on_close_settings_pressed)
		
	_setup_settings_modal()
		
	# Connect to EventBus signals
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.scrap_collected.connect(_on_scrap_collected)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.weapon_upgraded.connect(_on_weapon_upgraded)
	EventBus.special_gauge_changed.connect(_on_special_gauge_changed)
	EventBus.secondary_energy_changed.connect(_on_secondary_energy_changed)
	EventBus.secondary_weapon_fired.connect(_on_secondary_weapon_fired)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_updated.connect(_on_boss_health_updated)
	EventBus.boss_weakpoint_health_updated.connect(_on_boss_weakpoint_health_updated)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.hit_stop_triggered.connect(_on_hit_stop)
	EventBus.bullet_cancel_triggered.connect(_on_bullet_cancel)
	EventBus.player_grazed.connect(_on_player_grazed)
	EventBus.boss_timer_updated.connect(_on_boss_timer_updated)
	EventBus.formation_completed.connect(_on_formation_completed)
	
	_update_emp_ui()
	_update_sec_ui()
	_update_score_ui()

func _process(delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
		
	# Passive slow EMP charge (+2.5% per second)
	if not _emp_ready:
		_add_emp_charge(2.5 * delta)
		
	# Touch hint fade out
	if touch_hint and touch_hint.visible:
		_hint_timer -= delta
		if _hint_timer <= 0:
			var tween := create_tween()
			tween.tween_property(touch_hint, "modulate:a", 0.0, 1.0)
			tween.tween_callback(func(): touch_hint.hide())
			
	# Camera screen shake decay
	if _shake_timer > 0.0 and camera:
		_shake_timer -= delta
		var offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		camera.position = _camera_origin + offset
	elif camera and camera.position != _camera_origin:
		camera.position = _camera_origin

func shake_camera(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_timer = duration

func _add_emp_charge(amount: float) -> void:
	_emp_charge = clampf(_emp_charge + amount, 0.0, 100.0)
	var now_ready := _emp_charge >= 100.0
	if now_ready != _emp_ready:
		_emp_ready = now_ready
		_on_emp_state_changed()
	_update_emp_ui()

func _on_emp_state_changed() -> void:
	if _emp_ready:
		if _emp_pulse_tween:
			_emp_pulse_tween.kill()
		_emp_pulse_tween = create_tween().set_loops()
		_emp_pulse_tween.tween_property(emp_button, "modulate", Color(1.8, 1.8, 1.0, 1.0), 0.4)
		_emp_pulse_tween.tween_property(emp_button, "modulate", Color.WHITE, 0.4)
		if emp_status_label:
			emp_status_label.text = "EMP // READY"
			emp_status_label.modulate = Color(0.0, 1.0, 1.0)
	else:
		if _emp_pulse_tween:
			_emp_pulse_tween.kill()
		emp_button.modulate = Color.WHITE
		if emp_status_label:
			emp_status_label.modulate = Color(0.7, 0.8, 0.9)

func _update_emp_ui() -> void:
	if emp_charge_bar:
		emp_charge_bar.value = _emp_charge
	if emp_status_label and not _emp_ready:
		emp_status_label.text = "EMP: %d%%" % int(_emp_charge)

func _on_secondary_button_pressed() -> void:
	if player and is_instance_valid(player):
		player.fire_secondary_weapon()

func _on_secondary_energy_changed(curr: float, max_val: float) -> void:
	_sec_energy = curr
	_sec_max_energy = max_val
	_update_sec_ui()

func _update_sec_ui() -> void:
	if sec_gauge_bar:
		sec_gauge_bar.max_value = _sec_max_energy
		sec_gauge_bar.value = _sec_energy
	if sec_status_label:
		sec_status_label.text = "SEC: %d%%" % int((_sec_energy / maxf(1.0, _sec_max_energy)) * 100.0)
	if sec_button:
		var can_fire := _sec_energy >= 10.0
		sec_button.modulate = Color(1.2, 1.2, 1.2, 1.0) if can_fire else Color(0.6, 0.6, 0.6, 0.6)

func _on_secondary_weapon_fired(weapon_type: String) -> void:
	match weapon_type:
		"SWARM_MISSILES":
			shake_camera(7.0, 0.2)
		"HYPER_BEAM":
			shake_camera(6.0, 0.35)
		"PULSE_MORTAR":
			shake_camera(14.0, 0.35)
		"DEFLECTOR_BARRIER":
			shake_camera(4.0, 0.15)
		_:
			shake_camera(7.0, 0.2)
			
	if sec_button:
		var tween := create_tween()
		sec_button.scale = Vector2(0.88, 0.88)
		tween.tween_property(sec_button, "scale", Vector2.ONE, 0.15)

func _spawn_active_escorts() -> void:
	if not GameState.escort_license_unlocked:
		return
	var escort_scene: PackedScene = load("res://src/entities/player/escort_drone.tscn")
	if not escort_scene:
		return
		
	# Slot 1 Escort
	if GameState.escort_slot_1 != "":
		var d1 := escort_scene.instantiate() as EscortDrone
		d1.escort_id = GameState.escort_slot_1
		d1.slot_index = 1
		d1.player_node = player
		d1.player_bullet_pool = player_bullet_pool
		add_child(d1)
		
	# Slot 2 Escort (if unlocked)
	if GameState.escort_dual_slot_unlocked and GameState.escort_slot_2 != "":
		var d2 := escort_scene.instantiate() as EscortDrone
		d2.escort_id = GameState.escort_slot_2
		d2.slot_index = 2
		d2.player_node = player
		d2.player_bullet_pool = player_bullet_pool
		add_child(d2)

func _on_emp_button_pressed() -> void:
	if not _emp_ready or not player or not is_instance_valid(player):
		return
		
	# Fire screen-clearing EMP
	_emp_charge = 0.0
	_emp_ready = false
	_on_emp_state_changed()
	_update_emp_ui()
	
	player.trigger_emp()
	shake_camera(18.0, 0.45)
	
	# EMP announcement popup
	if wave_banner:
		wave_banner.text = "⚡ EMP DETONATED ⚡"
		wave_banner.show()
		wave_banner.modulate = Color(0.0, 2.0, 2.0, 1.0)
		var t := create_tween()
		t.tween_property(wave_banner, "modulate:a", 0.0, 0.8)
		t.tween_callback(wave_banner.hide)

func _on_player_damaged(current_hp: int, max_hp: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	shake_camera(8.0, 0.25)

func _on_player_died() -> void:
	shake_camera(14.0, 0.5)
	if _current_score > GameState.high_score:
		GameState.high_score = _current_score
		GameState.save_data()
	var earned := GameState.finalize_run(false)
	if touch_hint:
		touch_hint.text = "SHIP DESTROYED // RECOVERED ⬡ %d SCRAP\nRETURNING TO HANGAR..." % earned
		touch_hint.show()
		touch_hint.modulate.a = 1.0
	await get_tree().create_timer(2.2).timeout
	get_tree().change_scene_to_file("res://src/ui/menus/hangar.tscn")

func _on_scrap_collected(amount: int) -> void:
	_total_scrap += amount
	_add_score(amount * 20)
	if scrap_label:
		scrap_label.text = "⬡ %d" % _total_scrap
		var tween := create_tween()
		scrap_label.scale = Vector2(1.2, 1.2)
		tween.tween_property(scrap_label, "scale", Vector2.ONE, 0.15)

func _on_enemy_destroyed(type: String, _pos: Vector2, _val: int) -> void:
	shake_camera(3.0, 0.1)
	_add_emp_charge(10.0) # +10% charge per kill
	var lower_type := type.to_lower()
	var pts := 120
	if "heavy" in lower_type or "elite" in lower_type:
		pts = 1200
	elif "interceptor" in lower_type:
		pts = 300
	elif "boss" in lower_type or "core" in lower_type:
		pts = 5000
	_add_score(pts)

func _on_hit_stop(duration_ms: float) -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.05
	var timer := get_tree().create_timer(duration_ms / 1000.0, true, false, true)
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
		_hit_stop_active = false
	)

func _on_bullet_cancel() -> void:
	if enemy_bullet_pool:
		var cancelled := enemy_bullet_pool.cancel_bullets_to_scrap()
		if cancelled > 0:
			shake_camera(6.0, 0.2)
			_add_score(cancelled * 50)

func _on_player_grazed(pos: Vector2) -> void:
	_add_score(150)
	var label := Label.new()
	label.text = "GRAZE +150"
	label.modulate = Color(0.2, 1.0, 1.0, 0.95)
	label.scale = Vector2(0.75, 0.75)
	label.position = pos + Vector2(randf_range(-12, 12), -20)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 25.0, 0.4)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)

func _on_boss_timer_updated(seconds_left: int) -> void:
	if not boss_timer_label:
		return
	if seconds_left <= 0:
		boss_timer_label.text = "⚠️ FLAGSHIP CORE OVERCHARGED / ENRAGED ⚠️"
		boss_timer_label.modulate = Color(2.5, 0.3, 0.3, 1.0)
	else:
		boss_timer_label.text = "COMBAT ESCAPE / ENRAGE: %02ds" % seconds_left
		if seconds_left <= 15:
			boss_timer_label.modulate = Color(2.5, 0.4, 0.4, 1.0)
		else:
			boss_timer_label.modulate = Color(1.0, 0.85, 0.3, 1.0)

func _on_formation_completed(formation_type: String) -> void:
	_add_score(1500)
	if wave_banner:
		wave_banner.text = "★ %s DESTROYED // POWER-UP DROP ★" % formation_type.replace("_", " ")
		wave_banner.show()
		wave_banner.modulate = Color(2.5, 1.8, 0.3, 1.0)
		var t := create_tween()
		t.tween_interval(1.2)
		t.tween_property(wave_banner, "modulate:a", 0.0, 0.4)
		t.tween_callback(wave_banner.hide)

func _add_score(amount: int) -> void:
	_current_score += amount
	EventBus.score_updated.emit(_current_score)
	_update_score_ui()
	_check_extends()

func _update_score_ui() -> void:
	if score_label:
		score_label.text = "%06d" % _current_score

func _check_extends() -> void:
	for threshold in _extend_thresholds:
		if _current_score >= threshold and not _claimed_extends.has(threshold):
			_claimed_extends.append(threshold)
			_trigger_extend(threshold)

func _trigger_extend(threshold: int) -> void:
	_total_scrap += 50
	GameState.add_run_scrap(50)
	_add_emp_charge(100.0)
	if scrap_label:
		scrap_label.text = "⬡ %d" % _total_scrap
	if wave_banner:
		wave_banner.text = "★ EXTEND BONUS UNLOCKED (%d PTS) // +50 SCRAP & EMP MAX ★" % threshold
		wave_banner.show()
		wave_banner.modulate = Color(0.2, 2.5, 1.2, 1.0)
		var t := create_tween()
		t.tween_interval(1.8)
		t.tween_property(wave_banner, "modulate:a", 0.0, 0.4)
		t.tween_callback(wave_banner.hide)

func _on_weapon_upgraded(tier: int) -> void:
	if weapon_label:
		var bars := ""
		for i in range(4):
			bars += "■" if i < tier else "□"
		weapon_label.text = "TIER %d [%s]" % [tier, bars]
		weapon_label.modulate = Color(2.0, 1.8, 0.5) # Flash golden
		var tween := create_tween()
		tween.tween_property(weapon_label, "modulate", Color(1.0, 0.85, 0.3), 0.5)
		
	shake_camera(5.0, 0.2)
	
	# Banner notification
	if wave_banner:
		wave_banner.text = "★ WEAPON TIER %d UNLOCKED ★" % tier
		wave_banner.show()
		wave_banner.modulate = Color(2.0, 1.8, 0.5, 1.0)
		var t := create_tween()
		t.tween_interval(0.8)
		t.tween_property(wave_banner, "modulate:a", 0.0, 0.4)
		t.tween_callback(wave_banner.hide)

func _on_special_gauge_changed(ratio: float) -> void:
	_emp_charge = clampf(ratio * 100.0, 0.0, 100.0)
	var now_ready := _emp_charge >= 100.0
	if now_ready != _emp_ready:
		_emp_ready = now_ready
		_on_emp_state_changed()
	_update_emp_ui()

func _on_wave_started(wave_num: int) -> void:
	if not wave_banner:
		return
	wave_banner.text = "// WAVE %d : INCOMING //" % wave_num
	wave_banner.show()
	wave_banner.modulate = Color.WHITE
	wave_banner.scale = Vector2(0.8, 0.8)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(wave_banner, "modulate:a", 1.0, 0.3)
	tween.tween_property(wave_banner, "scale", Vector2.ONE, 0.3)
	tween.chain().tween_interval(1.2)
	tween.chain().tween_property(wave_banner, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(wave_banner.hide)

func _on_boss_spawned(boss_name: String, max_hp: int) -> void:
	if boss_name_label:
		boss_name_label.text = "⚠️ %s // FLAGSHIP CORE ⚠️" % boss_name.to_upper()
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = max_hp
	if boss_container:
		boss_container.show()
		boss_container.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(boss_container, "modulate:a", 1.0, 0.6)
		
	if wave_banner:
		wave_banner.text = "⚠️ WARNING: CAPITAL CLASS DETECTED ⚠️"
		wave_banner.show()
		wave_banner.modulate = Color(2.5, 0.5, 0.5, 1.0)
		var t := create_tween()
		t.tween_interval(1.5)
		t.tween_property(wave_banner, "modulate:a", 0.0, 0.4)
		t.tween_callback(wave_banner.hide)
		
	shake_camera(12.0, 0.6)

func _on_boss_health_updated(current_hp: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.value = current_hp

func _on_boss_weakpoint_health_updated(id_name: String, current_hp: int, max_hp: int) -> void:
	match id_name:
		"TopWing":
			if top_wing_hp_bar:
				top_wing_hp_bar.max_value = max_hp
				top_wing_hp_bar.value = current_hp
		"BottomWing":
			if bottom_wing_hp_bar:
				bottom_wing_hp_bar.max_value = max_hp
				bottom_wing_hp_bar.value = current_hp
		"TopTurret":
			if top_turret_hp_bar:
				top_turret_hp_bar.max_value = max_hp
				top_turret_hp_bar.value = current_hp
		"BottomTurret":
			if bottom_turret_hp_bar:
				bottom_turret_hp_bar.max_value = max_hp
				bottom_turret_hp_bar.value = current_hp

func _on_boss_defeated() -> void:
	shake_camera(20.0, 1.2)
	_add_score(8000)
	if _current_score > GameState.high_score:
		GameState.high_score = _current_score
		GameState.save_data()
	if boss_container:
		var t := create_tween()
		t.tween_property(boss_container, "modulate:a", 0.0, 0.8)
		t.tween_callback(boss_container.hide)
		
	if wave_banner:
		wave_banner.text = "★ DREADNOUGHT DESTROYED // SECTOR LIBERATED ★"
		wave_banner.show()
		wave_banner.modulate = Color(1.0, 2.5, 1.0, 1.0)
		var t := create_tween()
		t.tween_interval(3.0)
		t.tween_property(wave_banner, "modulate:a", 0.0, 0.6)
		t.tween_callback(func():
			var earned := GameState.finalize_run(true)
			if touch_hint:
				touch_hint.text = "VICTORY! REWARD: ⬡ %d SCRAP\nRETURNING TO HANGAR..." % earned
				touch_hint.show()
				touch_hint.modulate.a = 1.0
			await get_tree().create_timer(2.5).timeout
			get_tree().change_scene_to_file("res://src/ui/menus/hangar.tscn")
		)

func _setup_settings_modal() -> void:
	if not has_node("/root/GameState"):
		return
	if sfx_check:
		sfx_check.button_pressed = GameState.sfx_enabled
		sfx_check.toggled.connect(func(pressed: bool):
			AudioManager.set_sfx_enabled(pressed)
			if pressed:
				AudioManager.play_sfx("laser", false)
		)
	if sfx_slider:
		sfx_slider.value = GameState.sfx_volume
		sfx_slider.value_changed.connect(func(val: float):
			AudioManager.set_sfx_volume(val)
		)
	if bgm_check:
		bgm_check.button_pressed = GameState.bgm_enabled
		bgm_check.toggled.connect(func(pressed: bool):
			AudioManager.set_bgm_enabled(pressed)
		)
	if bgm_slider:
		bgm_slider.value = GameState.bgm_volume
		bgm_slider.value_changed.connect(func(val: float):
			AudioManager.set_bgm_volume(val)
		)

func _on_settings_button_pressed() -> void:
	if settings_modal:
		get_tree().paused = true
		settings_modal.show()

func _on_close_settings_pressed() -> void:
	if settings_modal:
		settings_modal.hide()
		get_tree().paused = false
