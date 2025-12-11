extends RefCounted
class_name Recipe

var id: String
var inputs: Dictionary = {}
var output: Dictionary = {}
var craft_time: float = 3.0
var xp_reward := {"craft": 2.0}

func _init(data: Dictionary = {}):
	id = data.get("id", "")
	inputs = data.get("inputs", {})
	output = data.get("output", {})
	craft_time = float(data.get("craft_time", 3.0))
	xp_reward = data.get("xp_reward", {"craft": 2.0})
