# res://src/ui/menus/warp_screen.gd
class_name WarpScreen
extends Control

@export var target_scene: String = "res://src/scenes/main.tscn"
@export var dispatch_title: String = "DEPLOYING TO COMBAT SECTOR 01"

@onready var starfield: Starfield = $Starfield
@onready var mission_label: Label = $CenterContainer/VBoxContainer/MissionLabel
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var warp_progress_bar: ProgressBar = $CenterContainer/VBoxContainer/WarpProgressBar
@onready var flash_overlay: ColorRect = $FlashOverlay

static var next_target_scene: String = "res://src/scenes/main.tscn"
static var next_dispatch_title: String = "DEPLOYING TO COMBAT SECTOR 01"

static func transition_to(tree: SceneTree, p_target: String, p_title: String = "DEPLOYING TO COMBAT SECTOR 01") -> void:
	next_target_scene = p_target
	next_dispatch_title = p_title
	tree.change_scene_to_file("res://src/ui/menus/warp_screen.tscn")

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	target_scene = next_target_scene
	dispatch_title = next_dispatch_title
	
	if mission_label:
		mission_label.text = "// %s //" % dispatch_title.to_upper()
		
	if flash_overlay:
		flash_overlay.color = Color.TRANSPARENT
		flash_overlay.show()
		
	_start_warp_sequence()

func _start_warp_sequence() -> void:
	if starfield:
		starfield.warp_multiplier = 1.0
		
	var tween := create_tween()
	
	# Step 1: Ramp warp multiplier & progress bar
	tween.tween_property(starfield, "warp_multiplier", 12.0, 1.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(warp_progress_bar, "value", 100.0, 1.4)
	
	# Step 2: Update status text stages
	tween.parallel().tween_callback(func():
		status_label.text = "CALIBRATING WARP DRIVE..."
	)
	tween.parallel().tween_interval(0.4)
	tween.chain().tween_callback(func():
		status_label.text = "WARP TUNNEL ENGAGED • VELOCITY 8.4c"
		status_label.modulate = Color(0.2, 0.9, 1.0)
	)
	tween.chain().tween_interval(0.5)
	tween.chain().tween_callback(func():
		status_label.text = "ARRIVING AT HOSTILE DESTINATION..."
		status_label.modulate = Color(1.0, 0.8, 0.2)
	)
	
	# Step 3: Flash white exit surge
	tween.chain().tween_interval(0.3)
	tween.chain().tween_property(flash_overlay, "color", Color.WHITE, 0.15)
	
	# Step 4: Scene switch
	tween.chain().tween_callback(func():
		get_tree().change_scene_to_file(target_scene)
	)
