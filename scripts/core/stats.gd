extends RefCounted
class_name Stats

var hp_max := 20
var hp := 20
var energy_max := 100
var energy := 100
var power := 1
var defense := 0
var gather := 1
var craft := 1
var speed := 1.0

func rest():
	hp = hp_max
	energy = energy_max

func apply_damage(amount: float) -> bool:
	hp = max(0, hp - amount)
	return hp <= 0

func consume_energy(cost: float) -> bool:
	if energy < cost:
		return false
	energy -= cost
	return true

func apply_bonus(bonus: Dictionary):
	power += bonus.get("power", 0)
	defense += bonus.get("defense", 0)
	gather += bonus.get("gather", 0)
	craft += bonus.get("craft", 0)
	speed += bonus.get("speed", 0.0)
	hp_max += bonus.get("hp_max", 0)
	energy_max += bonus.get("energy_max", 0)
	hp = min(hp, hp_max)
	energy = min(energy, energy_max)

func to_dict() -> Dictionary:
	return {
		"hp_max": hp_max,
		"hp": hp,
		"energy_max": energy_max,
		"energy": energy,
		"power": power,
		"defense": defense,
		"gather": gather,
		"craft": craft,
		"speed": speed
	}

static func from_dict(data: Dictionary) -> Stats:
	var stats = Stats.new()
	stats.hp_max = int(data.get("hp_max", 20))
	stats.hp = int(data.get("hp", stats.hp_max))
	stats.energy_max = int(data.get("energy_max", 10))
	stats.energy = float(data.get("energy", stats.energy_max))
	stats.power = int(data.get("power", 1))
	stats.defense = int(data.get("defense", 0))
	stats.gather = int(data.get("gather", 1))
	stats.craft = int(data.get("craft", 1))
	stats.speed = float(data.get("speed", 1.0))
	return stats
