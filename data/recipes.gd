extends RefCounted

const RECIPES := {
	"plank": {
		"id": "plank",
		"inputs": {"log": 2},
		"output": {"plank": 1},
		"craft_time": 4.0,
		"xp_reward": {"craft": 4.0}
	},
	"tonic": {
		"id": "tonic",
		"inputs": {"herb": 3},
		"output": {"potion": 1},
		"craft_time": 5.0,
		"xp_reward": {"craft": 6.0}
	}
}

func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})
