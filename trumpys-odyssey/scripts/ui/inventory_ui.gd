# inventory_ui.gd
# Secret inventory UI - shows every collected secret grouped by rarity,
# with its effect described. Toggled with the "inventory" action.
#
# No icon art yet, so each row uses a rarity-colored swatch in place of
# the SNES icon described in the Game Bible / secrets_101.json icon_prompt
# field - swap ColorRect for TextureRect once real icons exist.

extends Control

const RARITY_ORDER := ["Mythic", "Legendary", "Epic", "Rare"]
const RARITY_COLORS := {
	"Rare": Color(0.75, 0.75, 0.8),
	"Epic": Color(0.64, 0.35, 0.94),
	"Legendary": Color(1.0, 0.6, 0.0),
	"Mythic": Color(1.0, 0.2, 0.2),
}

@onready var list_container: VBoxContainer = $Panel/ScrollContainer/VBox
@onready var progress_label: Label = $Panel/ProgressLabel

func _ready() -> void:
	visible = false
	SecretsDatabase.secret_collected.connect(func(_s): _refresh())
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		visible = not visible
		if visible:
			_refresh()

func _refresh() -> void:
	progress_label.text = "SECRET INVENTORY - %s found" % SecretsDatabase.progress_text()

	for child in list_container.get_children():
		child.queue_free()

	var grouped := SecretsDatabase.get_collected_by_rarity()

	if SecretsDatabase.collected_ids.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No secrets yet. Find cracked walls and bomb them!"
		list_container.add_child(empty_label)
		return

	for rarity in RARITY_ORDER:
		var secrets: Array = grouped.get(rarity, [])
		if secrets.is_empty():
			continue

		var header := Label.new()
		header.text = "%s (%d)" % [rarity, secrets.size()]
		header.add_theme_color_override("font_color", RARITY_COLORS[rarity])
		list_container.add_child(header)

		for secret in secrets:
			var row := HBoxContainer.new()

			var swatch := ColorRect.new()
			swatch.custom_minimum_size = Vector2(16, 16)
			swatch.color = RARITY_COLORS[rarity]
			row.add_child(swatch)

			var label := Label.new()
			label.text = "  %s - %s (%d%% %s)" % [secret["name"], secret["effect_type"], secret["percent"], "stack"]
			row.add_child(label)

			list_container.add_child(row)
