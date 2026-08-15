# floating_heal_text.gd
# Simple floating heal number. Instanced when the player heals from
# over-mitigation (see CombatSystem.check_over_mitigation_heal).

extends Node2D

@export var heal_amount: int = 2
@export var duration: float = 1.2

@onready var label: Label = $Label

func _ready() -> void:
	label.text = "+" + str(heal_amount)
	label.add_theme_color_override("font_color", Color(0.3, 1, 0.4))  # Green heal color

	# Float upward and fade
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 40, duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
