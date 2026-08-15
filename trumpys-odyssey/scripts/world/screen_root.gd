# screen_root.gd
# Attached to the root Node2D of every overworld/dungeon screen scene.
# Just records where the player currently is for the HUD/debugging -- the
# actual spawn positioning is handled by Player._ready() reading
# GameState.consume_pending_spawn() directly.

extends Node2D

@export var world_id: int = 1
@export var screen_label: String = ""

func _ready() -> void:
	GameState.current_world = world_id
	GameState.current_screen = screen_label
