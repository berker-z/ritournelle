extends RefCounted
class_name Character

const Skill = preload("res://scripts/core/skill.gd")
const Stats = preload("res://scripts/core/stats.gd")
const Inventory = preload("res://scripts/core/inventory.gd")

var name := "Wanderer"
var background := "wanderer"
var stats := Stats.new()
var skills: Dictionary = {
	"combat": Skill.new("combat"),
	"gather": Skill.new("gather"),
	"craft": Skill.new("craft")
}
var inventory := Inventory.new()
var location := "town"

static func new_with_background(char_name: String, bg: String) -> Character:
	var character = Character.new()
	character.name = char_name
	character.background = bg
	character._apply_background(bg)
	return character

func _apply_background(bg: String):
	match bg:
		"harvester":
			skills["gather"].level = 1
		"fighter":
			skills["combat"].level = 1
		_:
			pass
	# start with full energy for new backgrounds
	stats.energy = stats.energy_max

func rest():
	stats.rest()

func apply_rewards(rewards: Dictionary) -> Dictionary:
	var log: Array = []
	if rewards.has("items"):
		for item_id in rewards["items"].keys():
			var amount: int = int(rewards["items"][item_id])
			inventory.add(item_id, amount)
			log.append("Gained %s x%d" % [item_id, amount])
	if rewards.has("xp"):
		for skill_id in rewards["xp"].keys():
			if skills.has(skill_id):
				var amount = float(rewards["xp"][skill_id])
				var result = skills[skill_id].add_xp(amount)
				log.append("XP %s +%.1f (Lv %d)" % [skill_id, amount, result["level"]])
	if rewards.has("hp"):
		stats.hp = clamp(stats.hp + int(rewards["hp"]), 0, stats.hp_max)
	if rewards.has("energy"):
		stats.energy = clamp(stats.energy + int(rewards["energy"]), 0, stats.energy_max)
	return {"log": log}

func is_down() -> bool:
	return stats.hp <= 0

func to_dict() -> Dictionary:
	var skills_data: Dictionary = {}
	for skill_id in skills.keys():
		skills_data[skill_id] = skills[skill_id].to_dict()
	return {
		"name": name,
		"background": background,
		"stats": stats.to_dict(),
		"skills": skills_data,
		"inventory": inventory.to_dict(),
		"location": location
	}

static func from_dict(data: Dictionary) -> Character:
	var c = Character.new()
	c.name = data.get("name", "Wanderer")
	c.background = data.get("background", "wanderer")
	c.stats = Stats.from_dict(data.get("stats", {}))
	c.inventory = Inventory.from_dict(data.get("inventory", {}))
	c.location = data.get("location", "town")
	c.skills = {}
	for skill_id in data.get("skills", {}).keys():
		var skill_data: Dictionary = data["skills"][skill_id]
		c.skills[skill_id] = Skill.from_dict(skill_data)
	# ensure defaults exist
	if not c.skills.has("combat"):
		c.skills["combat"] = Skill.new("combat")
	if not c.skills.has("gather"):
		c.skills["gather"] = Skill.new("gather")
	if not c.skills.has("craft"):
		c.skills["craft"] = Skill.new("craft")
	return c
