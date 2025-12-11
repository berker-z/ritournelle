class_name NavigationController extends Node

signal log_produced(message)
signal state_changed

var _map_panel: Control
var _town_panel: Control
var _zone_panel: Control
var _node_panel: Control

func init(map_panel: Control, town_panel: Control, zone_panel: Control, node_panel: Control):
	_map_panel = map_panel
	_town_panel = town_panel
	_zone_panel = zone_panel
	_node_panel = node_panel
	
	_connect_signals()

func _connect_signals():
	_map_panel.select_zone.connect(_on_map_zone_selected)
	_zone_panel.move_to_node.connect(_on_move_to_node_requested)
	_zone_panel.open_map.connect(_on_open_map_requested)
	_node_panel.open_map.connect(_on_open_map_requested)
	_node_panel.open_zone.connect(_on_open_zone_from_node)
	_node_panel.return_pressed.connect(_on_return_pressed)

func _on_map_zone_selected(submap: String):
	if not GameState.has_active_character():
		log_produced.emit("No active character.")
		return
		
	var logs: Array[String] = GameState.travel_to_submap(submap)
	_emit_logs(logs)
	state_changed.emit()
	
	_map_panel.visible = false
	_open_location_panel()

func _on_move_to_node_requested(submap: String, node_id: String):
	var logs: Array[String] = GameState.move_to_node(submap, node_id)
	_emit_logs(logs)
	state_changed.emit()
	
	var current_submap = GameState.get_current_submap()
	var current_node = GameState.get_current_node()
	if current_submap == submap and current_node == node_id:
		_open_node_panel(submap, node_id)

func _on_open_map_requested():
	if not GameState.has_active_character():
		log_produced.emit("No active character.")
		return
	_hide_sub_panels()
	# Main.gd handled _refresh_map_panel(). We should do it here or assume Main does it via state_changed?
	# Main's _refresh_map_panel calls set_enabled and refresh logic.
	# Ideally the controller prepares the panel.
	_map_panel.set_enabled(true)
	_map_panel.refresh(GameState.get_location_text())
	_map_panel.visible = true

func _on_open_zone_from_node():
	var submap = GameState.get_current_submap()
	if submap == "":
		return
	_open_zone_panel(submap)

func _on_return_pressed():
	var logs: Array[String] = GameState.return_to_town()
	_emit_logs(logs)
	state_changed.emit()
	_open_location_panel()

func _open_location_panel():
	var current_submap = GameState.get_current_submap()
	if current_submap == GameConstants.SUBMAP_TOWN:
		_open_town_panel()
	elif current_submap != "":
		_open_zone_panel(current_submap)
	
	var current_node = GameState.get_current_node()
	if current_node != "":
		_open_node_panel(current_submap, current_node)

func _open_town_panel():
	_hide_sub_panels()
	_town_panel.set_enabled(true)
	_town_panel.refresh("Location: %s" % GameState.get_location_text())
	_town_panel.visible = true

func _open_zone_panel(submap: String):
	if submap == GameConstants.SUBMAP_TOWN:
		_open_town_panel()
		return
	_hide_sub_panels()
	var nodes = GameState.list_nodes(submap)
	var current_node = GameState.get_current_node()
	_zone_panel.set_enabled(true)
	var info = "Location: %s" % GameState.get_location_text()
	_zone_panel.refresh(submap, nodes, current_node, info)
	_zone_panel.visible = true

func _open_node_panel(submap: String, node_id: String):
	if node_id == "":
		return
	_hide_sub_panels()
	_node_panel.set_enabled(true)
	var info = "Location: %s" % GameState.get_location_text()
	_node_panel.refresh(submap, node_id, info)
	_node_panel.visible = true

func _hide_sub_panels():
	_map_panel.visible = false
	_town_panel.visible = false
	_zone_panel.visible = false
	_node_panel.visible = false

func _emit_logs(logs):
	if logs is Array:
		for line in logs:
			log_produced.emit(str(line))
	else:
		log_produced.emit(str(logs))

# Helper to refresh panels when state changes externally (e.g. initial load)
func refresh_panels():
	if not GameState.has_active_character():
		_hide_sub_panels()
		return
		
	# Check what is visible and refresh it
	if _map_panel.visible:
		_on_open_map_requested()
	elif _town_panel.visible or GameState.get_current_submap() == GameConstants.SUBMAP_TOWN:
		_open_town_panel() # Re-opening refreshes data
	elif _zone_panel.visible:
		_open_zone_panel(GameState.get_current_submap())
	elif _node_panel.visible:
		_open_node_panel(GameState.get_current_submap(), GameState.get_current_node())
