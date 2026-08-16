# secret_pickup.gd
# Revealed by a cracked wall exploding. Player walks over it to collect
# one of the 101 secrets from SecretsDatabase.

extends Area2D

@export var secret_id: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if secret_id < 0 or SecretsDatabase.is_collected(secret_id):
		queue_free()
		return

	SecretsDatabase.collect_secret(secret_id)
	_show_pickup_text()

	var sparkle_count := 12
	for i in sparkle_count:
		if ResourceLoader.exists("res://scenes/effects/SparkleParticle.tscn"):
			var p = preload("res://scenes/effects/SparkleParticle.tscn").instantiate()
			p.global_position = global_position
			get_parent().add_child(p)

	await get_tree().create_timer(0.1).timeout
	queue_free()

func _show_pickup_text() -> void:
	var secret: Dictionary = SecretsDatabase.secrets_by_id.get(secret_id, {})
	if secret.is_empty():
		return

	var label := Label.new()
	label.text = "%s\n(%s)" % [secret["name"], secret["rarity"]]
	label.add_theme_color_override("font_color", _rarity_color(secret["rarity"]))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, -50)
	label.size = Vector2(120, 40)
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-60, -50)

	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 1.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.6)
	tween.tween_callback(label.queue_free)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Rare":
			return Color(0.75, 0.75, 0.8)
		"Epic":
			return Color(0.64, 0.35, 0.94)
		"Legendary":
			return Color(1.0, 0.6, 0.0)
		"Mythic":
			return Color(1.0, 0.2, 0.2)
		_:
			return Color(1, 1, 1)
