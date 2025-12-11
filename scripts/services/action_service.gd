class_name ActionService extends RefCounted

const MapNode = preload("res://scripts/core/map_node.gd")
const Recipe = preload("res://scripts/core/recipe.gd")
const ItemsData = preload("res://data/items.gd")
const RecipesData = preload("res://data/recipes.gd")
# EncounterSystem and CraftingSystem are Autoloads.

var recipes: Dictionary = {}

func _init():
	_load_data()

func _load_data():
	for recipe_id in RecipesData.RECIPES.keys():
		recipes[recipe_id] = Recipe.new(RecipesData.RECIPES[recipe_id])

func act_in_node(player, base_node: MapNode, submap: String, action_type: String) -> Array[String]:
	if player == null:
		return ["No active character."]
	if base_node == null:
		return ["Node data missing."]
		
	# Create a temporary node instance for the encounter
	var node = MapNode.new(base_node.to_dict())
	
	if action_type == GameConstants.ACTION_HARVEST:
		node.node_type = "harvest"
		node.damage_range = Vector2.ZERO
		node.xp_reward = {_harvest_skill_for_submap(submap): _xp_for_node(node, "gather")}
	elif action_type == GameConstants.ACTION_COMBAT:
		node.node_type = "combat"
		node.xp_reward = {_combat_skill_for_equipped(player): _xp_for_node(node, "combat")}
	else:
		return ["Unknown action."]
		
	var result = EncounterSystem.resolve(node, player)
	return result.get("log", [])

func rest(player) -> Array[String]:
	if player == null:
		return ["No active character."]
	if not player.inventory.has("camping_supplies", 1):
		return ["No camping supplies to rest."]
	player.inventory.remove("camping_supplies", 1)
	player.rest()
	return ["Rested using 1 camping supplies. HP %d/%d | Energy %.1f/%.1f" % [player.stats.hp, player.stats.hp_max, player.stats.energy, player.stats.energy_max]]

func start_craft(player, recipe_id: String) -> Array[String]:
	if player == null:
		return ["No active character."]
	if not recipes.has(recipe_id):
		return ["No recipe named %s." % recipe_id]
	var outcome = CraftingSystem.start_job(recipes[recipe_id], player)
	return outcome.get("log", [])

# Helpers
func _harvest_skill_for_submap(submap: String) -> String:
	match submap:
		GameConstants.SUBMAP_LAKE: return "harvest.fishing"
		GameConstants.SUBMAP_FOREST: return "harvest.woodcutting"
		GameConstants.SUBMAP_MOUNTAIN: return "harvest.mining"
		_: return "harvest.foraging"

func _combat_skill_for_equipped(player) -> String:
	var weapon = player.get_equipped_weapon()
	if weapon == "":
		return "combat.unarmed"
	var item_meta = ItemsData.get_item_static(weapon)
	var skill_id = item_meta.get("skill", "")
	if skill_id != "":
		return skill_id
	return "combat.unarmed"

func _xp_for_node(node: MapNode, kind: String) -> float:
	var total: float = 0.0
	for v in node.xp_reward.values():
		total += float(v)
	if total <= 0:
		total = 5.0
	return total
