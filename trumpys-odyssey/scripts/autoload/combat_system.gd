# combat_system.gd (autoload singleton: CombatSystem)
# Centralized combat: damage application, knockback, over-mitigation
# healing (see SecretsDatabase), and impact visual effects.
#
# Ported from the original standalone CombatSystem.gd design doc, wired up
# to SecretsDatabase as the single source of truth for stacked mitigation.

extends Node

# === DAMAGE SYSTEM ===
func apply_damage(target: Node, amount: int, damage_type: String = "physical", attacker: Node = null) -> void:
	if not target or not target.has_method("take_damage"):
		return

	target.take_damage(amount, damage_type)

	# Knockback
	if attacker and target.has_method("apply_knockback"):
		var direction: Vector2 = (target.global_position - attacker.global_position).normalized()
		var force := get_knockback_force(damage_type, amount)
		target.apply_knockback(direction, force, 0.35)

	# Spawn impact dust
	spawn_impact_dust(target.global_position)

# === OVER-MITIGATION HEALING (from stacked secrets) ===
func check_over_mitigation_heal(player: Node, amount: int, damage_type: String) -> void:
	if not player or not player.has_method("heal"):
		return

	var reduction: float = SecretsDatabase.get_stat(damage_type)
	if reduction > 1.0:
		var excess: float = reduction - 1.0
		var heal_amount: int = int(amount * excess)
		if heal_amount > 0:
			player.heal(heal_amount)

			# Trigger enemy confused reaction
			trigger_enemy_confused_reaction(player)

			# Spawn heal text
			spawn_floating_heal_text(player.global_position, heal_amount)

# === KNOCKBACK HELPERS ===
func get_knockback_force(damage_type: String, amount: int) -> float:
	match damage_type:
		"physical":
			return 180 + (amount * 10)
		"fire":
			return 160
		"ice":
			return 140
		"lightning":
			return 200
		_:
			return 150

func apply_player_knockback(player: Node, direction: Vector2, force: float = 140.0, duration: float = 0.25) -> void:
	if player and player.has_method("apply_player_knockback"):
		player.apply_player_knockback(direction, force, duration)

# === VISUAL EFFECTS ===
func spawn_impact_dust(position: Vector2) -> void:
	var dust = preload("res://scenes/effects/ImpactDustEffect.tscn").instantiate()
	dust.global_position = position
	get_tree().current_scene.add_child(dust)

func spawn_floating_heal_text(position: Vector2, amount: int) -> void:
	var heal_text = preload("res://scenes/effects/FloatingHealText.tscn").instantiate()
	heal_text.heal_amount = amount
	heal_text.global_position = position
	get_tree().current_scene.add_child(heal_text)

# === ENEMY REACTION (WTF + Run) ===
func trigger_enemy_confused_reaction(player: Node) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("become_confused"):
			var dist: float = enemy.global_position.distance_to(player.global_position)
			if dist < 180:  # Only nearby enemies react
				enemy.become_confused(2.0)
