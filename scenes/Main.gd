extends Control

@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/Log
@onready var status_label: Label = $MarginContainer/VBoxContainer/Status
@onready var account_box: VBoxContainer = $MarginContainer/VBoxContainer/AccountBox
@onready var account_select: OptionButton = $MarginContainer/VBoxContainer/AccountBox/AccountSelectRow/AccountSelect
@onready var select_account_button: Button = $MarginContainer/VBoxContainer/AccountBox/AccountSelectRow/SelectAccountButton
@onready var account_name_input: LineEdit = $MarginContainer/VBoxContainer/AccountBox/AccountCreateRow/AccountNameInput
@onready var create_account_button: Button = $MarginContainer/VBoxContainer/AccountBox/AccountCreateRow/CreateAccountButton
@onready var character_box: VBoxContainer = $MarginContainer/VBoxContainer/CharacterBox
@onready var name_input: LineEdit = $MarginContainer/VBoxContainer/CharacterBox/CharacterNameRow/NameInput
@onready var character_select: OptionButton = $MarginContainer/VBoxContainer/CharacterBox/ManageRow/CharacterSelect
@onready var select_button: Button = $MarginContainer/VBoxContainer/CharacterBox/ManageRow/SelectButton
@onready var delete_button: Button = $MarginContainer/VBoxContainer/CharacterBox/ManageRow/DeleteButton
@onready var create_harvester_button: Button = $MarginContainer/VBoxContainer/CharacterBox/CreateRow/CreateHarvesterButton
@onready var create_fighter_button: Button = $MarginContainer/VBoxContainer/CharacterBox/CreateRow/CreateFighterButton
@onready var travel_box: VBoxContainer = $MarginContainer/VBoxContainer/TravelBox
@onready var submap_select: OptionButton = $MarginContainer/VBoxContainer/TravelBox/SubmapRow/SubmapSelect
@onready var node_select: OptionButton = $MarginContainer/VBoxContainer/TravelBox/NodeRow/NodeSelect
@onready var travel_button: Button = $MarginContainer/VBoxContainer/TravelBox/SubmapRow/TravelButton
@onready var move_node_button: Button = $MarginContainer/VBoxContainer/TravelBox/NodeRow/MoveNodeButton
@onready var harvest_button: Button = $MarginContainer/VBoxContainer/Actions/HarvestButton
@onready var combat_button: Button = $MarginContainer/VBoxContainer/Actions/CombatButton
@onready var return_button: Button = $MarginContainer/VBoxContainer/Actions/ReturnButton
@onready var inventory_button: Button = $MarginContainer/VBoxContainer/Actions/InventoryButton
@onready var skills_button: Button = $MarginContainer/VBoxContainer/Actions/SkillsButton
@onready var craft_button: Button = $MarginContainer/VBoxContainer/Actions/CraftButton
@onready var rest_button: Button = $MarginContainer/VBoxContainer/Actions/RestButton
@onready var save_exit_button: Button = $MarginContainer/VBoxContainer/Actions/SaveExitButton
@onready var inventory_panel: Control = $InventoryPanel
@onready var inventory_equipped_list: ItemList = $InventoryPanel/Panel/MarginContainer/VBoxContainer/EquippedList
@onready var inventory_equipment_list: ItemList = $InventoryPanel/Panel/MarginContainer/VBoxContainer/EquipmentList
@onready var inventory_items_list: ItemList = $InventoryPanel/Panel/MarginContainer/VBoxContainer/ItemsList
@onready var close_inventory_button: Button = $InventoryPanel/Panel/MarginContainer/VBoxContainer/InventoryHeader/CloseInventoryButton
@onready var skills_panel: Control = $SkillsPanel
@onready var skills_list: ItemList = $SkillsPanel/Panel/MarginContainer/VBoxContainer/SkillsList
@onready var close_skills_button: Button = $SkillsPanel/Panel/MarginContainer/VBoxContainer/SkillsHeader/CloseSkillsButton

var _log_lines: Array = []

func _ready():
	_connect_buttons()
	_append_log("Pick or create an account to begin.")
	_refresh_account_selector()
	_refresh_character_selector()
	_refresh_map_selectors()
	_refresh_status()
	_refresh_visibility()

func _process(delta):
	var updates = GameState.tick(delta)
	if updates.size() > 0:
		_append_logs(updates)
		_refresh_status()

func _connect_buttons():
	create_account_button.pressed.connect(_on_create_account_pressed)
	select_account_button.pressed.connect(_on_select_account_pressed)
	create_harvester_button.pressed.connect(_on_create_harvester_pressed)
	create_fighter_button.pressed.connect(_on_create_fighter_pressed)
	select_button.pressed.connect(_on_select_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	travel_button.pressed.connect(_on_travel_pressed)
	submap_select.item_selected.connect(_on_submap_selected)
	move_node_button.pressed.connect(_on_move_node_pressed)
	harvest_button.pressed.connect(_on_harvest_pressed)
	combat_button.pressed.connect(_on_combat_pressed)
	return_button.pressed.connect(_on_return_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	skills_button.pressed.connect(_on_skills_pressed)
	craft_button.pressed.connect(_on_craft_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	save_exit_button.pressed.connect(_on_save_exit_pressed)
	close_inventory_button.pressed.connect(_on_close_inventory_pressed)
	close_skills_button.pressed.connect(_on_close_skills_pressed)
	inventory_equipped_list.item_selected.connect(_on_equipped_item_selected)
	inventory_equipment_list.item_selected.connect(_on_inventory_item_selected)

func _on_create_account_pressed():
	var name = account_name_input.text
	_append_logs(GameState.create_account(name))
	account_name_input.text = ""
	_refresh_account_selector()
	_refresh_visibility()
	_refresh_status()

func _on_select_account_pressed():
	if account_select.disabled:
		_append_log("No accounts to select. Create one first.")
		return
	var name = account_select.get_item_text(account_select.selected)
	_append_logs(GameState.select_account(name))
	_refresh_character_selector()
	_refresh_map_selectors()
	_refresh_visibility()
	_refresh_status()

func _on_create_harvester_pressed():
	_append_logs(GameState.create_character(name_input.text, "harvester"))
	name_input.text = ""
	_refresh_character_selector()
	_refresh_map_selectors()
	_refresh_visibility()
	_refresh_status()

func _on_create_fighter_pressed():
	_append_logs(GameState.create_character(name_input.text, "fighter"))
	name_input.text = ""
	_refresh_character_selector()
	_refresh_map_selectors()
	_refresh_visibility()
	_refresh_status()

func _on_select_pressed():
	if character_select.disabled:
		_append_log("No characters to select. Create one first.")
		return
	var name = character_select.get_item_text(character_select.selected)
	_append_logs(GameState.select_character_by_name(name))
	_refresh_visibility()
	_refresh_status()

func _on_delete_pressed():
	if character_select.disabled:
		_append_log("No characters to delete.")
		return
	var name = character_select.get_item_text(character_select.selected)
	_append_logs(GameState.delete_character(name))
	_refresh_character_selector()
	_refresh_map_selectors()
	_refresh_visibility()
	_refresh_status()

func _on_submap_selected(index):
	_refresh_node_selector()

func _on_travel_pressed():
	var submap = submap_select.get_item_text(submap_select.selected)
	_append_logs(GameState.travel_to_submap(submap))
	_refresh_node_selector()
	_refresh_status()

func _on_move_node_pressed():
	var submap = submap_select.get_item_text(submap_select.selected)
	var node_id = node_select.get_item_text(node_select.selected)
	_append_logs(GameState.move_to_node(submap, node_id))
	_refresh_node_selector()
	_refresh_status()

func _on_harvest_pressed():
	_append_logs(GameState.act_in_current_node("harvest"))
	_refresh_status()

func _on_combat_pressed():
	_append_logs(GameState.act_in_current_node("combat"))
	_refresh_status()

func _on_return_pressed():
	_append_logs(GameState.return_to_town())
	_refresh_node_selector()
	_refresh_status()

func _on_inventory_pressed():
	if not GameState.has_active_character():
		_append_log("No active character.")
		return
	inventory_panel.visible = true
	_refresh_inventory_panel()

func _on_skills_pressed():
	if not GameState.has_active_character():
		_append_log("No active character.")
		return
	skills_panel.visible = true
	_refresh_skills_panel()

func _on_craft_pressed():
	_append_logs(GameState.start_craft("plank"))
	_refresh_status()

func _on_rest_pressed():
	_append_logs(GameState.rest())
	_refresh_status()

func _on_save_exit_pressed():
	if GameState.has_active_character():
		SaveSystem.save_character(GameState.account_name, GameState.player)
	_append_log("Saved. Exiting.")
	get_tree().quit()

func _on_close_inventory_pressed():
	inventory_panel.visible = false

func _on_close_skills_pressed():
	skills_panel.visible = false

func _on_equipped_item_selected(index: int):
	var data = inventory_equipped_list.get_item_metadata(index)
	var slot = data.get("slot", "")
	if slot == "":
		return
	_append_logs(GameState.unequip(slot))
	_refresh_inventory_panel()
	_refresh_status()

func _on_inventory_item_selected(index: int):
	var data = inventory_equipment_list.get_item_metadata(index)
	var item_id = data.get("item_id", "")
	if item_id == "":
		return
	_append_logs(GameState.equip_item(item_id))
	_refresh_inventory_panel()
	_refresh_status()

func _append_log(line: String):
	_log_lines.append(line)
	if _log_lines.size() > 50:
		_log_lines.remove_at(0)
	log_label.text = "\n".join(_log_lines)
	log_label.scroll_to_line(log_label.get_line_count())

func _append_logs(lines: Array):
	for line in lines:
		_append_log(str(line))

func _refresh_inventory_panel():
	inventory_equipped_list.clear()
	inventory_equipment_list.clear()
	inventory_items_list.clear()
	var equipped_entries = GameState.get_equipped_entries()
	equipped_entries.sort_custom(func(a, b): return a.get("slot", "") < b.get("slot", ""))
	for entry in equipped_entries:
		var slot: String = entry.get("slot", "").capitalize()
		var item_id: String = entry.get("item_id", "")
		var name: String = entry.get("name", "")
		var label = "%s: %s" % [slot, name if name != "" else "(empty)"]
		var idx = inventory_equipped_list.add_item(label)
		inventory_equipped_list.set_item_metadata(idx, entry)
	var equipment_entries = GameState.get_equipment_inventory_entries()
	for entry in equipment_entries:
		var label = "%s x%d" % [entry.get("name", entry.get("item_id", "")), int(entry.get("count", 0))]
		var slot_tag = entry.get("slot", "")
		if slot_tag != "":
			label += " [%s]" % slot_tag
		var idx = inventory_equipment_list.add_item(label)
		inventory_equipment_list.set_item_metadata(idx, entry)
	var item_entries = GameState.get_item_inventory_entries()
	for entry in item_entries:
		var label = "%s x%d" % [entry.get("name", entry.get("item_id", "")), int(entry.get("count", 0))]
		inventory_items_list.add_item(label)

func _refresh_skills_panel():
	skills_list.clear()
	if not GameState.has_active_character():
		return
	var p = GameState.player
	var ids: Array = p.skills.keys()
	ids.sort()
	for id in ids:
		var skill = p.skills[id]
		skills_list.add_item("%s - Lv%d (%.1f/%.1f)" % [id, skill.level, skill.xp, skill.xp_to_next])

func _refresh_status():
	var p = GameState.player
	var status_lines: Array = []
	if not GameState.has_account_selected():
		status_lines.append("No account selected.")
	elif p == null:
		status_lines.append("No active character. Create or select one.")
	else:
		status_lines.append("Location: %s" % GameState.get_location_text())
		status_lines.append("HP %d/%d | Energy %.1f/%.1f" % [p.stats.hp, p.stats.hp_max, p.stats.energy, p.stats.energy_max])
		var equipped_entries = GameState.get_equipped_entries()
		equipped_entries.sort_custom(func(a, b): return a.get("slot", "") < b.get("slot", ""))
		var eq_parts: Array = []
		for entry in equipped_entries:
			var slot = entry.get("slot", "")
			var name = entry.get("name", "")
			eq_parts.append("%s: %s" % [slot.capitalize(), name if name != "" else "Empty"])
		status_lines.append("Equipped: " + ", ".join(eq_parts))
		status_lines.append("Open Inventory/Skills to manage gear and view XP.")
	status_label.text = "\n".join(status_lines)
	_set_action_buttons_enabled(p != null)
	if inventory_panel.visible:
		_refresh_inventory_panel()
	if skills_panel.visible:
		_refresh_skills_panel()

func _refresh_character_selector():
	character_select.clear()
	var names = GameState.get_character_names()
	for i in range(names.size()):
		character_select.add_item(names[i], i)
	if names.size() > 0:
		character_select.select(0)
	else:
		character_select.add_item("No characters", -1)
		character_select.select(0)
	character_select.disabled = names.size() == 0

func _refresh_map_selectors():
	submap_select.clear()
	var maps = GameState.list_submaps()
	for i in range(maps.size()):
		submap_select.add_item(maps[i], i)
	if maps.size() > 0:
		submap_select.select(0)
		submap_select.disabled = false
	else:
		submap_select.add_item("No maps", -1)
		submap_select.select(0)
		submap_select.disabled = true
	_refresh_node_selector()

func _refresh_node_selector():
	node_select.clear()
	if submap_select.disabled:
		node_select.add_item("Travel to a submap first", -1)
		node_select.select(0)
		node_select.disabled = true
		move_node_button.disabled = true
		return
	var submap = submap_select.get_item_text(submap_select.selected)
	var nodes = GameState.list_nodes(submap)
	for i in range(nodes.size()):
		node_select.add_item(nodes[i], i)
	if nodes.size() > 0:
		node_select.select(0)
		node_select.disabled = false
		move_node_button.disabled = false
	else:
		node_select.add_item("No nodes", -1)
		node_select.select(0)
		node_select.disabled = true
		move_node_button.disabled = true

func _refresh_account_selector():
	account_select.clear()
	var accounts = GameState.list_accounts()
	for i in range(accounts.size()):
		account_select.add_item(accounts[i], i)
	if accounts.size() > 0:
		account_select.select(0)
	else:
		account_select.add_item("No accounts", -1)
		account_select.select(0)
	account_select.disabled = accounts.size() == 0

func _refresh_visibility():
	account_box.visible = not GameState.has_account_selected()
	character_box.visible = GameState.has_account_selected() and not GameState.has_active_character()
	travel_box.visible = GameState.has_active_character()
	if not GameState.has_active_character():
		inventory_panel.visible = false
		skills_panel.visible = false

func _set_action_buttons_enabled(enabled: bool):
	harvest_button.disabled = not enabled
	combat_button.disabled = not enabled
	return_button.disabled = not enabled
	inventory_button.disabled = not enabled
	skills_button.disabled = not enabled
	craft_button.disabled = not enabled
	rest_button.disabled = not enabled
	save_exit_button.disabled = false
