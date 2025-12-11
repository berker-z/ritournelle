class_name ActionController extends Node

signal log_produced(message)
signal state_changed

var _node_panel: Control
var _zone_panel: Control
var _town_panel: Control

func init(node_panel: Control, zone_panel: Control, town_panel: Control):
	_node_panel = node_panel
	_zone_panel = zone_panel
	_town_panel = town_panel
	
	_connect_signals()

func _connect_signals():
	_node_panel.harvest_pressed.connect(_on_harvest_pressed)
	_node_panel.combat_pressed.connect(_on_combat_pressed)
	
	_zone_panel.rest_pressed.connect(_on_rest_pressed)
	_zone_panel.craft_pressed.connect(_on_craft_pressed)
	
	_town_panel.rest_pressed.connect(_on_rest_pressed)
	_town_panel.craft_pressed.connect(_on_craft_pressed)

func _on_harvest_pressed():
	var logs: Array[String] = GameState.act_in_current_node(GameConstants.ACTION_HARVEST)
	_emit_logs(logs)
	state_changed.emit()

func _on_combat_pressed():
	var logs: Array[String] = GameState.act_in_current_node(GameConstants.ACTION_COMBAT)
	_emit_logs(logs)
	state_changed.emit()

func _on_rest_pressed():
	var logs: Array[String] = GameState.rest()
	_emit_logs(logs)
	state_changed.emit()

func _on_craft_pressed():
	# Hardcoded "plank" as per original Main.gd logic, will be improved in Phase 5
	var logs: Array[String] = GameState.start_craft(GameConstants.RECIPE_PLANK)
	_emit_logs(logs)
	state_changed.emit()

func _emit_logs(logs):
	if logs is Array:
		for line in logs:
			log_produced.emit(str(line))
	else:
		log_produced.emit(str(logs))
