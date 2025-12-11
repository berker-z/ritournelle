extends Node

const Character = preload("res://scripts/core/character.gd")
const Account = preload("res://scripts/core/account.gd")
const MapNode = preload("res://scripts/core/map_node.gd")
const Recipe = preload("res://scripts/core/recipe.gd")
const ItemsData = preload("res://data/items.gd")
const RecipesData = preload("res://data/recipes.gd")
const NodesData = preload("res://data/nodes.gd")

var account_name: String = ""
var account: Account
var player: Character
var nodes: Dictionary = {}
var recipes: Dictionary = {}

func _ready():
	_load_data()
	SaveSystem.ensure_base_dir()

func _load_data():
	for node_id in NodesData.NODES.keys():
		nodes[node_id] = MapNode.new(NodesData.NODES[node_id])
	for recipe_id in RecipesData.RECIPES.keys():
		recipes[recipe_id] = Recipe.new(RecipesData.RECIPES[recipe_id])

func _seed_inventory(character: Character):
	character.inventory.add("log", 3)
	character.inventory.add("herb", 2)

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
	var created_name = SaveSystem.create_account(raw_name)
	var existed = SaveSystem.list_accounts().has(created_name)
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

func run_node(node_id: String) -> Array:
	if player == null:
		return ["No active character. Create or select one first."]
	if not nodes.has(node_id):
		return ["No node named %s." % node_id]
	var result = EncounterSystem.resolve(nodes[node_id], player)
	SaveSystem.save_character(account_name, player)
	return result.get("log", [])

func rest() -> Array:
	if player == null:
		return ["No active character. Create or select one first."]
	player.rest()
	SaveSystem.save_character(account_name, player)
	return ["Rested. HP %d/%d | Energy %.1f/%.1f" % [player.stats.hp, player.stats.hp_max, player.stats.energy, player.stats.energy_max]]

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
