extends Node

var inventory_panel: Control
var skills_panel: Control

var _log: Callable
var _refresh_status: Callable
var _refresh_open_panels: Callable
var _save_and_exit: Callable

func init(inventory: Control, skills: Control, log_func: Callable, refresh_status_func: Callable, refresh_open_panels_func: Callable, save_exit_func: Callable):
	inventory_panel = inventory
	skills_panel = skills
	_log = log_func
	_refresh_status = refresh_status_func
	_refresh_open_panels = refresh_open_panels_func
	_save_and_exit = save_exit_func

	if inventory_panel != null:
		inventory_panel.equip_item.connect(_on_inventory_panel_equip)
		inventory_panel.unequip_slot.connect(_on_inventory_panel_unequip)

func register_action_bar(action_bar: Node):
	if action_bar == null:
		return
	if action_bar.has_signal("open_inventory"):
		action_bar.open_inventory.connect(_on_inventory_pressed)
	if action_bar.has_signal("open_skills"):
		action_bar.open_skills.connect(_on_skills_pressed)
	if action_bar.has_signal("save_exit"):
		action_bar.save_exit.connect(_on_save_exit_pressed)

func _on_inventory_pressed():
	if not GameState.has_active_character():
		_log.call("No active character.")
		return
	_refresh_inventory_panel()
	inventory_panel.visible = true

func request_inventory():
	_on_inventory_pressed()

func _on_skills_pressed():
	if not GameState.has_active_character():
		_log.call("No active character.")
		return
	_refresh_skills_panel()
	skills_panel.visible = true

func request_skills():
	_on_skills_pressed()

func _on_save_exit_pressed():
	_save_and_exit.call()

func request_save_exit():
	_on_save_exit_pressed()

func _on_inventory_panel_equip(item_id: String):
	_log.call(GameState.equip_item(item_id))
	_refresh_inventory_panel()
	_refresh_status.call()

func _on_inventory_panel_unequip(slot: String):
	_log.call(GameState.unequip(slot))
	_refresh_inventory_panel()
	_refresh_status.call()

func _refresh_inventory_panel():
	if inventory_panel == null:
		return
	var equipped_entries = GameState.get_equipped_entries()
	var equipment_entries = GameState.get_equipment_inventory_entries()
	var item_entries = GameState.get_item_inventory_entries()
	inventory_panel.refresh(equipped_entries, equipment_entries, item_entries)

func _refresh_skills_panel():
	if skills_panel == null:
		return
	if not GameState.has_active_character():
		return
	skills_panel.refresh(_get_skill_lines())

func refresh_if_visible():
	if inventory_panel != null and inventory_panel.visible:
		_refresh_inventory_panel()
	if skills_panel != null and skills_panel.visible:
		_refresh_skills_panel()

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
