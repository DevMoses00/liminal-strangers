extends Node2D

@export var left_character : AnimatedSprite2D
@export var right_character : AnimatedSprite2D
@export var left_arrow : AnimatedSprite2D
@export var right_arrow : AnimatedSprite2D
@export var changing_panel : Node2D

enum GamePhase { INTRO_LEFT, INTRO_RIGHT, TURN_BASED }
var phase = GamePhase.TURN_BASED
var input_enabled := false

var turn = "left"  # Start with left character's turn
var step_size := 52  # Distance to move per input
var max_steps := 20
var left_steps := 0
var right_steps := 0

var moment_on = true

var sequence_color : String = "red"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signals_connect()
	# priming the fixed panel to be red
	for s in get_tree().get_nodes_in_group("fixed"):
		s.animation = "red"
		s.play()
	if SoundManager.is_playing("Red") == false:
		SoundManager.play_bgm("Red")
	await get_tree().create_timer(1).timeout
	$ChangingPanel.action("red")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func signals_connect():
	$ChangingPanel.reveal_finished.connect(sequence)

func sequence(target_anim):
	if SoundManager.is_playing("RoomTone") == true:
		SoundManager.fade_out("RoomTone",1.0)
	if sequence_color == "red":
		reset_intro()
		_reset_arrows()
		for s in get_tree().get_nodes_in_group("fixed"):
			s.animation = "red"
			s.play()
		$FixedPanel.show()
		await get_tree().create_timer(1).timeout
		fade_tween_out($ChangingPanel)
		await get_tree().create_timer(3).timeout
		#set the modulation to 1 and hide the changing panel
		changing_panel.hide()
		changing_panel.modulate.a = 1
		fade_tween_in(left_character)
		SoundManager.play_sfx("Elevator")
		await get_tree().create_timer(4).timeout
		fade_tween_in(right_character)
		SoundManager.play_sfx("DoorOpen")
		await get_tree().create_timer(2).timeout
		turn = "left"
		_update_arrows()
		await get_tree().create_timer(1).timeout
		input_enabled = true
		moment_on = true 
	elif sequence_color == "blue":
		reset_intro()
		_reset_arrows()
		for s in get_tree().get_nodes_in_group("fixed"):
			s.animation = "blue"
			s.play()
		$FixedPanel.show()
		await get_tree().create_timer(1).timeout
		fade_tween_out($ChangingPanel)
		await get_tree().create_timer(3).timeout
		#set the modulation to 1 and hide the changing panel
		changing_panel.hide()
		changing_panel.modulate.a = 1
		fade_tween_in(left_character)
		SoundManager.play_sfx("Elevator")
		await get_tree().create_timer(4).timeout
		fade_tween_in(right_character)
		SoundManager.play_sfx("DoorOpen")
		await get_tree().create_timer(2).timeout
		turn = "left"
		_update_arrows()
		await get_tree().create_timer(1).timeout
		input_enabled = true
		moment_on = true 
	elif sequence_color == "green":
		reset_intro()
		_reset_arrows()
		for s in get_tree().get_nodes_in_group("fixed"):
			s.animation = "green"
			s.play()
		$FixedPanel.show()
		await get_tree().create_timer(1).timeout
		fade_tween_out($ChangingPanel)
		await get_tree().create_timer(3).timeout
		#set the modulation to 1 and hide the changing panel
		changing_panel.hide()
		changing_panel.modulate.a = 1
		fade_tween_in(left_character)
		SoundManager.play_sfx("Elevator")
		await get_tree().create_timer(4).timeout
		fade_tween_in(right_character)
		SoundManager.play_sfx("DoorOpen")
		await get_tree().create_timer(2).timeout
		turn = "left"
		_update_arrows()
		await get_tree().create_timer(1).timeout
		input_enabled = true
		moment_on = true 


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
							rotate_arrows()
							turn = "right"
							_update_arrows()
							await get_tree().create_timer(0.3).timeout
							input_enabled = true
							
					"right":
						if event.is_action_pressed("char_right_move") and right_steps < max_steps:
							input_enabled = false
							var sfx = ["Step1","Step2","Step3","Step4","Step5"].pick_random()
							SoundManager.play_sfx(sfx,0,10)
							right_character.position.x -= step_size
							right_steps += 1
							rotate_arrows()
							turn = "left"
							_update_arrows()
							await get_tree().create_timer(0.3).timeout
							input_enabled = true

				if abs(left_steps - right_steps) > 1:
					turn = "right" if left_steps < right_steps else "left"
					_update_arrows()

				if left_character.position.x >= right_character.position.x:
					_on_characters_cross()
				
				if left_steps >= max_steps:
					fade_tween_out(left_character)
					SoundManager.play_sfx("DoorClose")
				if right_steps >= max_steps:
					fade_tween_out(right_character)
					SoundManager.play_sfx("Elevator")
				if left_steps >= max_steps and right_steps >= max_steps: 
					input_enabled = false
					fade_tween_in($ChangingPanel)
					await get_tree().create_timer(4).timeout
					if sequence_color == "red":
						$ChangingPanel.action("blue")
						sequence_color = "blue"
					elif sequence_color == "blue": 
						$ChangingPanel.action("green")
						sequence_color = "green"
					elif sequence_color == "green":
						SoundManager.stop_all()
						SoundManager.play_bgm("Moment")
						await get_tree().create_timer(0.4).timeout
						$ChangingPanel.chaos_mode(10.0, 0.1,"green")
						await get_tree().create_timer(10).timeout
						get_tree().change_scene_to_file("res://scenes/end.tscn")



func _on_characters_cross():
	# sequence that only happens once, player has no control and it's a moment of glitch magic
	if moment_on == true:
		moment_on = false
		input_enabled = false
		$FixedPanel.hide()
		$ChangingPanel.show()
		SoundManager.stop_all()
		SoundManager.play_sfx("Static")
		SoundManager.play_sfx("Moment")
		if sequence_color == "red":
			$ChangingPanel.chaos_mode(5.0, 0.1,"red")
		elif sequence_color == "blue":
			$ChangingPanel.chaos_mode(10.0, 0.1,"blue")
		elif sequence_color == "green":
			$ChangingPanel.chaos_mode(15.0, 0.1,"green")
		await get_tree().create_timer(5).timeout
		SoundManager.stop_all()
		SoundManager.play_bgs("RoomTone")
		$ChangingPanel.hide()
		$ChangingPanel.modulate.a = 0
		$ChangingPanel.show()
		$FixedPanel.show()
		input_enabled = true

# HELPER FUNCTIONS
func fade_tween_in(image) -> void:
	var fadeTween = get_tree().create_tween()
	fadeTween.tween_property(image,"modulate",Color(1.0, 1.0, 1.0, 1.0), 2)

func fade_tween_out(image) -> void:
	var fadeTween = get_tree().create_tween()
	fadeTween.tween_property(image,"modulate",Color(1.0, 1.0, 1.0, 0.0), 2)
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

func _reset_arrows():
	left_arrow.scale = Vector2(0.8, 0.8)
	right_arrow.scale = Vector2(0.8, 0.8)
