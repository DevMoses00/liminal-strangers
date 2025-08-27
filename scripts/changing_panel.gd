extends Node2D

@onready var sprites : Array = []  # all AnimatedSprite2Ds

var reveal_delay := 0.5   # starting delay
var min_delay := 0.05     # fastest reveal
signal reveal_finished
# list of available animations
const ANIMS = ["blank", "blue", "red", "green"]

func _ready():
	# Collect all AnimatedSprite2D children
	sprites = get_children().filter(func(c): return c is AnimatedSprite2D)
	
	# Start them all as "blank"
	for s in sprites:
		s.play("blank")
	await get_tree().create_timer(2).timeout
	# Example: progressive reveal into "blue"
	_progressive_reveal("red")
	# Later, you could trigger chaos mode like this:
	await get_tree().create_timer(20.0).timeout
	chaos_mode(9.0, 0.1,"red")  # run chaos for 3 seconds, switching every 0.1s

func action(string):
	_progressive_reveal(string)
	if string == "blue":
		SoundManager.play_bgm("Blue")
		SoundManager.play_bgs("Force",0,-15,-10)
	elif string == "green":
		SoundManager.play_bgm("Green")
		SoundManager.play_bgs("Nature",0,-10)
	
# ------------------------------------------------------------
# Progressive reveal (one by one, speeds up over time)
# ------------------------------------------------------------
func _progressive_reveal(target_anim : String, index := 0):
	if index == 0:
		# shuffle order before first reveal
		sprites.shuffle()
		reveal_delay = 0.5
	
	if index >= sprites.size():
		#reveal_finished.emit("target_")
		print("done")
		reveal_finished.emit(target_anim)
		return  # done
	
	var sprite = sprites[index]
	sprite.play(target_anim)
	SoundManager.play_sfx("Piece",0,0,randf())
	
	# optional fade-in effect if using "blank" alpha 0
	sprite.modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)
	
	# ramp up speed
	reveal_delay = max(min_delay, reveal_delay * 0.95)
	
	# schedule next
	await get_tree().create_timer(reveal_delay).timeout
	_progressive_reveal(target_anim, index + 1)


# ------------------------------------------------------------
# Chaos mode (randomize animations independently)
# ------------------------------------------------------------
func chaos_mode(duration : float, interval : float, color : String):
	var time_passed := 0.0
	while time_passed < duration:
		for sprite in sprites:
			var anim = ANIMS.pick_random()
			sprite.play(anim)
		await get_tree().create_timer(interval).timeout
		time_passed += interval
	for s in sprites:
		s.play(color)
