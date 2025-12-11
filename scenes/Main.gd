extends Control

@onready var log_box: Control = $ScrollContainer/MarginContainer/VBoxContainer/LogBox
@onready var status_label: Label = $ScrollContainer/MarginContainer/VBoxContainer/Status
@onready var account_box: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer/AccountBox
@onready var account_select: OptionButton = $ScrollContainer/MarginContainer/VBoxContainer/AccountBox/AccountSelectRow/AccountSelect
@onready var select_account_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/AccountBox/AccountSelectRow/SelectAccountButton
@onready var account_name_input: LineEdit = $ScrollContainer/MarginContainer/VBoxContainer/AccountBox/AccountCreateRow/AccountNameInput
@onready var create_account_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/AccountBox/AccountCreateRow/CreateAccountButton
@onready var character_box: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer/CharacterBox
@onready var name_input: LineEdit = $ScrollContainer/MarginContainer/VBoxContainer/CharacterBox/CharacterNameRow/NameInput
@onready var character_select: OptionButton = $ScrollContainer/MarginContainer/VBoxContainer/CharacterBox/ManageRow/CharacterSelect
@onready var select_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/CharacterBox/ManageRow/SelectButton
@onready var delete_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/CharacterBox/ManageRow/DeleteButton
@onready var create_harvester_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/CharacterBox/CreateRow/CreateHarvesterButton
@onready var create_fighter_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/CharacterBox/CreateRow/CreateFighterButton
@onready var map_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/NavigationRow/MapButton
@onready var primary_action_bar: Control = $ScrollContainer/MarginContainer/VBoxContainer/NavigationRow/PrimaryActionBar
@onready var inventory_panel: Control = $InventoryPanel
@onready var skills_panel: Control = $SkillsPanel
@onready var map_panel: Control = $MapPanel
@onready var town_panel: Control = $TownPanel
@onready var zone_panel: Control = $ZonePanel
@onready var node_panel: Control = $NodePanel

var _log_lines: Array = []

func _ready():
	_connect_buttons()
	_append_log("Pick or create an account to begin.")
	_refresh_account_selector()
	_refresh_character_selector()
	_refresh_status()
	_refresh_visibility()
	_refresh_open_panels()

func _process(delta):
	var updates = GameState.tick(delta)
	if updates.size() > 0:
		_append_logs(updates)
		_refresh_status()
		_refresh_open_panels()

func _connect_buttons():
	create_account_button.pressed.connect(_on_create_account_pressed)
	select_account_button.pressed.connect(_on_select_account_pressed)
	create_harvester_button.pressed.connect(_on_create_harvester_pressed)
	create_fighter_button.pressed.connect(_on_create_fighter_pressed)
	select_button.pressed.connect(_on_select_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	map_button.pressed.connect(_on_map_pressed)
	if primary_action_bar.has_signal("open_inventory"):
		primary_action_bar.open_inventory.connect(_on_inventory_pressed)
		primary_action_bar.open_skills.connect(_on_skills_pressed)
		primary_action_bar.save_exit.connect(_on_save_exit_pressed)
	inventory_panel.equip_item.connect(_on_inventory_panel_equip)
	inventory_panel.unequip_slot.connect(_on_inventory_panel_unequip)
	map_panel.select_zone.connect(_on_map_zone_selected)
	map_panel.close_requested.connect(func(): map_panel.visible = false)
	map_panel.open_inventory.connect(_on_inventory_pressed)
	map_panel.open_skills.connect(_on_skills_pressed)
	map_panel.save_exit.connect(_on_save_exit_pressed)
	town_panel.rest_pressed.connect(_on_rest_pressed)
	town_panel.craft_pressed.connect(_on_craft_pressed)
	town_panel.open_map.connect(_on_map_pressed)
	town_panel.open_inventory.connect(_on_inventory_pressed)
	town_panel.open_skills.connect(_on_skills_pressed)
	town_panel.save_exit.connect(_on_save_exit_pressed)
	town_panel.close_requested.connect(func(): town_panel.visible = false)
	zone_panel.move_to_node.connect(_on_move_to_node_requested)
	zone_panel.rest_pressed.connect(_on_rest_pressed)
	zone_panel.craft_pressed.connect(_on_craft_pressed)
	zone_panel.open_map.connect(_on_map_pressed)
	zone_panel.open_inventory.connect(_on_inventory_pressed)
	zone_panel.open_skills.connect(_on_skills_pressed)
	zone_panel.save_exit.connect(_on_save_exit_pressed)
	zone_panel.close_requested.connect(func(): zone_panel.visible = false)
	node_panel.rest_pressed.connect(_on_rest_pressed)
	node_panel.craft_pressed.connect(_on_craft_pressed)
	node_panel.return_pressed.connect(_on_return_pressed)
	node_panel.harvest_pressed.connect(_on_harvest_pressed)
	node_panel.combat_pressed.connect(_on_combat_pressed)
	node_panel.open_map.connect(_on_map_pressed)
	node_panel.open_zone.connect(_on_open_zone_from_node)
	node_panel.open_inventory.connect(_on_inventory_pressed)
	node_panel.open_skills.connect(_on_skills_pressed)
	node_panel.save_exit.connect(_on_save_exit_pressed)
	node_panel.close_requested.connect(func():
		node_panel.visible = false
		var sub = GameState.get_current_submap()
		if sub != "":
			_open_zone_panel(sub)
	)

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
	_refresh_visibility()
	_refresh_status()
	_refresh_open_panels()

func _on_create_harvester_pressed():
	_append_logs(GameState.create_character(name_input.text, "harvester"))
	name_input.text = ""
	_refresh_character_selector()
	_refresh_visibility()
	_refresh_status()
	_refresh_open_panels()

func _on_create_fighter_pressed():
	_append_logs(GameState.create_character(name_input.text, "fighter"))
	name_input.text = ""
	_refresh_character_selector()
	_refresh_visibility()
	_refresh_status()
	_refresh_open_panels()

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
	_refresh_visibility()
	_refresh_status()
	_refresh_open_panels()

func _on_harvest_pressed():
	_append_logs(GameState.act_in_current_node("harvest"))
	_refresh_status()
	_refresh_open_panels()

func _on_combat_pressed():
	_append_logs(GameState.act_in_current_node("combat"))
	_refresh_status()
	_refresh_open_panels()

func _on_return_pressed():
	_append_logs(GameState.return_to_town())
	_refresh_status()
	_refresh_open_panels()
	if GameState.get_current_submap() == "town":
		_open_town_panel()

func _on_inventory_pressed():
	if not GameState.has_active_character():
		_append_log("No active character.")
		return
	_refresh_inventory_panel()
	inventory_panel.visible = true

func _on_skills_pressed():
	if not GameState.has_active_character():
		_append_log("No active character.")
		return
	_refresh_skills_panel()
	skills_panel.visible = true

func _on_craft_pressed():
	_append_logs(GameState.start_craft("plank"))
	_refresh_status()
	_refresh_open_panels()

func _on_rest_pressed():
	_append_logs(GameState.rest())
	_refresh_status()
	_refresh_open_panels()

func _on_map_pressed():
	if not GameState.has_active_character():
		_append_log("No active character.")
		return
	_hide_sub_panels()
	_refresh_map_panel()
	map_panel.visible = true
	node_panel.visible = false

func _on_map_zone_selected(submap: String):
	if not GameState.has_active_character():
		_append_log("No active character.")
		return
	_append_logs(GameState.travel_to_submap(submap))
	_refresh_status()
	_refresh_open_panels()
	map_panel.visible = false
	var current_submap = GameState.get_current_submap()
	if current_submap == "town":
		_open_town_panel()
	elif current_submap != "":
		_open_zone_panel(current_submap)
	var current_node = GameState.get_current_node()
	if current_node != "":
		_open_node_panel(current_submap, current_node)

func _on_open_zone_from_node():
	var submap = GameState.get_current_submap()
	if submap == "":
		return
	_open_zone_panel(submap)

func _on_move_to_node_requested(submap: String, node_id: String):
	_append_logs(GameState.move_to_node(submap, node_id))
	_refresh_status()
	_refresh_open_panels()
	var current_submap = GameState.get_current_submap()
	var current_node = GameState.get_current_node()
	if current_submap == submap and current_node == node_id:
		_open_node_panel(submap, node_id)

func _on_save_exit_pressed():
	if GameState.has_active_character():
		SaveSystem.save_character(GameState.account_name, GameState.player)
	_append_log("Saved. Exiting.")
	get_tree().quit()

func _on_inventory_panel_equip(item_id: String):
	_append_logs(GameState.equip_item(item_id))
	_refresh_inventory_panel()
	_refresh_status()

func _on_inventory_panel_unequip(slot: String):
	_append_logs(GameState.unequip(slot))
	_refresh_inventory_panel()
	_refresh_status()

func _append_log(line: String):
	_log_lines.append(line)
	if _log_lines.size() > 50:
		_log_lines.remove_at(0)
	_refresh_log_outputs()

func _append_logs(lines: Array):
	for line in lines:
		_append_log(str(line))

func _refresh_log_outputs():
	if log_box != null and log_box.has_method("set_lines"):
		log_box.set_lines(_log_lines)
		if log_box.has_method("scroll_to_end"):
			log_box.scroll_to_end()
	if node_panel != null and node_panel.has_method("set_log_lines"):
		node_panel.set_log_lines(_log_lines)

func _refresh_inventory_panel():
	var equipped_entries = GameState.get_equipped_entries()
	var equipment_entries = GameState.get_equipment_inventory_entries()
	var item_entries = GameState.get_item_inventory_entries()
	inventory_panel.refresh(equipped_entries, equipment_entries, item_entries)

func _refresh_skills_panel():
	if not GameState.has_active_character():
		return
	skills_panel.refresh(_get_skill_lines())

func _get_skill_lines() -> Array:
	var lines: Array = []
	if not GameState.has_active_character():
		return lines
	var p = GameState.player
	var ids: Array = p.skills.keys()
	ids.sort()
	for id in ids:
		var skill = p.skills[id]
		lines.append("%s - Lv%d (%.1f/%.1f)" % [id, skill.level, skill.xp, skill.xp_to_next])
	return lines

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
	_refresh_open_panels()

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

func _refresh_map_panel():
	if map_panel.has_method("set_enabled"):
		map_panel.set_enabled(GameState.has_active_character())
	if map_panel.has_method("refresh"):
		map_panel.refresh(GameState.get_location_text())

func _open_town_panel():
	if not GameState.has_active_character():
		return
	_hide_sub_panels()
	if town_panel.has_method("set_enabled"):
		town_panel.set_enabled(true)
	if town_panel.has_method("refresh"):
		town_panel.refresh("Location: %s" % GameState.get_location_text())
	town_panel.visible = true

func _open_zone_panel(submap: String):
	if not GameState.has_active_character():
		return
	if submap == "town":
		_open_town_panel()
		return
	_hide_sub_panels()
	var nodes = GameState.list_nodes(submap)
	var current_node = GameState.get_current_node()
	if zone_panel.has_method("set_enabled"):
		zone_panel.set_enabled(true)
	if zone_panel.has_method("refresh"):
		var info = "Location: %s" % GameState.get_location_text()
		zone_panel.refresh(submap, nodes, current_node, info)
	zone_panel.visible = true
	node_panel.visible = false

func _open_node_panel(submap: String, node_id: String):
	if not GameState.has_active_character():
		return
	if node_id == "":
		return
	_hide_sub_panels()
	if node_panel.has_method("set_enabled"):
		node_panel.set_enabled(true)
	if node_panel.has_method("refresh"):
		var info = "Location: %s" % GameState.get_location_text()
		node_panel.refresh(submap, node_id, info)
	node_panel.visible = true
	zone_panel.visible = false
	_refresh_log_outputs()

func _hide_sub_panels():
	map_panel.visible = false
	town_panel.visible = false
	zone_panel.visible = false
	node_panel.visible = false

func _refresh_open_panels():
	var has_character = GameState.has_active_character()
	if primary_action_bar.has_method("set_enabled"):
		primary_action_bar.set_enabled(has_character)
	if map_panel.has_method("set_enabled"):
		map_panel.set_enabled(has_character)
	if town_panel.has_method("set_enabled"):
		town_panel.set_enabled(has_character)
	if zone_panel.has_method("set_enabled"):
		zone_panel.set_enabled(has_character)
	if node_panel.has_method("set_enabled"):
		node_panel.set_enabled(has_character)
	if not has_character:
		_hide_sub_panels()
	if map_panel.visible:
		_refresh_map_panel()
	if town_panel.visible:
		if has_character and town_panel.has_method("refresh"):
			town_panel.refresh("Location: %s" % GameState.get_location_text())
		else:
			town_panel.visible = false
	if zone_panel.visible:
		if not has_character:
			zone_panel.visible = false
		else:
			var current_submap = GameState.get_current_submap()
			if current_submap == "town":
				_open_town_panel()
			elif current_submap != "" and zone_panel.has_method("refresh"):
				var nodes = GameState.list_nodes(current_submap)
				var current_node = GameState.get_current_node()
				var info = "Location: %s" % GameState.get_location_text()
				zone_panel.refresh(current_submap, nodes, current_node, info)
	if node_panel.visible:
		if not has_character:
			node_panel.visible = false
		else:
			var current_submap_node = GameState.get_current_submap()
			var current_node_id = GameState.get_current_node()
			if current_submap_node == "" or current_node_id == "":
				node_panel.visible = false
			elif node_panel.has_method("refresh"):
				var info_node = "Location: %s" % GameState.get_location_text()
				node_panel.refresh(current_submap_node, current_node_id, info_node)
	if node_panel.visible:
		_refresh_log_outputs()

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
	if not GameState.has_active_character():
		inventory_panel.visible = false
		skills_panel.visible = false
		_hide_sub_panels()

func _set_action_buttons_enabled(enabled: bool):
	map_button.disabled = not enabled
	if primary_action_bar.has_method("set_enabled"):
		primary_action_bar.set_enabled(enabled)
	if map_panel.has_method("set_enabled"):
		map_panel.set_enabled(enabled)
	if town_panel.has_method("set_enabled"):
		town_panel.set_enabled(enabled)
	if zone_panel.has_method("set_enabled"):
		zone_panel.set_enabled(enabled)
	if node_panel.has_method("set_enabled"):
		node_panel.set_enabled(enabled)
	if not enabled:
		inventory_panel.visible = false
		skills_panel.visible = false
		_hide_sub_panels()
