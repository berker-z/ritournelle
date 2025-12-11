extends RefCounted

# Each submap has an array of nodes with distance growing from entrance.
const MAPS := {
	"town": [],
	"lake": [
		{"id": "lake_shore", "submap": "lake", "type": "harvest", "tier": 1, "distance": 1, "energy_cost": 2, "rewards": [{"item_id": "herb", "min": 1, "max": 2}], "xp_reward": {"gather": 3}, "damage_range": [0, 0]},
		{"id": "reeds_edge", "submap": "lake", "type": "harvest", "tier": 1, "distance": 2, "energy_cost": 4, "rewards": [{"item_id": "herb", "min": 2, "max": 3}], "xp_reward": {"gather": 4}, "damage_range": [0, 0]},
		{"id": "fishing_dock", "submap": "lake", "type": "mixed", "tier": 1, "distance": 3, "energy_cost": 6, "rewards": [{"item_id": "herb", "min": 1, "max": 3}], "xp_reward": {"gather": 4, "combat": 2}, "damage_range": [0, 1]},
		{"id": "islet_crossing", "submap": "lake", "type": "mixed", "tier": 2, "distance": 4, "energy_cost": 8, "rewards": [{"item_id": "herb", "min": 2, "max": 3}, {"item_id": "ore", "min": 0, "max": 1}], "xp_reward": {"gather": 5, "combat": 3}, "damage_range": [1, 2]},
		{"id": "deepwater", "submap": "lake", "type": "combat", "tier": 2, "distance": 5, "energy_cost": 10, "rewards": [{"item_id": "scrap", "min": 1, "max": 2}, {"item_id": "ore", "min": 1, "max": 1}], "xp_reward": {"combat": 6}, "damage_range": [1, 3]}
	],
	"forest": [
		{"id": "forest_edge", "submap": "forest", "type": "harvest", "tier": 1, "distance": 1, "energy_cost": 2, "rewards": [{"item_id": "log", "min": 1, "max": 2}], "xp_reward": {"gather": 3}, "damage_range": [0, 0]},
		{"id": "mushroom_grove", "submap": "forest", "type": "harvest", "tier": 1, "distance": 2, "energy_cost": 4, "rewards": [{"item_id": "herb", "min": 1, "max": 2}], "xp_reward": {"gather": 4}, "damage_range": [0, 0]},
		{"id": "bandit_path", "submap": "forest", "type": "mixed", "tier": 1, "distance": 3, "energy_cost": 6, "rewards": [{"item_id": "scrap", "min": 1, "max": 2}], "xp_reward": {"combat": 4}, "damage_range": [1, 2]},
		{"id": "old_growth", "submap": "forest", "type": "harvest", "tier": 2, "distance": 4, "energy_cost": 8, "rewards": [{"item_id": "log", "min": 2, "max": 3}], "xp_reward": {"gather": 6}, "damage_range": [0, 1]},
		{"id": "beast_den", "submap": "forest", "type": "combat", "tier": 2, "distance": 5, "energy_cost": 10, "rewards": [{"item_id": "scrap", "min": 2, "max": 3}], "xp_reward": {"combat": 7}, "damage_range": [2, 4]}
	],
	"mountain": [
		{"id": "foothills", "submap": "mountain", "type": "harvest", "tier": 1, "distance": 1, "energy_cost": 2, "rewards": [{"item_id": "ore", "min": 1, "max": 1}], "xp_reward": {"gather": 3}, "damage_range": [0, 0]},
		{"id": "switchbacks", "submap": "mountain", "type": "mixed", "tier": 1, "distance": 2, "energy_cost": 4, "rewards": [{"item_id": "ore", "min": 1, "max": 2}], "xp_reward": {"gather": 4, "combat": 2}, "damage_range": [1, 2]},
		{"id": "cliffside", "submap": "mountain", "type": "mixed", "tier": 2, "distance": 3, "energy_cost": 6, "rewards": [{"item_id": "ore", "min": 1, "max": 2}, {"item_id": "scrap", "min": 1, "max": 1}], "xp_reward": {"gather": 5, "combat": 3}, "damage_range": [1, 3]},
		{"id": "mineshaft", "submap": "mountain", "type": "harvest", "tier": 2, "distance": 4, "energy_cost": 8, "rewards": [{"item_id": "ore", "min": 2, "max": 3}], "xp_reward": {"gather": 7}, "damage_range": [0, 2]},
		{"id": "peak_pass", "submap": "mountain", "type": "combat", "tier": 2, "distance": 5, "energy_cost": 10, "rewards": [{"item_id": "ore", "min": 1, "max": 2}, {"item_id": "scrap", "min": 1, "max": 2}], "xp_reward": {"combat": 8}, "damage_range": [2, 4]}
	]
}

func get_maps() -> Dictionary:
	return MAPS
