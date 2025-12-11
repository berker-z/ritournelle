extends Node

const Character = preload("res://scripts/core/character.gd")
const Account = preload("res://scripts/core/account.gd")
const MapNode = preload("res://scripts/core/map_node.gd")
const Recipe = preload("res://scripts/core/recipe.gd")
const ItemsData = preload("res://data/items.gd")
const RecipesData = preload("res://data/recipes.gd")
const MapsData = preload("res://data/maps.gd")

var account_name: String = ""
var account: Account
var player: Character
var nodes: Dictionary = {}
var recipes: Dictionary = {}
var submap_nodes: Dictionary = {} # submap -> Array[MapNode]
const SUBMAP_TRAVEL_COST := 10.0
const NODE_TRAVEL_COST := 2.0

func _ready():
	_load_data()
	SaveSystem.ensure_base_dir()

func _load_data():
	for submap in MapsData.MAPS.keys():
		submap_nodes[submap] = []
		for node_data in MapsData.MAPS[submap]:
			var node = MapNode.new(node_data)
			submap_nodes[submap].append(node)
			nodes[node.id] = node
		submap_nodes[submap].sort_custom(func(a, b): return a.distance < b.distance)
	for recipe_id in RecipesData.RECIPES.keys():
		recipes[recipe_id] = Recipe.new(RecipesData.RECIPES[recipe_id])

func _seed_inventory(character: Character):
	character.inventory.add("log", 3)
	character.inventory.add("herb", 2)
	character.inventory.add("camping_supplies", 100)

func has_account_selected() -> bool:
	return account != null and not account_name.is_empty()

func has_active_character() -> bool:
	return has_account_selected() and player != null

func list_accounts() -> Array:
	return SaveSystem.list_accounts()

func select_account(name: String) -> Array:
	if name.is_empty():
		return ["Pick an account from the list."]
	if not SaveSystem.list_accounts().has(name):
		return ["Account not found."]
	account_name = name
	account = SaveSystem.load_account(account_name)
	player = null
	CraftingSystem.reset()
	return ["Selected account: %s" % account_name]

func create_account(raw_name: String) -> Array:
	var target_name = SaveSystem.sanitize_name(raw_name, "account")
	var existed = SaveSystem.list_accounts().has(target_name)
	var created_name = SaveSystem.create_account(raw_name)
	account_name = created_name
	account = SaveSystem.load_account(account_name)
	player = null
	CraftingSystem.reset()
	var msg = "Selected existing account: %s" % account_name if existed else "Created account: %s" % account_name
	return [msg]

func get_character_names() -> Array:
	if not has_account_selected():
		return []
	return account.get_character_names()

func list_submaps() -> Array:
	var subs = submap_nodes.keys()
	subs.sort()
	return subs

func list_nodes(submap: String) -> Array:
	if not submap_nodes.has(submap):
		return []
	var ids: Array = []
	var sorted_nodes = submap_nodes[submap].duplicate()
	sorted_nodes.sort_custom(func(a, b): return a.distance < b.distance)
	for node in sorted_nodes:
		ids.append(node.id)
	return ids

func create_character(name: String, background: String) -> Array:
	if not has_account_selected():
		return ["Select or create an account first."]
	var safe_name = name.strip_edges()
	if safe_name.is_empty():
		safe_name = "Wanderer"
	var file_stub = SaveSystem.sanitize_name(safe_name, "char")
	for existing_name in get_character_names():
		if existing_name == safe_name:
			return ["Character with that name already exists."]
		if SaveSystem.sanitize_name(existing_name, "char") == file_stub:
			return ["Character with that name already exists."]
	var character = Character.new_with_background(safe_name, background)
	_seed_inventory(character)
	account.characters.append(character)
	player = character
	player.location = "town"
	SaveSystem.save_character(account_name, character)
	CraftingSystem.reset()
	return ["Created %s (%s) and set active." % [safe_name, background]]

func select_character_by_name(character_name: String) -> Array:
	if not has_account_selected():
		return ["Select or create an account first."]
	for c in account.characters:
		if c.name == character_name:
			player = c
			CraftingSystem.reset()
			return ["Selected %s." % c.name]
	return ["Character not found."]

func delete_character(character_name: String) -> Array:
	if not has_account_selected():
		return ["Select or create an account first."]
	for c in account.characters:
		if c.name == character_name:
			account.characters.erase(c)
			SaveSystem.delete_character(account_name, character_name)
			if player == c:
				player = null
				CraftingSystem.reset()
			return ["Deleted %s." % character_name]
	return ["Character not found."]

func get_inventory_lines() -> Array:
	if player == null:
		return []
	return player.inventory.to_lines()

func rest() -> Array:
	if player == null:
		return ["No active character. Create or select one first."]
	if not player.inventory.has("camping_supplies", 1):
		return ["No camping supplies to rest."]
	player.inventory.remove("camping_supplies", 1)
	player.rest()
	SaveSystem.save_character(account_name, player)
	return ["Rested using 1 camping supplies. HP %d/%d | Energy %.1f/%.1f" % [player.stats.hp, player.stats.hp_max, player.stats.energy, player.stats.energy_max]]

func start_craft(recipe_id: String) -> Array:
	if player == null:
		return ["No active character. Create or select one first."]
	if not recipes.has(recipe_id):
		return ["No recipe named %s." % recipe_id]
	var outcome = CraftingSystem.start_job(recipes[recipe_id], player)
	SaveSystem.save_character(account_name, player)
	return outcome.get("log", [])

func tick(delta: float) -> Array:
	if player == null:
		return []
	var logs: Array = []
	for entry in CraftingSystem.tick(delta, player):
		logs.append(entry)
	if logs.size() > 0:
		SaveSystem.save_character(account_name, player)
	return logs

func get_active_name() -> String:
	if not has_active_character():
		return ""
	return player.name

func get_location_text() -> String:
	if player == null:
		return "Unknown"
	return player.location

func get_current_submap() -> String:
	if player == null:
		return ""
	var parts = player.location.split(">")
	return parts[0]

func get_current_node() -> String:
	if player == null:
		return ""
	var parts = player.location.split(">")
	return parts[1] if parts.size() > 1 else ""

func travel_to_submap(submap: String) -> Array:
	if player == null:
		return ["No active character. Create or select one first."]
	if submap == "":
		return ["Choose a submap."]
	var current_submap = get_current_submap()
	if current_submap == submap and get_current_node() == "":
		return ["Already in %s." % submap]
	var exit_cost = _exit_cost_from_current()
	var submap_cost = SUBMAP_TRAVEL_COST if current_submap != submap else 0.0
	var total_cost = exit_cost + submap_cost
	if player.stats.energy < total_cost:
		return ["Not enough energy: need %.1f (exit %.1f + travel %.1f)" % [total_cost, exit_cost, submap_cost]]
	player.stats.consume_energy(total_cost)
	player.location = submap
	SaveSystem.save_character(account_name, player)
	return ["Traveled to %s (-%.1f energy)." % [submap, total_cost]]

func move_to_node(submap: String, node_id: String) -> Array:
	if player == null:
		return ["No active character. Create or select one first."]
	if get_current_submap() != submap:
		return ["Travel to %s first." % submap]
	if submap == "town":
		return ["Town has no nodes."]
	if not nodes.has(node_id):
		return ["No node named %s." % node_id]
	var target_distance = _node_distance(submap, node_id)
	if target_distance <= 0:
		return ["Node %s is not in %s." % [node_id, submap]]
	var exit_cost = _exit_cost_from_current()
	var entry_cost = target_distance * NODE_TRAVEL_COST
	var total_cost = exit_cost + entry_cost
	if player.stats.energy < total_cost:
		return ["Not enough energy: need %.1f (exit %.1f + move %.1f)." % [total_cost, exit_cost, entry_cost]]
	player.stats.consume_energy(total_cost)
	var log: Array = []
	if exit_cost > 0:
		log.append("Left current node (-%.1f energy)." % exit_cost)
	log.append("Moved to %s (-%.1f energy)." % [node_id, entry_cost])
	player.location = "%s>%s" % [submap, node_id]
	SaveSystem.save_character(account_name, player)
	return log

func return_to_town() -> Array:
	return travel_to_submap("town")

func act_in_current_node(action_type: String) -> Array:
	if player == null:
		return ["No active character. Create or select one first."]
	var node_id = get_current_node()
	var submap = get_current_submap()
	if node_id == "" or submap == "town":
		return ["Move to a node first."]
	if not nodes.has(node_id):
		return ["Node data missing."]
	var base_node: MapNode = nodes[node_id]
	var node = MapNode.new(base_node.to_dict())
	if action_type == "harvest":
		node.node_type = "harvest"
		node.damage_range = Vector2.ZERO
	elif action_type == "combat":
		node.node_type = "combat"
	else:
		return ["Unknown action."]
	var result = EncounterSystem.resolve(node, player)
	SaveSystem.save_character(account_name, player)
	return result.get("log", [])

func _exit_cost_from_current() -> float:
	var current_node = get_current_node()
	if current_node == "":
		return 0.0
	var submap = get_current_submap()
	var distance = _node_distance(submap, current_node)
	if distance <= 0:
		return 0.0
	return distance * NODE_TRAVEL_COST

func _node_distance(submap: String, node_id: String) -> int:
	if not submap_nodes.has(submap):
		return -1
	for i in range(submap_nodes[submap].size()):
		var node: MapNode = submap_nodes[submap][i]
		if node.id == node_id:
			return i + 1
	return -1
