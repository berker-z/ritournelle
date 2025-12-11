extends RefCounted
class_name Character

const Skill = preload("res://scripts/core/skill.gd")
const Stats = preload("res://scripts/core/stats.gd")
const Inventory = preload("res://scripts/core/inventory.gd")
const SkillsData = preload("res://data/skills.gd")
const ItemsData = preload("res://data/items.gd")
const EQUIPMENT_SLOTS := ["weapon", "hat", "armor"]

var name := "Wanderer"
var background := "wanderer"
var stats := Stats.new()
var skills: Dictionary = {}
var inventory := Inventory.new()
var location := "town"
var equipped := {
	"weapon": "",
	"hat": "",
	"armor": ""
}

static func new_with_background(char_name: String, bg: String) -> Character:
	var character = Character.new()
	character._init_skills()
	character.name = char_name
	character.background = bg
	character._apply_background(bg)
	return character

func _init_skills():
	for id in SkillsData.all_ids():
		if not skills.has(id):
			skills[id] = Skill.new(id)

func _apply_background(bg: String):
	match bg:
		"harvester":
			skills["combat.swordsmanship"].level = 1
		"fighter":
			skills["combat.swordsmanship"].level = 1
		_:
			pass
	# start with full energy for new backgrounds
	stats.energy = stats.energy_max

func equip_weapon(item_id: String) -> String:
	return equip_item(item_id)

func equip_item(item_id: String) -> String:
	var item_meta = ItemsData.get_item_static(item_id)
	if item_meta.is_empty():
		return "Item %s not found." % item_id
	var slot = ItemsData.slot_for(item_meta)
	if slot == "":
		return "%s cannot be equipped." % item_id
	if not EQUIPMENT_SLOTS.has(slot):
		return "Slot %s is not supported yet." % slot
	if equipped.get(slot, "") == item_id and not inventory.has(item_id, 1):
		return "%s already equipped." % item_id
	if not inventory.has(item_id, 1):
		return "No %s to equip." % item_id
	# return currently equipped item in that slot to inventory
	if equipped.get(slot, "") != "":
		inventory.add(equipped[slot], 1)
	inventory.remove(item_id, 1)
	equipped[slot] = item_id
	return "Equipped %s to %s." % [item_id, slot]

func unequip_slot(slot: String) -> String:
	if not equipped.has(slot):
		return "Unknown slot %s." % slot
	if equipped[slot] == "":
		return "Nothing equipped in %s." % slot
	var item_id = equipped[slot]
	inventory.add(item_id, 1)
	equipped[slot] = ""
	return "Unequipped %s from %s." % [item_id, slot]

func get_equipped_weapon() -> String:
	return equipped.get("weapon", "")

func get_equipped_items() -> Dictionary:
	return equipped.duplicate()

func rest():
	stats.rest()

func apply_rewards(rewards: Dictionary) -> Dictionary:
	var log: Array[String] = []
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
		"location": location,
		"equipped": equipped
	}

static func from_dict(data: Dictionary) -> Character:
	var c = Character.new()
	c._init_skills()
	c.name = data.get("name", "Wanderer")
	c.background = data.get("background", "wanderer")
	c.stats = Stats.from_dict(data.get("stats", {}))
	c.inventory = Inventory.from_dict(data.get("inventory", {}))
	c.location = data.get("location", "town")
	c.equipped = data.get("equipped", {"weapon": ""})
	# ensure all slots exist
	for slot in EQUIPMENT_SLOTS:
		if not c.equipped.has(slot):
			c.equipped[slot] = ""
	c.skills = {}
	for skill_id in data.get("skills", {}).keys():
		var skill_data: Dictionary = data["skills"][skill_id]
		c.skills[skill_id] = Skill.from_dict(skill_data)
	# ensure defaults exist from data file
	for id in SkillsData.all_ids():
		if not c.skills.has(id):
			c.skills[id] = Skill.new(id)
	return c
