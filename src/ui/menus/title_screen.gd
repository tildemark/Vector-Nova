# res://src/ui/menus/title_screen.gd
extends Control

const WarpScreenScript = preload("res://src/ui/menus/warp_screen.gd")

@onready var starfield: Starfield = $Starfield
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var prompt_label: Label = $PromptLabel
@onready var menu_container: VBoxContainer = $MenuContainer
@onready var launch_btn: Button = $MenuContainer/LaunchButton
@onready var hangar_btn: Button = $MenuContainer/HangarButton
@onready var settings_btn: Button = $MenuContainer/SettingsButton
@onready var scrap_label: Label = $TopHeader/ScrapLabel
@onready var high_score_label: Label = $TopHeader/HighScoreLabel

# Settings Modal
@onready var settings_modal: PanelContainer = $SettingsModal
@onready var sfx_check: CheckBox = $SettingsModal/VBox/SFXRow/SFXCheck
@onready var close_settings_btn: Button = $SettingsModal/VBox/CloseSettingsButton

var _is_menu_active: bool = false
var _prompt_tween: Tween = null

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	AudioManager.play_bgm("title")
	
	if launch_btn:
		launch_btn.pressed.connect(_on_launch_pressed)
	if hangar_btn:
		hangar_btn.pressed.connect(_on_hangar_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if close_settings_btn:
		close_settings_btn.pressed.connect(func(): settings_modal.hide())
		
	# Connect GameState scrap
	if has_node("/root/GameState"):
		scrap_label.text = "SCRAP: ⬡ %d" % GameState.total_scrap
		high_score_label.text = "HIGH SCORE: %d" % GameState.high_score
		
	_start_prompt_pulse()
	
	# Menu container starts hidden until player touches screen
	menu_container.modulate.a = 0.0
	menu_container.hide()

func _input(event: InputEvent) -> void:
	if _is_menu_active:
		return
		
	# Any touch, mouse click, or key press transitions attract mode into active menu
	if (event is InputEventScreenTouch and event.pressed) or \
	   (event is InputEventMouseButton and event.pressed) or \
	   (event is InputEventKey and event.pressed):
		_reveal_menu()

func _start_prompt_pulse() -> void:
	if not prompt_label:
		return
	if _prompt_tween:
		_prompt_tween.kill()
	_prompt_tween = create_tween().set_loops()
	_prompt_tween.tween_property(prompt_label, "modulate:a", 0.2, 0.6)
	_prompt_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.6)

func _reveal_menu() -> void:
	_is_menu_active = true
	if _prompt_tween:
		_prompt_tween.kill()
		
	var tween := create_tween().set_parallel(true)
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(prompt_label.hide)
	
	menu_container.show()
	menu_container.position.y += 20.0
	tween.tween_property(menu_container, "modulate:a", 1.0, 0.35)
	tween.tween_property(menu_container, "position:y", menu_container.position.y - 20.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_launch_pressed() -> void:
	WarpScreenScript.transition_to(get_tree(), "res://src/scenes/main.tscn", "DEPLOYING VANGUARD-01 TO SECTOR 01")

func _on_hangar_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/menus/hangar.tscn")

func _on_settings_pressed() -> void:
	if settings_modal:
		settings_modal.show()
		settings_modal.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(settings_modal, "modulate:a", 1.0, 0.2)
