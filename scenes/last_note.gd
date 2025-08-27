extends Node2D

@export var left_character : AnimatedSprite2D
@export var right_character : AnimatedSprite2D
@export var left_arrow : AnimatedSprite2D
@export var right_arrow : AnimatedSprite2D
@export var changing_panel : Node2D

enum GamePhase { INTRO_LEFT, INTRO_RIGHT, TURN_BASED }
var phase = GamePhase.TURN_BASED
var input_enabled := true

var turn = "left"  # Start with left character's turn
var step_size := 52  # Distance to move per input
var max_steps := 9
var left_steps := 0
var right_steps := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_bgm("RoomTone")
	await get_tree().create_timer(2).timeout
	fade_tween_in(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event):
	if not input_enabled:
		return
	
	if event is InputEventKey and event.pressed:
		match phase:
			GamePhase.TURN_BASED:
				match turn:
					"left":
						if event.is_action_pressed("char_left_move") and left_steps < max_steps:
							input_enabled = false 
							var sfx = ["Step1","Step2","Step3","Step4","Step5"].pick_random()
							SoundManager.play_sfx(sfx,0,10)
							left_character.position.x += step_size
							left_steps += 1
							turn = "right"
							await get_tree().create_timer(0.3).timeout
							input_enabled = true
							
					"right":
						if event.is_action_pressed("char_right_move") and right_steps < max_steps:
							input_enabled = false
							var sfx = ["Step1","Step2","Step3","Step4","Step5"].pick_random()
							SoundManager.play_sfx(sfx,0,10)
							right_character.position.x -= step_size
							right_steps += 1
							turn = "left"
							await get_tree().create_timer(0.3).timeout
							input_enabled = true

				if abs(left_steps - right_steps) > 1:
					turn = "right" if left_steps < right_steps else "left"
				
				if left_steps >= max_steps:
					fade_tween_out(left_character)
					SoundManager.play_sfx("DoorClose")
				if right_steps >= max_steps:
					fade_tween_out(right_character)
					SoundManager.play_sfx("Elevator")
				if left_steps >= max_steps and right_steps >= max_steps: 
					input_enabled = false
					await get_tree().create_timer(3).timeout
					fade_tween_out(self)
					await get_tree().create_timer(4).timeout
					SoundManager.stop_all()
					await get_tree().create_timer(1).timeout
					get_tree().change_scene_to_file("res://scenes/intro.tscn")

func fade_tween_in(image) -> void:
	var fadeTween = get_tree().create_tween()
	fadeTween.tween_property(image,"modulate",Color(1.0, 1.0, 1.0, 1.0), 2)

func fade_tween_out(image) -> void:
	var fadeTween = get_tree().create_tween()
	fadeTween.tween_property(image,"modulate",Color(1.0, 1.0, 1.0, 0.0), 2)
