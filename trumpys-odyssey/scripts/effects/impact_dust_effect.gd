# impact_dust_effect.gd
# Simple dust/impact particle effect for knockback hits.
# Instanced at the point of impact by CombatSystem.spawn_impact_dust().

extends Node2D

@export var duration: float = 0.4

func _ready() -> void:
	for i in 6:
		var dust := ColorRect.new()
		dust.size = Vector2(4, 4)
		dust.color = Color(0.9, 0.85, 0.7, 0.8)
		dust.position = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		add_child(dust)

		var tween := create_tween()
		tween.tween_property(dust, "position", dust.position + Vector2(randf_range(-20, 20), randf_range(-15, 15)), duration)
		tween.parallel().tween_property(dust, "modulate:a", 0.0, duration)
		tween.tween_callback(dust.queue_free)

	# Auto delete after effect
	await get_tree().create_timer(duration).timeout
	queue_free()
