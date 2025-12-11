extends RefCounted

# Structured skill registry by category.
const SKILLS := {
	"combat": [
		{"id": "combat.swordsmanship"},
		{"id": "combat.archery"},
		{"id": "combat.unarmed"}
	],
	"harvest": [
		{"id": "harvest.fishing"},
		{"id": "harvest.mining"},
		{"id": "harvest.woodcutting"},
		{"id": "harvest.foraging"},
		{"id": "harvest.hunting"}
	],
	"craft": [
		{"id": "craft.crafting"}
	]
}

static func all_ids() -> Array:
	var ids: Array = []
	for category in SKILLS.keys():
		for entry in SKILLS[category]:
			ids.append(entry.get("id", ""))
	ids = ids.filter(func(id): return id != "")
	return ids
