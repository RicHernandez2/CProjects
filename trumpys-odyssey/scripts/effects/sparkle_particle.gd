# sparkle_particle.gd
# A single magic sparkle - used by Trumpy's orbit trail and secret pickups.

extends Node2D

@export var life_time: float = 0.6
@export var sparkle_color: Color = Color(1, 0.95, 0.4)

func _ready() -> void:
	var dot := ColorRect.new()
	dot.size = Vector2(3, 3)
	dot.color = sparkle_color
	dot.position = Vector2(-1.5, -1.5)
	add_child(dot)

	position += Vector2(randf_range(-10, 10), randf_range(-10, 10))

	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2(randf_range(-16, 16), randf_range(-26, -6)), life_time)
	tween.parallel().tween_property(dot, "modulate:a", 0.0, life_time)
	tween.tween_callback(queue_free)
