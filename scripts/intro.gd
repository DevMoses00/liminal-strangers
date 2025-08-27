extends Node2D

@export var left_character : AnimatedSprite2D
@export var right_character : AnimatedSprite2D
@export var left_arrow : AnimatedSprite2D
@export var right_arrow : AnimatedSprite2D
@export var changing_panel : Node2D
var turn = "left"  # Start with left character's turn
var step_size := 52  # Distance to move per input
var max_steps := 20
var left_steps := 0
var right_steps := 0

var intro = true

var sequence_on = true
var local_string

enum GamePhase { INTRO_LEFT, INTRO_RIGHT, TURN_BASED }
var phase = GamePhase.INTRO_LEFT
var input_enabled := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_bgs("RoomTone")
	fade_tween_in($FixedPanel/TOP)
	# Turn everything off
	_update_arrows()
	await get_tree().create_timer(3).timeout
	#SoundManager.play_bgs("Nature")
	fade_tween_in($Logo)
	await get_tree().create_timer(4).timeout
	fade_tween_out($Logo)
	await get_tree().create_timer(2).timeout
	fade_tween_in(left_character)
	SoundManager.play_sfx("Elevator")
	await get_tree().create_timer(4).timeout
	# fade in arrow keys circle
	fade_tween_in($FixedPanel/Circles/Bottom)
	await get_tree().create_timer(2).timeout
	input_enabled = true

# MOVEMENT LOGIC
func _unhandled_input(event):
	if not input_enabled:
		return
	
	if event is InputEventKey and event.pressed:
		match phase:
			GamePhase.INTRO_LEFT:
				if event.is_action_pressed("char_left_move"):
					await get_tree().create_timer(0.1).timeout
					input_enabled = false
					var sfx = ["Step1","Step2","Step3","Step4","Step5"].pick_random()
					SoundManager.play_sfx(sfx)
					rotate_arrows()
					left_character.position.x += step_size
					left_steps += 1
					await get_tree().create_timer(0.4).timeout
					input_enabled = true
					if left_steps >= max_steps:  # Adjust for screen layout
						input_enabled = false
						_reset_arrows()
						fade_tween_out(left_character)
						SoundManager.play_sfx("DoorClose")
						await get_tree().create_timer(4).timeout
						fade_tween_in(right_character)
						SoundManager.play_sfx("DoorOpen")
						await get_tree().create_timer(2).timeout
						reset_intro()
						phase = GamePhase.INTRO_RIGHT
						turn = "right"
						_update_arrows()
						await get_tree().create_timer(0.4).timeout
						input_enabled = true
						print("Now try moving the Right Character!")
			GamePhase.INTRO_RIGHT:
				if event.is_action_pressed("char_right_move"):
					await get_tree().create_timer(0.1).timeout
					input_enabled = false
					var sfx = ["Step1","Step2","Step3","Step4","Step5"].pick_random()
					SoundManager.play_sfx(sfx)
					rotate_arrows()
					right_character.position.x -= step_size
					right_steps += 1
					await get_tree().create_timer(0.4).timeout
					input_enabled = true
					if right_steps >= max_steps:
						input_enabled = false
						_reset_arrows()
						fade_tween_out(right_character)
						SoundManager.play_sfx("Elevator")
						await get_tree().create_timer(2).timeout
						reset_intro()
						await get_tree().create_timer(2).timeout
						fade_tween_in(left_character)
						SoundManager.play_sfx("Elevator")
						await get_tree().create_timer(4).timeout
						fade_tween_in(right_character)
						SoundManager.play_sfx("DoorOpen")
						await get_tree().create_timer(2).timeout
						phase = GamePhase.TURN_BASED
						turn = "left"
						_update_arrows()
						await get_tree().create_timer(1).timeout
						input_enabled = true
						print("Now take turns with both characters.")
			GamePhase.TURN_BASED:
				match turn:
					"left":
						if event.is_action_pressed("char_left_move") and left_steps < max_steps:
							await get_tree().create_timer(0.1)
							input_enabled = false 
							var sfx = ["Step1","Step2","Step3","Step4","Step5"].pick_random()
							SoundManager.play_sfx(sfx)
							left_character.position.x += step_size
							left_steps += 1
							rotate_arrows()
							turn = "right"
							_update_arrows()
							await get_tree().create_timer(0.4).timeout
							input_enabled = true
							
					"right":
						if event.is_action_pressed("char_right_move") and right_steps < max_steps:
							await get_tree().create_timer(0.1)
							input_enabled = false
							var sfx = ["Step1","Step2","Step3","Step4","Step5"].pick_random()
							SoundManager.play_sfx(sfx)
							right_character.position.x -= step_size
							right_steps += 1
							rotate_arrows()
							turn = "left"
							_update_arrows()
							await get_tree().create_timer(0.4).timeout
							input_enabled = true

				if abs(left_steps - right_steps) > 1:
					turn = "right" if left_steps < right_steps else "left"
					_update_arrows()

				if left_character.position.x >= right_character.position.x:
					if intro == true:
						_on_characters_cross()
						intro = false
				
				if left_steps >= max_steps:
					fade_tween_out(left_character)
				
				if right_steps >= max_steps:
					fade_tween_out(right_character)

func rotate_arrows():
	var active_rot = 180
	var inactive_rot = 0
	var tween := create_tween()
	
	if turn == "right":
		tween.tween_property(right_arrow, "rotation_degrees", active_rot, 0.2)
		tween.tween_interval(0.2)
		tween.tween_property(right_arrow, "rotation_degrees", inactive_rot, 0.2)
	else:
		tween.tween_property(left_arrow, "rotation_degrees", active_rot, 0.2)
		tween.tween_interval(0.2)
		tween.tween_property(left_arrow, "rotation_degrees", inactive_rot, 0.2)


func reset_intro():
	left_character.position.x = -521
	right_character.position.x = 511
	left_steps = 0
	right_steps = 0

func _update_arrows():
	var active_scale = Vector2(1.1, 1.1)
	var inactive_scale = Vector2(0.9, 0.9)

	var tween := create_tween()

	if turn == "left":
		tween.tween_property(left_arrow, "scale", active_scale, 0.2)
		tween.tween_property(right_arrow, "scale", inactive_scale, 0.2)
	else:
		tween.tween_property(left_arrow, "scale", inactive_scale, 0.2)
		tween.tween_property(right_arrow, "scale", active_scale, 0.2)

func _on_characters_cross():
	# HIDE EVERYTHING
	SoundManager.stop_all()
	SoundManager.play_sfx("Hide")
	$FixedPanel/TOP.hide()
	$FixedPanel/TOP.position = Vector2.ZERO
	$FixedPanel/Circles/Bottom.hide()
	#SoundManager.play_sfx("Title")
	input_enabled = false
	await get_tree().create_timer(2).timeout
	# SHOW TITLE
	fade_tween_in($Title)
	await get_tree().create_timer(2).timeout
	SoundManager.play_bgm("Red")
	await get_tree().create_timer(3).timeout
	fade_tween_out($Title)
	await get_tree().create_timer(5).timeout
	print("Characters crossed!")
	# going to the next scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	return



# HELPER FUNCTIONS
func fade_tween_in(image) -> void:
	var fadeTween = get_tree().create_tween()
	fadeTween.tween_property(image,"modulate",Color(1.0, 1.0, 1.0, 1.0), 2)

func fade_tween_out(image) -> void:
	var fadeTween = get_tree().create_tween()
	fadeTween.tween_property(image,"modulate",Color(1.0, 1.0, 1.0, 0.0), 2)

func _reset_arrows():
	left_arrow.scale = Vector2(0.8, 0.8)
	right_arrow.scale = Vector2(0.8, 0.8)
