extends Node

signal state_changed

const SessionService = preload("res://scripts/services/session_service.gd")
const TravelService = preload("res://scripts/services/travel_service.gd")
const ActionService = preload("res://scripts/services/action_service.gd")
const ItemsData = preload("res://data/items.gd")
const Account = preload("res://scripts/core/account.gd")
const Character = preload("res://scripts/core/character.gd")
const TravelOutcome = preload("res://scripts/core/travel_outcome.gd")

var _session_service: SessionService
var _travel_service: TravelService
var _action_service: ActionService

var account_name: String = ""
var account: Account
var player: Character

func _ready():
	_session_service = SessionService.new()
	_travel_service = TravelService.new()
	_action_service = ActionService.new()
	SaveSystem.ensure_base_dirs()

# --- Session Service Delegates ---

func has_account_selected() -> bool:
	return account != null and not account_name.is_empty()

func has_active_character() -> bool:
	return has_account_selected() and player != null

func list_accounts() -> Array[String]:
	return _session_service.list_accounts()

func select_account(name: String) -> Array[String]:
	var result = _session_service.select_account(name)
	var logs: Array[String] = []
	if result.error != "":
		logs.append(result.error)
		return logs
	account = result.account
	account_name = name
	player = null
	CraftingSystem.reset()
	state_changed.emit()
	logs.append(result.log)
	return logs

func create_account(name: String) -> Array[String]:
	var result = _session_service.create_account(name)
	var logs: Array[String] = []
	# Account creation currently never sets an error; it always returns a created/loaded account.
	account = result.account
	account_name = result.account_name
	player = null
	CraftingSystem.reset()
	state_changed.emit()
	logs.append(result.log)
	return logs

func get_character_names() -> Array[String]:
	return _session_service.get_character_names(account)

func create_character(name: String, background: String) -> Array[String]:
	var result = _session_service.create_character(account, account_name, name, background)
	var logs: Array[String] = []
	if result.error != "":
		logs.append(result.error)
		return logs
	player = result.character
	# create_character service already saves
	CraftingSystem.reset()
	state_changed.emit()
	logs.append(result.log)
	return logs

func select_character_by_name(character_name: String) -> Array[String]:
	var result = _session_service.select_character_by_name(account, character_name)
	var logs: Array[String] = []
	if result.error != "":
		logs.append(result.error)
		return logs
	player = result.character
	CraftingSystem.reset()
	_save_game() # Ensure state is consistent
	logs.append(result.log)
	return logs

func delete_character(character_name: String) -> Array[String]:
	var result = _session_service.delete_character(account, account_name, character_name, player)
	var logs: Array[String] = []
	if result.error != "":
		logs.append(result.error)
		return logs
	if result.reset_player:
		player = null
		CraftingSystem.reset()
	state_changed.emit()
	logs.append(result.log)
	return logs

# --- Travel Service Delegates ---

func list_submaps() -> Array[String]:
	return _travel_service.list_submaps()

func list_nodes(submap: String) -> Array[String]:
	return _travel_service.list_nodes(submap)

func travel_to_submap(submap: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character. Create or select one first.")
		return logs
	var outcome: TravelOutcome = _travel_service.travel_to_submap(player.location, player.stats.energy, submap)
	logs.append_array(outcome.log)
	if not outcome.ok:
		return logs
	player.stats.consume_energy(outcome.energy_cost)
	player.location = outcome.new_location
	_save_game()
	return logs

func move_to_node(submap: String, node_id: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs
	var outcome: TravelOutcome = _travel_service.move_to_node(player.location, player.stats.energy, submap, node_id)
	logs.append_array(outcome.log)
	if not outcome.ok:
		return logs
	player.stats.consume_energy(outcome.energy_cost)
	player.location = outcome.new_location
	_save_game()
	return logs

func return_to_town() -> Array[String]:
	return travel_to_submap(GameConstants.SUBMAP_TOWN)

func get_location_text() -> String:
	if player == null:
		return "Unknown"
	return player.location

func get_current_submap() -> String:
	if player == null: return ""
	return _travel_service.get_submap_from_location(player.location)

func get_current_node() -> String:
	if player == null: return ""
	return _travel_service.get_node_from_location(player.location)

# --- Action Service Delegates ---

func act_in_current_node(action_type: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs
	var node_id = get_current_node()
	var submap = get_current_submap()
	if node_id == "" or submap == GameConstants.SUBMAP_TOWN:
		logs.append("Move to a node first.")
		return logs

	# We need the MapNode object. ActionService expects it.
	# TravelService has the nodes.
	if not _travel_service.nodes.has(node_id):
		logs.append("Node data missing.")
		return logs
	var base_node = _travel_service.nodes[node_id]

	logs = _action_service.act_in_node(player, base_node, submap, action_type)
	_save_game()
	return logs

func rest() -> Array[String]:
	var logs = _action_service.rest(player)
	_save_game()
	return logs

func start_craft(recipe_id: String) -> Array[String]:
	var logs = _action_service.start_craft(player, recipe_id)
	_save_game()
	return logs

# --- Inventory / Equipment (Facade) ---

func get_inventory_lines() -> Array[String]:
	if player == null:
		var empty: Array[String] = []
		return empty
	return player.inventory.to_lines()

func get_equipped_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if player == null:
		return entries
	for slot in player.equipped.keys():
		var item_id: String = player.equipped.get(slot, "")
		var meta = ItemsData.get_item_static(item_id) if item_id != "" else {}
		entries.append({
			"slot": slot,
			"item_id": item_id,
			"name": meta.get("name", item_id),
			"type": meta.get("type", ""),
			"slot_name": ItemsData.slot_for(meta)
		})
	return entries

func get_equipment_inventory_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if player == null:
		return entries
	for item_id in player.inventory.items.keys():
		var count: int = int(player.inventory.items[item_id])
		var meta = ItemsData.get_item_static(item_id)
		if ItemsData.is_equipment(meta):
			entries.append({
				"item_id": item_id,
				"name": meta.get("name", item_id),
				"type": meta.get("type", ""),
				"slot": ItemsData.slot_for(meta),
				"count": count
			})
	entries.sort_custom(func(a, b): return a.get("name", "") < b.get("name", ""))
	return entries

func get_item_inventory_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if player == null:
		return entries
	for item_id in player.inventory.items.keys():
		var count: int = int(player.inventory.items[item_id])
		var meta = ItemsData.get_item_static(item_id)
		if not ItemsData.is_equipment(meta):
			entries.append({
				"item_id": item_id,
				"name": meta.get("name", item_id),
				"type": meta.get("type", ""),
				"count": count
			})
	entries.sort_custom(func(a, b): return a.get("name", "") < b.get("name", ""))
	return entries

# Helper actions for inventory (Equip/Unequip) - could be in ActionService
func equip_item(item_id: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs
	var message = player.equip_item(item_id)
	_save_game()
	logs.append(message)
	return logs

func unequip(slot: String) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		logs.append("No active character.")
		return logs
	var message = player.unequip_slot(slot)
	_save_game()
	logs.append(message)
	return logs

# --- System ---

func tick(delta: float) -> Array[String]:
	var logs: Array[String] = []
	if player == null:
		return logs
	for entry in CraftingSystem.tick(delta, player):
		logs.append(entry)
	if logs.size() > 0:
		_save_game()
	return logs

func _save_game():
	if has_active_character():
		SaveSystem.save_character(account_name, player)
	state_changed.emit()

func _create_new_character_and_save(account_name: String, character: Character):
	player = character
	player.location = GameConstants.SUBMAP_TOWN
	SaveSystem.save_character(account_name, character)

func save_checkpoint():
	_save_game()
