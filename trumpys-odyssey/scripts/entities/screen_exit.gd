# screen_exit.gd
# Placed along a screen's edge (or anywhere inside it, e.g. a dungeon
# entrance). Walking into it loads target_scene and places the player at
# spawn_position on the new screen.
#
# If required_item is non-empty, this doubles as a Zelda-style world gate:
# the transition only happens once GameState.has_item(required_item) is
# true; otherwise it shows what's needed and gently nudges the player back
# instead of letting them wander into an unfinished scene.

extends Area2D

@export var target_scene: String = ""
@export var spawn_position: Vector2 = Vector2.ZERO
@export var required_item: String = ""
@export var locked_hint: String = ""

var _hint_cooldown: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _hint_cooldown > 0.0:
		_hint_cooldown -= delta

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if target_scene == "":
		return

	if required_item != "" and not GameState.has_item(required_item):
		_show_locked_hint(body)
		return

	GameState.travel_to(target_scene, spawn_position)

func _show_locked_hint(player: Node) -> void:
	if _hint_cooldown > 0.0:
		return
	_hint_cooldown = 1.5

	var text := locked_hint if locked_hint != "" else "You need the %s to go further." % required_item.replace("_", " ")
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	label.position = Vector2(-70, -40)
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-70, -40)

	var tween := label.create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

	# Gently push the player back so they don't loop the trigger repeatedly.
	if player.has_method("apply_player_knockback"):
		var away := (player.global_position - global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.UP
		player.apply_player_knockback(away, 90.0, 0.2)
