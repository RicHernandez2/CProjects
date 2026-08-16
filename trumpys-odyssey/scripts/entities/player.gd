# player.gd
# Trumpy's Odyssey - Player controller.
#
# Merges the original Player_Damage_System.gd + Player_Knockback.gd design
# docs with movement, bombs, and a basic melee attack. Mitigation and stat
# boosts are read live from SecretsDatabase (the 101 stacking secrets) so
# there's one source of truth instead of a duplicated local dict.

extends CharacterBody2D
class_name Player

signal health_changed(new_health: int)
signal died
signal tunic_color_changed(new_color: String)
signal bombs_changed(count: int)

@export var base_speed: float = 90.0
@export var max_health: int = 12  # 6 hearts = 12 HP
@export var base_bomb_capacity: int = 5
@export var base_melee_damage: int = 1

var current_health: int = max_health
var bombs: int = base_bomb_capacity
var tunic_color: String = "green"  # green, blue, purple

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
var is_knocked_back: bool = false

var _attack_cooldown: float = 0.0
const ATTACK_COOLDOWN_TIME := 0.35

@onready var attack_area: Area2D = get_node_or_null("AttackArea")

func _ready() -> void:
	add_to_group("player")

	if GameState.has_saved_player_state():
		max_health = GameState.player_max_health
		current_health = GameState.player_health
		bombs = GameState.player_bombs
		tunic_color = GameState.player_tunic_color
	else:
		current_health = max_health
		bombs = get_bomb_capacity()
		_sync_to_game_state()

	_update_tunic_color()

	if GameState.has_pending_spawn:
		global_position = GameState.consume_pending_spawn()

func _sync_to_game_state() -> void:
	GameState.save_player_state(current_health, max_health, bombs, tunic_color)

func _physics_process(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	if is_knocked_back:
		knockback_timer -= delta
		velocity = knockback_velocity
		move_and_slide()
		if knockback_timer <= 0.0:
			is_knocked_back = false
			knockback_velocity = Vector2.ZERO
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * get_move_speed()
	move_and_slide()

	if Input.is_action_just_pressed("bomb") and bombs > 0:
		place_bomb()

	if Input.is_action_just_pressed("attack") and _attack_cooldown <= 0.0:
		perform_attack()

# === MOVEMENT / STATS (fed by stacked secrets) ===
func get_move_speed() -> float:
	var speed := base_speed * (1.0 + SecretsDatabase.get_stat("move_speed"))
	if GameState.zeus_mode:
		speed *= 2.0
	return speed

func get_bomb_capacity() -> int:
	return int(base_bomb_capacity * (1.0 + SecretsDatabase.get_stat("bomb_capacity")))

func get_melee_damage() -> int:
	return int(ceil(base_melee_damage * (1.0 + SecretsDatabase.get_stat("attack_power"))))

func get_secret_detection_range() -> float:
	return 48.0 * (1.0 + SecretsDatabase.get_stat("secret_range"))

# === BOMBS ===
func place_bomb() -> void:
	if not GameState.zeus_mode:
		bombs -= 1
		bombs_changed.emit(bombs)
		_sync_to_game_state()
	var bomb = preload("res://scenes/entities/Bomb.tscn").instantiate()
	bomb.global_position = global_position
	get_parent().add_child(bomb)

func refill_bombs() -> void:
	bombs = get_bomb_capacity()
	bombs_changed.emit(bombs)
	_sync_to_game_state()

# === MELEE ATTACK ===
func perform_attack() -> void:
	_attack_cooldown = ATTACK_COOLDOWN_TIME
	if not attack_area:
		return
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			CombatSystem.apply_damage(body, get_melee_damage(), "physical", self)

# === DAMAGE / HEALTH ===
func take_damage(amount: int, type: String = "physical") -> void:
	if current_health <= 0:
		return
	if GameState.zeus_mode:
		return  # Invulnerable

	var reduction: float = SecretsDatabase.get_stat(type)
	var final_damage: int = int(amount * max(0.0, 1.0 - reduction))

	if final_damage < 1 and reduction < 1.0:
		final_damage = 1  # minimum 1 damage unless fully mitigated

	current_health -= final_damage
	current_health = max(0, current_health)

	health_changed.emit(current_health)
	_sync_to_game_state()

	CombatSystem.check_over_mitigation_heal(self, amount, type)

	if current_health <= 0:
		die()
	else:
		check_tunic_color_change()

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health)
	_sync_to_game_state()

func die() -> void:
	died.emit()
	print("Player died")

# === KNOCKBACK ===
func apply_player_knockback(direction: Vector2, force: float = 140.0, duration: float = 0.25) -> void:
	knockback_velocity = direction.normalized() * force
	knockback_timer = duration
	is_knocked_back = true

# === TUNIC COLOR (fire/ice mitigation thresholds) ===
func check_tunic_color_change() -> void:
	var new_color := tunic_color
	var fire_maxed: bool = SecretsDatabase.get_stat("fire") >= 1.0
	var ice_maxed: bool = SecretsDatabase.get_stat("ice") >= 1.0

	if fire_maxed and ice_maxed:
		new_color = "purple"
	elif fire_maxed or ice_maxed:
		new_color = "blue"

	if new_color != tunic_color:
		tunic_color = new_color
		_update_tunic_color()
		tunic_color_changed.emit(tunic_color)
		_sync_to_game_state()

func _update_tunic_color() -> void:
	match tunic_color:
		"green":
			modulate = Color(1, 1, 1)
		"blue":
			modulate = Color(0.6, 0.8, 1.0)
		"purple":
			modulate = Color(0.8, 0.6, 1.0)

func debug_stats() -> void:
	print("Health: ", current_health, "/", max_health)
	print("Tunic: ", tunic_color)
	print("Bombs: ", bombs, "/", get_bomb_capacity())
	print("Secrets: ", SecretsDatabase.progress_text())
