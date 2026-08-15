# bomb.gd
# Placed by the player (Player.place_bomb). Ticks down a fuse, then
# explodes and cracks open any CrackedWall within its blast radius,
# revealing whatever secret (or plain rubble) is behind it.

extends Node2D

@export var fuse_time: float = 0.75
@export var blast_radius: float = 50.0

@onready var sprite: ColorRect = $Sprite

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), fuse_time * 0.5)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), fuse_time * 0.5)

	await get_tree().create_timer(fuse_time).timeout
	_explode()

func _explode() -> void:
	var cracked_walls := get_tree().get_nodes_in_group("cracked_wall")
	for wall in cracked_walls:
		if wall.global_position.distance_to(global_position) < blast_radius:
			if wall.has_method("crack_open"):
				wall.crack_open()

	var dust = preload("res://scenes/effects/ImpactDustEffect.tscn").instantiate()
	dust.global_position = global_position
	dust.duration = 0.5
	get_parent().add_child(dust)

	queue_free()
