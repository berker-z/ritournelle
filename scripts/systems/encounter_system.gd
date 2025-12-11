extends Node

const Character = preload("res://scripts/core/character.gd")
const MapNode = preload("res://scripts/core/map_node.gd")

func resolve(node: MapNode, character: Character) -> Dictionary:
	var log: Array[String] = []
	if not character.stats.consume_energy(node.energy_cost):
		return {"log": ["Too tired to act. Need %.1f energy." % node.energy_cost], "down": character.is_down()}

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
			log.append("Took %d damage." % damage_taken)
			if down:
				log.append("You are down. Rest to recover.")

	var rewards: Dictionary = {}
	if gained_items.size() > 0:
		rewards["items"] = gained_items
	if node.xp_reward.size() > 0:
		rewards["xp"] = node.xp_reward

	if rewards.size() > 0:
		var reward_log = character.apply_rewards(rewards)["log"]
		log.append_array(reward_log)

	if gained_items.is_empty() and damage_taken == 0:
		log.append("Nothing happened at %s." % node.id)

	return {
		"log": log,
		"down": character.is_down(),
		"energy_spent": node.energy_cost,
		"damage": damage_taken,
		"items": gained_items
	}
