extends Node2D

# --- Tunables ---
@export var chaos_duration: float = 6.0
@export var chaos_interval: float = 0.08
@export var char_speed: float = .5     # player move speed (px/s)
@export var box_speed: float = 140.0
@export var world_min_x: float = 0.0
@export var world_max_x: float = 1280.0
@export var meet_threshold_px: float = 12.0

# Slow-mo burst when they meet
@export var slowmo_scale: float = 0.3
@export var slowmo_in_time: float = 0.15
@export var slowmo_hold: float = 0.35
@export var slowmo_out_time: float = 0.25

const ANIMS := ["red", "blue", "green"]

@export var left_char : AnimatedSprite2D
@export var right_char : AnimatedSprite2D
@onready var left_area  : Area2D = left_char.get_node("Area2D") if left_char else null
@onready var right_area : Area2D = right_char.get_node("Area2D") if right_char else null

var _center_x := 0.0
var _chaos_running := false
var _time := 0.0
var _met_fired := false

signal characters_met

func _ready() -> void:
	SoundManager.play_sfx("Hide")
	_center_x = get_viewport_rect().size.x * 0.5

	# Area2D meet detection signals
	if left_area:
		left_area.area_entered.connect(_on_left_area_entered)
	if right_area:
		right_area.area_entered.connect(_on_right_area_entered)

	start_chaos()

func start_chaos() -> void:
	if _chaos_running: return
	_chaos_running = true
	_time = 0.0
	_met_fired = false
	_randomize_loop()

func stop_chaos() -> void:
	_chaos_running = false

func _physics_process(delta: float) -> void:
	if not _chaos_running:
		return

	_time += delta

	# --- PLAYER INPUT MOVEMENT ---
	# Left character: hold left action to move RIGHT toward center, clamp at center
	if left_char:
		if Input.is_action_pressed("char_left_move"):
			left_char.global_position.x += char_speed

	# Right character: hold right action to move LEFT toward center, clamp at center
	if right_char:
		if Input.is_action_pressed("char_right_move"):
			right_char.global_position.x -= char_speed

	# --- BOXES DRIFT AWAY FROM CENTER (still chaos) ---
	for n in get_tree().get_nodes_in_group("chaos_boxes"):
		if n is AnimatedSprite2D:
			var dir := -1.0 if n.global_position.x < _center_x else 1.0

# --- Rapid randomize animations while chaos is running ---
func _randomize_loop() -> void:
	for n in get_tree().get_nodes_in_group("chaos_chars"):
		if n is AnimatedSprite2D:
			n.play(ANIMS.pick_random())
	for n in get_tree().get_nodes_in_group("chaos_boxes"):
		if n is AnimatedSprite2D:
			n.play(ANIMS.pick_random())

	if _chaos_running and not _met_fired:
		await get_tree().create_timer(chaos_interval).timeout
		_randomize_loop()

# --- Meet detection via Areas ---
func _on_left_area_entered(other: Area2D) -> void:
	if not _chaos_running or _met_fired: return
	if other == right_area:
		_on_characters_met()

func _on_right_area_entered(other: Area2D) -> void:
	if not _chaos_running or _met_fired: return
	if other == left_area:
		_on_characters_met()

func _on_characters_met() -> void:
	stop_chaos()
	SoundManager.play_sfx("Hide")
	print("working")
	SoundManager.stop_all()
	self.hide()
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://scenes/last_note.tscn")
	# Do something here
	pass
