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
	}
}

func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})
