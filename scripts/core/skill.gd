extends RefCounted
class_name Skill

var id: String
var level := 0
var xp := 0.0
var xp_to_next := 10.0

func _init(_id: String):
	id = _id

func add_xp(amount: float) -> Dictionary:
	xp += amount
	var leveled := false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next *= 1.25
		leveled = true
	return {
		"leveled": leveled,
		"level": level,
		"xp": xp,
		"xp_to_next": xp_to_next
	}

func to_dict() -> Dictionary:
	return {
		"id": id,
		"level": level,
		"xp": xp,
		"xp_to_next": xp_to_next
	}

static func from_dict(data: Dictionary) -> Skill:
	var skill = Skill.new(data.get("id", ""))
	skill.level = int(data.get("level", 1))
	skill.xp = float(data.get("xp", 0.0))
	skill.xp_to_next = float(data.get("xp_to_next", 10.0))
	return skill
