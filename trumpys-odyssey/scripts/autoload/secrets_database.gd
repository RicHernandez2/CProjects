# secrets_database.gd (autoload singleton: SecretsDatabase)
# Loads the 101 secrets from data/secrets_101.json, tracks which the player
# has collected, and is the single source of truth for stacked stat totals
# (mitigation %, speed boosts, capacity boosts, etc). Collecting all 101
# unlocks Zeus Mode.

extends Node

signal secret_collected(secret: Dictionary)
signal all_secrets_complete

const DATA_PATH := "res://data/secrets_101.json"

var secrets_by_id: Dictionary = {}
var collected_ids: Array[int] = []

# effect_key -> summed fractional bonus (25% secret contributes 0.25)
var stat_totals: Dictionary = {}

func _ready() -> void:
	_load_secrets()

func _load_secrets() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("SecretsDatabase: missing %s" % DATA_PATH)
		return

	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("SecretsDatabase: secrets_101.json did not parse to an array")
		return

	for entry in parsed:
		secrets_by_id[int(entry["id"])] = entry

func total_count() -> int:
	return secrets_by_id.size()

func is_collected(id: int) -> bool:
	return collected_ids.has(id)

func collect_secret(id: int) -> void:
	if is_collected(id):
		return
	if not secrets_by_id.has(id):
		push_warning("SecretsDatabase: unknown secret id %d" % id)
		return

	collected_ids.append(id)
	var secret: Dictionary = secrets_by_id[id]

	var key: String = secret["effect_key"]
	var fraction: float = float(secret["percent"]) / 100.0
	stat_totals[key] = stat_totals.get(key, 0.0) + fraction

	secret_collected.emit(secret)

	if collected_ids.size() >= total_count():
		GameState.set_zeus_mode(true)
		all_secrets_complete.emit()

func get_stat(effect_key: String) -> float:
	if GameState.zeus_mode:
		# Zeus Mode: every stacking bonus effectively maxed out.
		return 999.0
	return stat_totals.get(effect_key, 0.0)

func get_collected_by_rarity() -> Dictionary:
	var out := {"Rare": [], "Epic": [], "Legendary": [], "Mythic": []}
	for id in collected_ids:
		var secret: Dictionary = secrets_by_id[id]
		out[secret["rarity"]].append(secret)
	return out

func progress_text() -> String:
	return "%d/%d" % [collected_ids.size(), total_count()]
