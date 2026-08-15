# game_state.gd (autoload singleton: GameState)
# Cross-screen game state: gems, consumables, world-unlock items, Zeus Mode,
# and the player's persistent stats (health/bombs/tunic color survive
# get_tree().change_scene_to_file() calls, which destroy and recreate the
# whole scene tree -- including Player -- on every screen transition).
#
# Secrets themselves live in SecretsDatabase; this is everything else the
# Game Bible calls "overt parts of the game" (separate from secrets).

extends Node

signal gems_changed(total: int)
signal zeus_mode_changed(active: bool)

var gems: int = 0
var gem_pouch_capacity: int = 50

var arrows: int = 0
var arrow_capacity: int = 10
var fire_sticks: int = 0
var health_potions: int = 0
var mana_potions: int = 0
var dual_potions: int = 0

# Progression items that unlock passage between worlds. Each of the 8
# worlds' dungeon bosses drops the item that unlocks the gate into the
# next world (see scripts/entities/boss_enemy.gd and
# scripts/entities/screen_exit.gd). "bomb" is the only one you start with.
var unlocked_items: Dictionary = {
	"bomb": true,
	"fire_stick": false,   # World 1 boss drop -> unlocks World 2
	"magic_lamp": false,   # World 2 boss drop -> unlocks World 3
	"hookshot": false,     # World 3 boss drop -> unlocks World 4
	"flippers": false,     # World 4 boss drop -> unlocks World 5
	"ice_boots": false,    # World 5 boss drop -> unlocks World 6
	"wing_charm": false,   # World 6 boss drop -> unlocks World 7
	"storm_horn": false,   # World 7 boss drop -> unlocks World 8
	"aegis_of_zeus": false, # World 8 boss drop -> final reward
}

var zeus_mode: bool = false

# === Player persistence across screen transitions ===
var player_health: int = -1  # -1 = not yet initialized; Player seeds it on first _ready
var player_max_health: int = 12
var player_bombs: int = -1
var player_tunic_color: String = "green"

# Where to place the player when a new screen scene finishes loading, set
# by ScreenExit right before change_scene_to_file(). Consumed once by the
# new screen's spawn logic (see scripts/world/screen_root.gd).
var pending_spawn_position: Vector2 = Vector2.ZERO
var has_pending_spawn: bool = false

var current_world: int = 1
var current_screen: String = ""

func add_gems(amount: int) -> void:
	gems = min(gems + amount, gem_pouch_capacity)
	gems_changed.emit(gems)

func grow_gem_pouch(extra_capacity: int) -> void:
	gem_pouch_capacity += extra_capacity

func unlock_item(item_key: String) -> void:
	unlocked_items[item_key] = true

func has_item(item_key: String) -> bool:
	return unlocked_items.get(item_key, false)

func set_zeus_mode(active: bool) -> void:
	if active == zeus_mode:
		return
	zeus_mode = active
	zeus_mode_changed.emit(active)

func save_player_state(health: int, max_health: int, bombs: int, tunic_color: String) -> void:
	player_health = health
	player_max_health = max_health
	player_bombs = bombs
	player_tunic_color = tunic_color

func has_saved_player_state() -> bool:
	return player_health >= 0

func request_spawn(position: Vector2) -> void:
	pending_spawn_position = position
	has_pending_spawn = true

func consume_pending_spawn() -> Vector2:
	has_pending_spawn = false
	return pending_spawn_position

func travel_to(scene_path: String, spawn_position: Vector2) -> void:
	request_spawn(spawn_position)
	get_tree().change_scene_to_file(scene_path)
