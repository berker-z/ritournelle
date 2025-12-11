extends RefCounted
class_name MapNode

var id: String
var node_type: String = "harvest"
var tier: int = 1
var energy_cost: float = 2.0
var rewards: Array = [] # [{item_id, min, max}]
var xp_reward: Dictionary = {} # skill -> amount
var damage_range: Vector2 = Vector2(0, 0) # for combat/mixed

func _init(data: Dictionary = {}):
	id = data.get("id", "")
	node_type = data.get("type", "harvest")
	tier = int(data.get("tier", 1))
	energy_cost = float(data.get("energy_cost", 2.0))
	rewards = data.get("rewards", [])
	xp_reward = data.get("xp_reward", {})
	var dmg = data.get("damage_range", Vector2.ZERO)
	if dmg is Array and dmg.size() >= 2:
		damage_range = Vector2(dmg[0], dmg[1])
	elif dmg is Vector2:
		damage_range = dmg
