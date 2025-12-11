extends Node

var town_panel: Control

var _rest_cb: Callable
var _craft_cb: Callable
var _open_map_cb: Callable
var _open_inventory_cb: Callable
var _open_skills_cb: Callable
var _save_exit_cb: Callable

func init(town: Control, rest_cb: Callable, craft_cb: Callable, open_map_cb: Callable, open_inventory_cb: Callable, open_skills_cb: Callable, save_exit_cb: Callable):
	town_panel = town
	_rest_cb = rest_cb
	_craft_cb = craft_cb
	_open_map_cb = open_map_cb
	_open_inventory_cb = open_inventory_cb
	_open_skills_cb = open_skills_cb
	_save_exit_cb = save_exit_cb

	if town_panel == null:
		return
	if town_panel.has_signal("rest_pressed"):
		town_panel.rest_pressed.connect(_on_rest)
	if town_panel.has_signal("craft_pressed"):
		town_panel.craft_pressed.connect(_on_craft)
	if town_panel.has_signal("open_map"):
		town_panel.open_map.connect(_on_open_map)
	if town_panel.has_signal("open_inventory"):
		town_panel.open_inventory.connect(_on_open_inventory)
	if town_panel.has_signal("open_skills"):
		town_panel.open_skills.connect(_on_open_skills)
	if town_panel.has_signal("save_exit"):
		town_panel.save_exit.connect(_on_save_exit)

func _on_rest():
	_rest_cb.call()

func _on_craft():
	_craft_cb.call()

func _on_open_map():
	_open_map_cb.call()

func _on_open_inventory():
	_open_inventory_cb.call()

func _on_open_skills():
	_open_skills_cb.call()

func _on_save_exit():
	_save_exit_cb.call()
