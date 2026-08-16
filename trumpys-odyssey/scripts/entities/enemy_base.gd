# enemy_base.gd
# Base script for enemies. Inherit from this or attach to enemy scenes.
#
# Merges the original EnemyBase_Confused.gd (patrol/chase/confused AI, the
# "WTF + run away" reaction when the player over-mitigates) with
# Enemy_Knockback.gd (knockback state), which the original design docs
# described as two separate files meant to be combined.

extends CharacterBody2D
class_name EnemyBase

@export var speed: float = 80.0
@export var max_health: int = 4
@export var damage: int = 2
@export var damage_type: String = "physical"
@export var gem_drop_min: int = 1
@export var gem_drop_max: int = 3
@export var detection_range: float = 140.0
@export var attack_range: float = 30.0

var health: int
var state: String = "patrol"  # patrol, chase, attack, confused, knocked_back
var player: Node2D = null
var confused_timer: float = 0.0
var original_speed: float = 0.0

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
var _pre_knockback_state: String = "patrol"

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	original_speed = speed
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	match state:
		"patrol":
			patrol_behavior(delta)
		"chase":
			chase_behavior(delta)
		"confused":
			confused_behavior(delta)
		"knocked_back":
			knockback_behavior(delta)
		_:
			pass

func patrol_behavior(_delta: float) -> void:
	# Simple idle - replace with your actual patrol path logic.
	velocity = Vector2.ZERO
	move_and_slide()

	if player and global_position.distance_to(player.global_position) < detection_range:
		state = "chase"

func chase_behavior(_delta: float) -> void:
	if not player:
		state = "patrol"
		return
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	if global_position.distance_to(player.global_position) < attack_range:
		attack_player()
	elif global_position.distance_to(player.global_position) > detection_range * 1.5:
		state = "patrol"

func confused_behavior(delta: float) -> void:
	confused_timer -= delta
	if confused_timer <= 0.0:
		state = "chase" if player else "patrol"
		speed = original_speed
		return

	# Run away in random direction
	var flee_dir := (global_position - player.global_position).normalized()
	velocity = flee_dir * (speed * 1.5)
	move_and_slide()

func knockback_behavior(delta: float) -> void:
	knockback_timer -= delta
	velocity = knockback_velocity
	move_and_slide()

	if knockback_timer <= 0.0:
		if state == "knocked_back":  # don't clobber a state change that happened mid-knockback
			state = _pre_knockback_state
			speed = original_speed

func attack_player() -> void:
	if player and player.has_method("take_damage"):
		player.take_damage(damage, damage_type)

# === Called by CombatSystem.apply_damage() ===
func take_damage(amount: int, _type: String = "physical") -> void:
	health -= amount
	if health <= 0:
		die()
	elif animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hurt"):
		animated_sprite.play("hurt")

func die() -> void:
	var gem_luck: float = SecretsDatabase.get_stat("luck")
	var gem_value := randi_range(gem_drop_min, gem_drop_max)
	gem_value = int(ceil(gem_value * (1.0 + gem_luck)))
	GameState.add_gems(gem_value)
	queue_free()

# === Called by Enemy_Knockback (player hit the enemy) ===
func apply_knockback(direction: Vector2, force: float = 180.0, duration: float = 0.35) -> void:
	if state != "knocked_back":
		_pre_knockback_state = state
	knockback_velocity = direction.normalized() * force
	knockback_timer = duration
	state = "knocked_back"

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hurt"):
		animated_sprite.play("hurt")

# === Called by CombatSystem when player over-mitigation heals ===
func become_confused(duration: float = 2.5) -> void:
	if state == "confused":
		return

	state = "confused"
	confused_timer = duration
	speed = original_speed * 1.2  # Run faster while confused

	play_wtf_animation()

func play_wtf_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("wtf"):
		animated_sprite.play("wtf")
	else:
		# Fallback: flash red
		modulate = Color(1, 0.5, 0.5)
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(self):
			modulate = Color(1, 1, 1)

	show_confused_text()

func show_confused_text() -> void:
	var label = Label.new()
	label.text = "?!?"
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	label.position = Vector2(0, -30)
	add_child(label)

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(label):
		label.queue_free()
