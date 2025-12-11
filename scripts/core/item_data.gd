extends RefCounted
class_name ItemData

var id: String
var name: String
var item_type: String
var rarity: String
var value := 1
var stats_bonus := {}
var stackable := true
var max_stack := 99

func _init(data: Dictionary = {}):
	id = data.get("id", "")
	name = data.get("name", id)
	item_type = data.get("type", "material")
	rarity = data.get("rarity", "common")
	value = data.get("value", 1)
	stats_bonus = data.get("stats_bonus", {})
	stackable = data.get("stackable", true)
	max_stack = data.get("max_stack", 99)
