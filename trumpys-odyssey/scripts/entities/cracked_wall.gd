# cracked_wall.gd
# A crackable wall/tree/rock tile. Per the Game Bible, secret tiles are
# always a modified version of a regular tile (e.g. a dried tree instead of
# a normal tree) with two lit torches on either side, and open via bomb.
#
# secret_id links this wall to a specific entry in data/secrets_101.json.
# Leave it at -1 for a cracked wall that just crumbles with no secret
# behind it (rubble/shortcut variant).

extends StaticBody2D

@export var secret_id: int = -1

var _opened: bool = false

func _ready() -> void:
	add_to_group("cracked_wall")

func crack_open() -> void:
	if _opened:
		return
	_opened = true

	var collision := get_node_or_null("CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", true)

	var sprite := get_node_or_null("Sprite")
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(sprite.hide)

	if secret_id >= 0:
		var pickup = preload("res://scenes/entities/SecretPickup.tscn").instantiate()
		pickup.secret_id = secret_id
		pickup.global_position = global_position
		get_parent().add_child(pickup)
