extends Control

signal close_requested
signal open_map
signal open_zone
signal rest_pressed
signal craft_pressed
signal return_pressed
signal harvest_pressed
signal combat_pressed

@onready var title_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Header/Title
@onready var info_box: Control = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/InfoBox
@onready var close_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var map_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/MapButton
@onready var to_zone_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/ZoneButton
@onready var return_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/ReturnButton
@onready var harvest_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/HarvestButton
@onready var combat_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/CombatButton
@onready var rest_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/RestButton
@onready var craft_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/CraftButton
@onready var action_bar = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/BottomRow/ActionBar

var submap := ""
var node_id := ""

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	map_button.pressed.connect(func(): emit_signal("open_map"))
	to_zone_button.pressed.connect(func(): emit_signal("open_zone"))
	return_button.pressed.connect(func(): emit_signal("return_pressed"))
	harvest_button.pressed.connect(func(): emit_signal("harvest_pressed"))
	combat_button.pressed.connect(func(): emit_signal("combat_pressed"))
	rest_button.pressed.connect(func(): emit_signal("rest_pressed"))
	craft_button.pressed.connect(func(): emit_signal("craft_pressed"))
	# ActionBar signals are wired via controllers

func refresh(submap_name: String, node_name: String, info_text: String):
	submap = submap_name
	node_id = node_name
	title_label.text = "Node: %s" % node_name.replace("_", " ").capitalize()
	info_box.set_text(info_text)

func set_enabled(has_character: bool):
	var buttons = [
		map_button,
		to_zone_button,
		return_button,
		harvest_button,
		combat_button,
		rest_button,
		craft_button
	]
	for b in buttons:
		b.disabled = not has_character
	action_bar.set_enabled(has_character)

func set_log_lines(lines: Array):
	info_box.set_lines(lines)
	info_box.scroll_to_end()

func _on_close_pressed():
	emit_signal("close_requested")
