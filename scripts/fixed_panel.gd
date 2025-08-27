extends Node2D

# === Node refs ===
@export var left_box  : AnimatedSprite2D       
@export var left_hand : AnimatedSprite2D         
@export var left_anim : AnimatedSprite2D  

@export var right_box  : AnimatedSprite2D        
@export var right_hand : AnimatedSprite2D          
@export var right_anim : AnimatedSprite2D

# === Tunables ===
@export var move_speed        : float = 0  # character glide speed (px/sec) if you also move characters
@export var box_bob_amp       : float = 8.0     # vertical bob amplitude (px)
@export var box_bob_hz        : float = 1.0     # bob frequency (cycles/sec)
@export var hand_in_dx        : float = 12.0    # how far the hand slides toward center (px)
@export var hand_tween_time   : float = 0.12    # seconds for the hand slide tween


# === Cached bases ===
var l_box_base : Vector2
var r_box_base : Vector2
var l_hand_base : Vector2
var r_hand_base : Vector2

# === State ===
var left_active  := false
var right_active := false
var t_left  := 0.0   # bobbing phase accumulators
var t_right := 0.0

func _ready() -> void:
	# Cache original positions so we can return to them cleanly
	l_box_base  = left_box.position
	r_box_base  = right_box.position
	l_hand_base = left_hand.position
	r_hand_base = right_hand.position

	# Make sure animations start stopped at frame 0
	_reset_anim_to_start(left_anim)
	_reset_anim_to_start(right_anim)

func _physics_process(delta: float) -> void:
	# --- Read input (hold to keep active) ---
	var lp  := Input.is_action_pressed("char_left_move")
	var rp  := Input.is_action_pressed("char_right_move")
	var ljp := Input.is_action_just_pressed("char_left_move")
	var rjp := Input.is_action_just_pressed("char_right_move")
	var ljr := Input.is_action_just_released("char_left_move")
	var rjr := Input.is_action_just_released("char_right_move")

	# --- Left character reactions ---
	if ljp:
		left_active = true
		_hand_slide(left_hand, l_hand_base + Vector2(+hand_in_dx, 0)) # toward screen center = +X for left side
		_anim_play_forward(left_anim)
	if ljr:
		left_active = false
		_hand_slide(left_hand, l_hand_base)  # slide back
		_anim_play_reverse_to_start(left_anim)

	# --- Right character reactions ---
	if rjp:
		right_active = true
		_hand_slide(right_hand, r_hand_base + Vector2(-hand_in_dx, 0)) # toward center = -X for right side
		_anim_play_forward(right_anim)
	if rjr:
		right_active = false
		_hand_slide(right_hand, r_hand_base)
		_anim_play_reverse_to_start(right_anim)

	# --- Box bobbing while held ---
	if left_active:
		t_left += TAU * box_bob_hz * delta
		left_box.position.y = l_box_base.y + sin(t_left) * box_bob_amp
	else:
		# ease back to base when released
		left_box.position.y = lerp(left_box.position.y, l_box_base.y, 12.0 * delta)

	if right_active:
		t_right += TAU * box_bob_hz * delta
		right_box.position.y = r_box_base.y + sin(t_right) * box_bob_amp
	else:
		right_box.position.y = lerp(right_box.position.y, r_box_base.y, 12.0 * delta)

	# --- Stop reversed animations cleanly at frame 0 ---
	_stop_if_rewound(left_anim)
	_stop_if_rewound(right_anim)

# =============== Helpers ===============

func _hand_slide(hand: Node2D, target: Vector2) -> void:
	var tw := create_tween()
	tw.tween_property(hand, "position", target, hand_tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _anim_play_forward(anim: AnimatedSprite2D) -> void:
	#anim.animation = name
	anim.speed_scale = abs(anim.speed_scale) # ensure forward
	anim.play()

func _anim_play_reverse_to_start(anim: AnimatedSprite2D) -> void:
	# Play the same clip backwards toward frame 0.
	#anim.animation = name
	anim.speed_scale = -abs(anim.speed_scale) # reverse
	# Important: if it was stopped, ensure it continues from current frame (or last). We'll just play:
	if not anim.is_playing():
		anim.play()

func _stop_if_rewound(anim: AnimatedSprite2D) -> void:
	# When reversing, stop exactly at frame 0 so it doesn't loop backwards forever.
	if anim.speed_scale < 0 and anim.frame == 0:
		anim.stop()
		anim.speed_scale = abs(anim.speed_scale)  # reset to forward-ready
		anim.frame = 0

func _reset_anim_to_start(anim: AnimatedSprite2D) -> void:
	#anim.animation = name
	anim.stop()
	anim.speed_scale = 6.0
	anim.frame = 0
