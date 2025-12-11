extends RefCounted

const ITEMS := {
	"log": {
		"id": "log",
		"name": "Wood Log",
		"type": "material",
		"rarity": "common",
		"value": 1
	},
	"herb": {
		"id": "herb",
		"name": "Wild Herb",
		"type": "material",
		"rarity": "common",
		"value": 1
	},
	"ore": {
		"id": "ore",
		"name": "Copper Ore",
		"type": "material",
		"rarity": "common",
		"value": 2
	},
	"plank": {
		"id": "plank",
		"name": "Wood Plank",
		"type": "material",
		"rarity": "common",
		"value": 3
	},
	"potion": {
		"id": "potion",
		"name": "Small Tonic",
		"type": "consumable",
		"rarity": "uncommon",
		"value": 5
	},
	"scrap": {
		"id": "scrap",
		"name": "Dented Scrap",
		"type": "material",
		"rarity": "common",
		"value": 1
	},
	"camping_supplies": {
		"id": "camping_supplies",
		"name": "Camping Supplies",
		"type": "consumable",
		"rarity": "common",
		"value": 1,
		"stackable": true,
		"max_stack": 999
	},
	"arrow": {
		"id": "arrow",
		"name": "Simple Arrow",
		"type": "projectile",
		"rarity": "common",
		"value": 1,
		"stackable": true,
		"max_stack": 999
	},
	"sword": {
		"id": "sword",
		"name": "Plain Sword",
		"type": "weapon",
		"rarity": "common",
		"value": 10,
		"skill": "combat.swordsmanship",
		"stackable": false,
		"max_stack": 1,
		"slot": "weapon"
	},
	"rusty_sword": {
		"id": "rusty_sword",
		"name": "Rusty Sword",
		"type": "weapon",
		"rarity": "common",
		"value": 5,
		"skill": "combat.swordsmanship",
		"stackable": false,
		"max_stack": 1,
		"slot": "weapon"
	},
	"wooden_sword": {
		"id": "wooden_sword",
		"name": "Wooden Sword",
		"type": "weapon",
		"rarity": "common",
		"value": 4,
		"skill": "combat.swordsmanship",
		"stackable": false,
		"max_stack": 1,
		"slot": "weapon"
	},
	"leather_hat": {
		"id": "leather_hat",
		"name": "Leather Hat",
		"type": "hat",
		"rarity": "common",
		"value": 2,
		"stackable": false,
		"max_stack": 1,
		"slot": "hat"
	},
	"leather_armor": {
		"id": "leather_armor",
		"name": "Leather Armor",
		"type": "armor",
		"rarity": "common",
		"value": 6,
		"stackable": false,
		"max_stack": 1,
		"slot": "armor"
	}
}

func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func get_item_static(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func is_equipment(item_meta: Dictionary) -> bool:
	var slot = item_meta.get("slot", "")
	if slot != "":
		return true
	var t = item_meta.get("type", "")
	return t in ["weapon", "armor", "hat", "projectile"]

static func slot_for(item_meta: Dictionary) -> String:
	return item_meta.get("slot", "")
