# hud.gd
# Always-on HUD: hearts, bombs, secrets progress, gems.
# Attach to the HUD CanvasLayer in Main/World scenes.

extends CanvasLayer

@onready var health_label: Label = $Panel/VBox/HealthLabel
@onready var bombs_label: Label = $Panel/VBox/BombsLabel
@onready var secrets_label: Label = $Panel/VBox/SecretsLabel
@onready var gems_label: Label = $Panel/VBox/GemsLabel
@onready var zeus_label: Label = $Panel/VBox/ZeusLabel

var player: Player = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.bombs_changed.connect(_on_bombs_changed)
		_on_health_changed(player.current_health)
		_on_bombs_changed(player.bombs)

	SecretsDatabase.secret_collected.connect(_on_secret_collected)
	GameState.gems_changed.connect(_on_gems_changed)
	GameState.zeus_mode_changed.connect(_on_zeus_mode_changed)

	_refresh_secrets_label()
	_on_gems_changed(GameState.gems)
	_on_zeus_mode_changed(GameState.zeus_mode)

func _on_health_changed(new_health: int) -> void:
	var hearts := ceil(new_health / 2.0)
	health_label.text = "Health: %d" % new_health if not player else "Hearts: %d/%d" % [hearts, ceil(player.max_health / 2.0)]

func _on_bombs_changed(count: int) -> void:
	var capacity := player.get_bomb_capacity() if player else count
	bombs_label.text = "Bombs: %d/%d" % [count, capacity]

func _on_secret_collected(_secret: Dictionary) -> void:
	_refresh_secrets_label()

func _refresh_secrets_label() -> void:
	secrets_label.text = "Secrets: %s" % SecretsDatabase.progress_text()

func _on_gems_changed(total: int) -> void:
	gems_label.text = "Gems: %d/%d" % [total, GameState.gem_pouch_capacity]

func _on_zeus_mode_changed(active: bool) -> void:
	zeus_label.visible = active
	if active:
		zeus_label.text = "ZEUS MODE"
