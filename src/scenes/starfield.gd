# res://src/scenes/starfield.gd
class_name Starfield
extends Node2D

@export var star_count_layer1: int = 80 # Distant slow stars
@export var star_count_layer2: int = 50 # Mid-speed stars
@export var star_count_layer3: int = 25 # Fast streak stars
@export var warp_multiplier: float = 1.0 # Multiplier for hyperspace jumps

var _stars_layer1: Array[Vector2] = []
var _stars_layer2: Array[Vector2] = []
var _stars_layer3: Array[Vector2] = []

var _speeds := Vector3(60.0, 160.0, 420.0) # Pixels per second

func _ready() -> void:
	var vp_size := get_viewport_rect().size
	if vp_size.x == 0 or vp_size.y == 0:
		vp_size = Vector2(1280, 720)
		
	# Populate random stars across screen
	for i in range(star_count_layer1):
		_stars_layer1.append(Vector2(randf() * vp_size.x, randf() * vp_size.y))
	for i in range(star_count_layer2):
		_stars_layer2.append(Vector2(randf() * vp_size.x, randf() * vp_size.y))
	for i in range(star_count_layer3):
		_stars_layer3.append(Vector2(randf() * vp_size.x, randf() * vp_size.y))

func _process(delta: float) -> void:
	var vp_size := get_viewport_rect().size
	if vp_size.x == 0:
		vp_size.x = 1280.0
	if vp_size.y == 0:
		vp_size.y = 720.0

	var mult := maxf(0.1, warp_multiplier)
	# Layer 1 (Distant)
	for i in range(_stars_layer1.size()):
		_stars_layer1[i].x -= _speeds.x * mult * delta
		if _stars_layer1[i].x < 0:
			_stars_layer1[i].x = vp_size.x
			_stars_layer1[i].y = randf() * vp_size.y

	# Layer 2 (Mid)
	for i in range(_stars_layer2.size()):
		_stars_layer2[i].x -= _speeds.y * mult * delta
		if _stars_layer2[i].x < 0:
			_stars_layer2[i].x = vp_size.x
			_stars_layer2[i].y = randf() * vp_size.y

	# Layer 3 (Foreground fast streaks)
	for i in range(_stars_layer3.size()):
		_stars_layer3[i].x -= _speeds.z * mult * delta
		if _stars_layer3[i].x < 0:
			_stars_layer3[i].x = vp_size.x
			_stars_layer3[i].y = randf() * vp_size.y
			
	queue_redraw()

func _draw() -> void:
	# Subtle grid lines in distant space for sleek vector cyber aesthetic
	var vp_size := get_viewport_rect().size
	var grid_color := Color(0.0, 0.5, 0.8, 0.04)
	for y in range(0, int(vp_size.y), 80):
		draw_line(Vector2(0, y), Vector2(vp_size.x, y), grid_color, 1.0)

	# Distant small dim stars
	for star in _stars_layer1:
		draw_circle(star, 1.2, Color(0.4, 0.6, 0.9, 0.5))

	# Mid-layer brighter cyan stars
	for star in _stars_layer2:
		draw_circle(star, 1.8, Color(0.2, 0.9, 1.0, 0.75))

	# Foreground streak lines (elongates during hyperspace jump)
	var streak_len: float = 14.0 * maxf(1.0, warp_multiplier * 0.7)
	var streak_alpha: float = clampf(0.8 + (warp_multiplier * 0.05), 0.8, 1.0)
	for star in _stars_layer3:
		draw_line(star, star + Vector2(streak_len, 0), Color(0.8, 0.95, 1.0, streak_alpha), 2.0)
