# res://src/scenes/main.gd
extends Node2D

@onready var player: Player = $Player
@onready var player_bullet_pool: ObjectPool = $PlayerBulletPool
@onready var enemy_bullet_pool: ObjectPool = $EnemyBulletPool
@onready var spawner_manager: SpawnerManager = $SpawnerManager
@onready var camera: Camera2D = $Camera2D

# UI references
@onready var fps_label: Label = $UI/HUD/TopBar/FPSLabel
@onready var scrap_label: Label = $UI/HUD/TopBar/ScrapContainer/ScrapLabel
@onready var hp_bar: ProgressBar = $UI/HUD/TopBar/HPContainer/HPBar
@onready var weapon_label: Label = $UI/HUD/TopBar/WeaponContainer/WeaponLabel
@onready var wave_banner: Label = $UI/HUD/WaveBanner
@onready var touch_hint: Label = $UI/HUD/CenterHint
@onready var hangar_btn: Button = $UI/HUD/TopBar/HangarButton

# EMP Special Button references
@onready var emp_button: Button = $UI/HUD/EMPContainer/EMPButton
@onready var emp_charge_bar: ProgressBar = $UI/HUD/EMPContainer/EMPChargeBar
@onready var emp_status_label: Label = $UI/HUD/EMPContainer/EMPStatusLabel

# Boss HUD references
@onready var boss_container: VBoxContainer = $UI/HUD/BossContainer
@onready var boss_name_label: Label = $UI/HUD/BossContainer/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $UI/HUD/BossContainer/BossHPBar

var _total_scrap: int = 0
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _camera_origin: Vector2 = Vector2.ZERO
var _hint_timer: float = 4.0

var _emp_charge: float = 50.0 # 0.0 to 100.0
var _emp_ready: bool = false
var _emp_pulse_tween: Tween = null

func _ready() -> void:
	# Enforce landscape horizontal orientation for mobile devices
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	
	if camera:
		_camera_origin = camera.position
		
	if player and player_bullet_pool:
		player.player_bullet_pool = player_bullet_pool
		
	if spawner_manager and enemy_bullet_pool:
		spawner_manager.enemy_bullet_pool = enemy_bullet_pool
		
	if emp_button:
		emp_button.pressed.connect(_on_emp_button_pressed)
		
	if hangar_btn:
		hangar_btn.pressed.connect(func():
			GameState.finalize_run(false)
			get_tree().change_scene_to_file("res://src/ui/menus/hangar.tscn")
		)
		
	# Connect to EventBus signals
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.scrap_collected.connect(_on_scrap_collected)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.weapon_upgraded.connect(_on_weapon_upgraded)
	EventBus.special_gauge_changed.connect(_on_special_gauge_changed)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_updated.connect(_on_boss_health_updated)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	
	_update_emp_ui()

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
	var earned := GameState.finalize_run(false)
	if touch_hint:
		touch_hint.text = "SHIP DESTROYED // RECOVERED ⬡ %d SCRAP\nRETURNING TO HANGAR..." % earned
		touch_hint.show()
		touch_hint.modulate.a = 1.0
	await get_tree().create_timer(2.2).timeout
	get_tree().change_scene_to_file("res://src/ui/menus/hangar.tscn")

func _on_scrap_collected(amount: int) -> void:
	_total_scrap += amount
	if scrap_label:
		scrap_label.text = "⬡ %d" % _total_scrap
		var tween := create_tween()
		scrap_label.scale = Vector2(1.2, 1.2)
		tween.tween_property(scrap_label, "scale", Vector2.ONE, 0.15)

func _on_enemy_destroyed(_type: String, _pos: Vector2, _val: int) -> void:
	shake_camera(3.0, 0.1)
	_add_emp_charge(10.0) # +10% charge per kill

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

func _on_boss_defeated() -> void:
	shake_camera(20.0, 1.2)
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
