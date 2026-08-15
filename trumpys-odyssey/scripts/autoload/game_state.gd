# game_state.gd (autoload singleton: GameState)
# Cross-screen game state: gems, consumables, world-unlock items, Zeus Mode.
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

# Progression items that unlock passage between worlds (bombs are the
# starting item; others are invented Zelda-style key items).
var unlocked_items: Dictionary = {
	"bomb": true,
	"fire_stick": false,
	"magic_lamp": false,
	"hookshot": false,
	"flippers": false,
}

var zeus_mode: bool = false

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
