# boss_enemy.gd
# A world's dungeon boss. Same patrol/chase/confused AI as EnemyBase, just
# tougher, and on death it unlocks the progression item that opens the
# gate to the next world (see GameState.unlocked_items and
# scripts/entities/screen_exit.gd's required_item gate).

extends EnemyBase
class_name BossEnemy

@export var drop_item_key: String = ""
@export var boss_name: String = "Boss"

func die() -> void:
	if drop_item_key != "":
		GameState.unlock_item(drop_item_key)
		_show_item_get_text()
	super.die()

func _show_item_get_text() -> void:
	var label := Label.new()
	label.text = "%s defeated!\nGot the %s!" % [boss_name, drop_item_key.replace("_", " ")]
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-80, -60)
	label.size = Vector2(160, 50)
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-80, -60)

	var tween := label.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
