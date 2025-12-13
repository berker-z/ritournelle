class_name ActionService extends RefCounted

const MapNode = preload("res://scripts/core/map_node.gd")
const Recipe = preload("res://scripts/core/recipe.gd")
const ItemsData = preload("res://data/items.gd")
const RecipesData = preload("res://data/recipes.gd")
const EncounterOutcome = preload("res://scripts/core/encounter_outcome.gd")
const CraftingStartOutcome = preload("res://scripts/core/crafting_outcome.gd")
# EncounterSystem and CraftingSystem are Autoloads.

var recipes: Dictionary = {}

func _init():
	_load_data()

func _load_data():
	for recipe_id in RecipesData.RECIPES.keys():
		recipes[recipe_id] = Recipe.new(RecipesData.RECIPES[recipe_id])

func act_in_node(player, base_node: MapNode, submap: String, action_type: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs
	if base_node == null:
		logs.append("Node data missing.")
		return logs

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
		logs.append("Unknown action.")
		return logs

	var result: EncounterOutcome = EncounterSystem.resolve(node, player)
	var raw_log = result.log
	for entry in raw_log:
		logs.append(str(entry))
	return logs

func rest(player) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs
	if not player.inventory.has("camping_supplies", 1):
		logs.append("No camping supplies to rest.")
		return logs
	player.inventory.remove("camping_supplies", 1)
	player.rest()
	logs.append("Rested using 1 camping supplies. HP %d/%d | Energy %.1f/%.1f" % [player.stats.hp, player.stats.hp_max, player.stats.energy, player.stats.energy_max])
	return logs

func start_craft(player, recipe_id: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs
	if not recipes.has(recipe_id):
		logs.append("No recipe named %s." % recipe_id)
		return logs
	var outcome: CraftingStartOutcome = CraftingSystem.start_job(recipes[recipe_id], player)
	var raw_log = outcome.log
	for entry in raw_log:
		logs.append(str(entry))
	return logs

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
