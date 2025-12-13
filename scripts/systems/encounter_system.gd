extends Node

const Character = preload("res://scripts/core/character.gd")
const MapNode = preload("res://scripts/core/map_node.gd")
const EncounterOutcome = preload("res://scripts/core/encounter_outcome.gd")

func resolve(node: MapNode, character: Character) -> EncounterOutcome:
	var outcome := EncounterOutcome.new()
	if not character.stats.consume_energy(node.energy_cost):
		outcome.log.append("Too tired to act. Need %.1f energy." % node.energy_cost)
		outcome.down = character.is_down()
		outcome.energy_spent = 0.0
		outcome.damage = 0
		outcome.items = {}
		return outcome

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var gained_items: Dictionary = {}
	for entry in node.rewards:
		var min_amt = int(entry.get("min", 0))
		var max_amt = int(entry.get("max", 0))
		var amount = rng.randi_range(min_amt, max_amt)
		if amount <= 0:
			continue
		var item_id: String = entry.get("item_id", "")
		gained_items[item_id] = gained_items.get(item_id, 0) + amount

	var damage_taken := 0
	if node.node_type != "harvest":
		var dmg_min = int(node.damage_range.x)
		var dmg_max = int(node.damage_range.y)
		damage_taken = max(0, rng.randi_range(dmg_min, dmg_max) + node.tier - character.stats.defense)
		if damage_taken > 0:
			var down = character.stats.apply_damage(damage_taken)
			outcome.log.append("Took %d damage." % damage_taken)
			if down:
				outcome.log.append("You are down. Rest to recover.")

	var rewards: Dictionary = {}
	if gained_items.size() > 0:
		rewards["items"] = gained_items
	if node.xp_reward.size() > 0:
		rewards["xp"] = node.xp_reward

	if rewards.size() > 0:
		var reward_log = character.apply_rewards(rewards)["log"]
		outcome.log.append_array(reward_log)

	if gained_items.is_empty() and damage_taken == 0:
		outcome.log.append("Nothing happened at %s." % node.id)

	outcome.down = character.is_down()
	outcome.energy_spent = node.energy_cost
	outcome.damage = damage_taken
	outcome.items = gained_items
	return outcome
