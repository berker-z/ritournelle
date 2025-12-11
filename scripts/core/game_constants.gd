class_name GameConstants extends RefCounted

const ACTION_HARVEST = "harvest"
const ACTION_COMBAT = "combat"

const SUBMAP_TOWN = "town"
const SUBMAP_LAKE = "lake"
const SUBMAP_FOREST = "forest"
const SUBMAP_MOUNTAIN = "mountain"

const SLOT_WEAPON = "weapon"
const SLOT_HAT = "hat"
const SLOT_ARMOR = "armor"

const SUBMAP_TRAVEL_COSTS := {
	SUBMAP_TOWN: 10.0,
	SUBMAP_LAKE: 10.0,
	SUBMAP_FOREST: 10.0,
	SUBMAP_MOUNTAIN: 10.0
}

const SUBMAP_NODE_COSTS := {
	SUBMAP_TOWN: 0.0,
	SUBMAP_LAKE: 2.0,
	SUBMAP_FOREST: 2.0,
	SUBMAP_MOUNTAIN: 3.0
}

const RECIPE_PLANK = "plank"
