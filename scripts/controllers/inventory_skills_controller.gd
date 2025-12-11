class_name InventorySkillsController extends Node

signal log_produced(message)
signal state_changed
signal save_exit_requested

var _inventory_panel: Control
var _skills_panel: Control

func init(inventory_panel: Control, skills_panel: Control):
	_inventory_panel = inventory_panel
	_skills_panel = skills_panel
	
	if _inventory_panel != null:
		_inventory_panel.equip_item.connect(_on_inventory_panel_equip)
		_inventory_panel.unequip_slot.connect(_on_inventory_panel_unequip)

# Optional: logic to create/register action bar connections if we want controller to own it
# Main currently uses "primary_action_bar" and manually connects it.
# We can expose request methods.

func request_inventory():
	if not GameState.has_active_character():
		log_produced.emit("No active character.")
		return
	_refresh_inventory_panel()
	if _inventory_panel:
		_inventory_panel.visible = true

func request_skills():
	if not GameState.has_active_character():
		log_produced.emit("No active character.")
		return
	_refresh_skills_panel()
	if _skills_panel:
		_skills_panel.visible = true

func request_save_exit():
	save_exit_requested.emit()

func _on_inventory_panel_equip(item_id: String):
	var logs: Array[String] = GameState.equip_item(item_id)
	_emit_logs(logs)
	_refresh_inventory_panel()
	state_changed.emit()

func _on_inventory_panel_unequip(slot: String):
	var logs: Array[String] = GameState.unequip(slot)
	_emit_logs(logs)
	_refresh_inventory_panel()
	state_changed.emit()

func refresh_if_visible():
	if _inventory_panel != null and _inventory_panel.visible:
		_refresh_inventory_panel()
	if _skills_panel != null and _skills_panel.visible:
		_refresh_skills_panel()

func _refresh_inventory_panel():
	if _inventory_panel == null:
		return
	var equipped_entries: Array[Dictionary] = GameState.get_equipped_entries()
	var equipment_entries: Array[Dictionary] = GameState.get_equipment_inventory_entries()
	var item_entries: Array[Dictionary] = GameState.get_item_inventory_entries()
	_inventory_panel.refresh(equipped_entries, equipment_entries, item_entries)

func _refresh_skills_panel():
	if _skills_panel == null:
		return
	if not GameState.has_active_character():
		return
	_skills_panel.refresh(_get_skill_lines())

func _get_skill_lines() -> Array[String]:
	var lines: Array[String] = []
	if not GameState.has_active_character():
		return lines
	var p = GameState.player
	var ids: Array = p.skills.keys()
	ids.sort()
	for id in ids:
		var skill = p.skills[id]
		lines.append("%s - Lv%d (%.1f/%.1f)" % [id, skill.level, skill.xp, skill.xp_to_next])
	return lines

func _emit_logs(logs):
	if logs is Array:
		for line in logs:
			log_produced.emit(str(line))
	else:
		log_produced.emit(str(logs))
