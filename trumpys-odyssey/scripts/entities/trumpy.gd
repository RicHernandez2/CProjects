# trumpy.gd
# Trumpy - a rainbow-colored, Alf-like alien with a longer/harder snout.
# Purely a fictional game creature, not based on any real person; the name
# is a whimsical creature name chosen for this game (see design/GAME_BIBLE.md).
#
# Behavior per the Game Bible: makes a sound as the player gets closer,
# and the instant the player touches it, it orbits them trailing sparkles
# and yells "Trumpy!" before flying off.
#
# Ported/cleaned up from the original setup-guide sample, which had the
# state machine's indentation broken (chase logic and the collide check
# were mis-nested). Rewritten here as a clean, correct state machine.

extends CharacterBody2D

@export var trumpy_color: Color = Color(1, 0.5, 0)
@export var speed: float = 90.0
@export var detection_range: float = 140.0
@export var collide_range: float = 25.0
@export var orbit_duration: float = 2.5
@export var proximity_sound_range: float = 220.0

var state: String = "idle"  # idle, chase, orbiting
var orbit_timer: float = 0.0
var player_ref: Node2D = null

@onready var proximity_sound: AudioStreamPlayer2D = get_node_or_null("ProximitySound")
@onready var sprite: ColorRect = get_node_or_null("Sprite")

func _ready() -> void:
	add_to_group("trumpy")
	player_ref = get_tree().get_first_node_in_group("player")
	if sprite:
		sprite.color = trumpy_color

func _physics_process(delta: float) -> void:
	if not player_ref:
		return

	var dist: float = global_position.distance_to(player_ref.global_position)
	_update_proximity_sound(dist)

	match state:
		"orbiting":
			_orbit_behavior(delta)
		"chase":
			_chase_behavior(dist)
		_:
			_idle_behavior(dist)

	if state != "orbiting" and dist < collide_range:
		_start_orbit()

func _idle_behavior(dist: float) -> void:
	if dist < detection_range:
		state = "chase"
	else:
		# Gentle wander
		velocity = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		move_and_slide()

func _chase_behavior(dist: float) -> void:
	if dist >= detection_range * 1.3:
		state = "idle"
		return
	var direction := (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _orbit_behavior(delta: float) -> void:
	orbit_timer -= delta
	var angle := Time.get_ticks_msec() / 300.0
	global_position = player_ref.global_position + Vector2(cos(angle), sin(angle)) * 50

	if orbit_timer <= 0.0:
		state = "idle"

func _start_orbit() -> void:
	state = "orbiting"
	orbit_timer = orbit_duration
	_show_trumpy_text()
	_create_sparkles()

func _update_proximity_sound(dist: float) -> void:
	if not proximity_sound or not proximity_sound.stream:
		return
	if dist < proximity_sound_range:
		if not proximity_sound.playing:
			proximity_sound.playing = true
		var closeness: float = 1.0 - clamp(dist / proximity_sound_range, 0.0, 1.0)
		proximity_sound.volume_db = lerp(-24.0, 0.0, closeness)
		proximity_sound.pitch_scale = lerp(0.9, 1.3, closeness)
	elif proximity_sound.playing:
		proximity_sound.playing = false

func _show_trumpy_text() -> void:
	var label := Label.new()
	label.text = "Trumpy!"
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	label.position = Vector2(-20, -30)
	add_child(label)
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(label):
		label.queue_free()

func _create_sparkles() -> void:
	if not ResourceLoader.exists("res://scenes/effects/SparkleParticle.tscn"):
		return
	for i in 12:
		var p = preload("res://scenes/effects/SparkleParticle.tscn").instantiate()
		p.global_position = global_position
		get_parent().add_child(p)
