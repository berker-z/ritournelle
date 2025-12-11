extends RefCounted

const NODES := {
	"meadow": {
		"id": "meadow",
		"type": "harvest",
		"tier": 1,
		"energy_cost": 2.0,
		"rewards": [
			{"item_id": "log", "min": 1, "max": 2},
			{"item_id": "herb", "min": 0, "max": 2}
		],
		"xp_reward": {"gather": 4.0},
		"damage_range": [0, 0]
	},
	"camp": {
		"id": "camp",
		"type": "combat",
		"tier": 1,
		"energy_cost": 3.0,
		"rewards": [
			{"item_id": "scrap", "min": 1, "max": 2},
			{"item_id": "ore", "min": 0, "max": 1}
		],
		"xp_reward": {"combat": 6.0},
		"damage_range": [1, 4]
	},
	"grove": {
		"id": "grove",
		"type": "mixed",
		"tier": 2,
		"energy_cost": 4.0,
		"rewards": [
			{"item_id": "log", "min": 1, "max": 2},
			{"item_id": "herb", "min": 0, "max": 2},
			{"item_id": "ore", "min": 0, "max": 1}
		],
		"xp_reward": {"gather": 4.0, "combat": 5.0},
		"damage_range": [1, 3]
	}
}

func get_node(node_id: String) -> Dictionary:
	return NODES.get(node_id, {})
