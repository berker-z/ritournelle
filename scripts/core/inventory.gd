extends RefCounted
class_name Inventory

var items: Dictionary = {}

func add(item_id: String, count: int = 1):
	items[item_id] = items.get(item_id, 0) + count

func remove(item_id: String, count: int = 1) -> bool:
	if not items.has(item_id):
		return false
	if items[item_id] < count:
		return false
	items[item_id] -= count
	if items[item_id] <= 0:
		items.erase(item_id)
	return true

func has(item_id: String, count: int = 1) -> bool:
	return items.get(item_id, 0) >= count

func can_afford(requirements: Dictionary) -> bool:
	for item_id in requirements.keys():
		if items.get(item_id, 0) < int(requirements[item_id]):
			return false
	return true

func deduct(requirements: Dictionary) -> bool:
	if not can_afford(requirements):
		return false
	for item_id in requirements.keys():
		remove(item_id, int(requirements[item_id]))
	return true

func to_lines() -> Array:
	var lines: Array = []
	for item_id in items.keys():
		lines.append("%s x%d" % [item_id, items[item_id]])
	lines.sort()
	return lines

func to_dict() -> Dictionary:
	return {"items": items.duplicate()}

static func from_dict(data: Dictionary) -> Inventory:
	var inv = Inventory.new()
	inv.items = data.get("items", {}).duplicate()
	return inv
