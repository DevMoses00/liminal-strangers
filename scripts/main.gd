extends Node2D

@export var left_character : AnimatedSprite2D
@export var right_character : AnimatedSprite2D
@export var left_arrow : AnimatedSprite2D
@export var right_arrow : AnimatedSprite2D
@export var changing_panel : Node2D
var turn = "left"  # Start with left character's turn
var step_size := 50  # Distance to move per input
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
	# Turn everything off
	signals_connect()
	$FixedPanel/BG.hide()
	$FixedPanel/LEFT.hide()
	$FixedPanel/RIGHT.hide()
	$FixedPanel/Circles/Top.hide()
	$FixedPanel/Circles/Middle.hide()
	_update_arrows()
	await get_tree().create_timer(3).timeout
	#SoundManager.play_bgs("Nature")
	fade_tween_in($Logo)
	await get_tree().create_timer(4).timeout
	fade_tween_out($Logo)
	await get_tree().create_timer(2).timeout
	fade_tween_in(left_character)
	#SoundManager.play_sfx("Elevator")
	await get_tree().create_timer(4).timeout
	# fade in arrow keys circle
	fade_tween_in($FixedPanel/Circles/Bottom)
	await get_tree().create_timer(2).timeout
	input_enabled = true


func signals_connect():
	$ChangingPanel.reveal_finished.connect(sequence)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# putting a check in process for when both players reach max steps at the same time 
	if left_steps >= max_steps and right_steps >= max_steps:
		if sequence_on == true: 
			# this is off so it doesn't repeat, but must be turned on at some point
			sequence_on = false
			input_enabled = false
			fade_tween_in($ChangingPanel)
			await get_tree().create_timer(2).timeout
			if local_string == "blue":
				$ChangingPanel.show()
				$ChangingPanel.action("blue")
			elif local_string == "green":
				$ChangingPanel.show()
				$ChangingPanel.action("green")
	pass

# MOVEMENT LOGIC
func _unhandled_input(event):
	if not input_enabled:
		return
	
	if event is InputEventKey and event.pressed:
		match phase:
			GamePhase.INTRO_LEFT:
				if event.keycode == KEY_LEFT:
					rotate_arrows()
					left_character.position.x += step_size
					left_steps += 1
					if left_steps >= max_steps:  # Adjust for screen layout
						input_enabled = false
						_reset_arrows()
						fade_tween_out(left_character)
						#SoundManager.play_sfx("Elevator")
						await get_tree().create_timer(4).timeout
						fade_tween_in(right_character)
						#SoundManager.play_sfx("Door")
						await get_tree().create_timer(2).timeout
						reset_intro()
						phase = GamePhase.INTRO_RIGHT
						turn = "right"
						input_enabled = true
						_update_arrows()
						print("Now try moving the Right Character!")
			GamePhase.INTRO_RIGHT:
				if event.keycode == KEY_RIGHT:
					rotate_arrows()
					right_character.position.x -= step_size
					right_steps += 1
					if right_steps >= max_steps:
						_reset_arrows()
						input_enabled = false
						fade_tween_out(right_character)
						#SoundManager.play_sfx("Door")
						await get_tree().create_timer(2).timeout
						reset_intro()
						await get_tree().create_timer(2).timeout
						fade_tween_in(left_character)
						#SoundManager.play_sfx("Elevator")
						await get_tree().create_timer(4).timeout
						fade_tween_in(right_character)
						#SoundManager.play_sfx("Door")
						await get_tree().create_timer(2).timeout
						phase = GamePhase.TURN_BASED
						input_enabled = true
						turn = "left"
						_update_arrows()
						print("Now take turns with both characters.")
			GamePhase.TURN_BASED:
				match turn:
					"left":
						if event.keycode == KEY_LEFT and left_steps < max_steps:
							left_character.position.x += step_size
							left_steps += 1
							rotate_arrows()
							turn = "right"
							_update_arrows()
							
					"right":
						if event.keycode == KEY_RIGHT and right_steps < max_steps:
							right_character.position.x -= step_size
							right_steps += 1
							rotate_arrows()
							turn = "left"
							_update_arrows()
							

				if abs(left_steps - right_steps) > 1:
					turn = "right" if left_steps < right_steps else "left"
					_update_arrows()

				if left_character.position.x >= right_character.position.x:
					_on_characters_cross()
				
				if left_steps >= max_steps:
					fade_tween_out(left_character)
				
				if right_steps >= max_steps:
					fade_tween_out(right_character)

		if abs(left_steps - right_steps) > 1:
			turn = "right" if left_steps < right_steps else "left"
			_update_arrows()

		if left_character.position.x >= right_character.position.x:
			_on_characters_cross()

func sequence(string):
	print("connected")
	# after the intro
	if string == "red":
		local_string = "blue"
		reset_intro()
		input_enabled = false
		$FixedPanel/BG.show()
		$FixedPanel/LEFT.show()
		$FixedPanel/RIGHT.show()
		$FixedPanel/Circles/Top.show()
		$FixedPanel/Circles/Middle.show()
		$FixedPanel/TOP.show()
		$FixedPanel/Circles/Bottom.show()
		fade_tween_out($ChangingPanel)
		await get_tree().create_timer(2).timeout
		fade_tween_in(left_character)
		#SoundManager.play_sfx("Elevator")
		await get_tree().create_timer(4).timeout
		fade_tween_in(right_character)
		#SoundManager.play_sfx("Door")
		await get_tree().create_timer(2).timeout
		input_enabled = true
	
	if string == "blue":
		local_string = "green"
		reset_intro()
		input_enabled = false
		sequence_on = true
		await get_tree().create_timer(0.5).timeout
		for s in get_tree().get_nodes_in_group("fixed"):
			s.animation = "blue"
			s.play()
		fade_tween_out($ChangingPanel)
		await get_tree().create_timer(2).timeout
		fade_tween_in(left_character)
		#SoundManager.play_sfx("Elevator")
		await get_tree().create_timer(4).timeout
		fade_tween_in(right_character)
		#SoundManager.play_sfx("Door")
		await get_tree().create_timer(2).timeout
		input_enabled = true
		pass
	if string == "green":
		pass
		local_string = "end"
		reset_intro()
		input_enabled = false
		sequence_on = true
		await get_tree().create_timer(0.5).timeout
		for s in get_tree().get_nodes_in_group("fixed"):
			s.animation = "green"
			s.play()
		fade_tween_out($ChangingPanel)
		await get_tree().create_timer(2).timeout
		fade_tween_in(left_character)
		#SoundManager.play_sfx("Elevator")
		await get_tree().create_timer(4).timeout
		fade_tween_in(right_character)
		#SoundManager.play_sfx("Door")
		await get_tree().create_timer(2).timeout
		input_enabled = true


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
	input_enabled = true

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
	if intro == true: 
		# HIDE EVERYTHING
		$FixedPanel/TOP.hide()
		$FixedPanel/TOP.position = Vector2.ZERO
		$FixedPanel/Circles/Bottom.hide()
		#SoundManager.play_sfx("Title")
		input_enabled = false
		await get_tree().create_timer(2).timeout
		# SHOW TITLE
		fade_tween_in($Title)
		await get_tree().create_timer(5).timeout
		fade_tween_out($Title)
		await get_tree().create_timer(5).timeout
		print("Characters crossed!")
		# Trigger your next logic here
		$ChangingPanel.action("red")
		intro = false
		reset_intro()
	else: 
		#make sure tha alpha on Changing panel is up
		$ChangingPanel.hide()
		$ChangingPanel.modulate.a = 1
		if local_string == "end":
			$ChangingPanel.show()
			input_enabled = false
			$ChangingPanel._chaos_mode(20.0, 0.1)
			await get_tree().create_timer(15).timeout
			# temporary cycle
			
			
		else:
			$ChangingPanel.show()
			$ChangingPanel._chaos_mode(2.0, 0.1)
			await get_tree().create_timer(1).timeout
			$ChangingPanel.hide()
			#SoundManager.play_mfx()


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
