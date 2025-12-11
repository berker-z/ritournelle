extends Control

signal close_requested
signal open_map
signal rest_pressed
signal craft_pressed
signal move_to_node(submap: String, node_id: String)
signal open_inventory
signal open_skills
signal save_exit

@onready var title_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Header/Title
@onready var info_box: Control = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/InfoBox
@onready var nodes_container: VBoxContainer = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Nodes/NodeList
@onready var close_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var rest_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/RestButton
@onready var craft_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/CraftButton
@onready var map_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/MapButton
@onready var action_bar = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/BottomRow/ActionBar

var submap: String = ""

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	rest_button.pressed.connect(func(): emit_signal("rest_pressed"))
	craft_button.pressed.connect(func(): emit_signal("craft_pressed"))
	map_button.pressed.connect(func(): emit_signal("open_map"))
	action_bar.open_inventory.connect(func(): emit_signal("open_inventory"))
	action_bar.open_skills.connect(func(): emit_signal("open_skills"))
	action_bar.save_exit.connect(func(): emit_signal("save_exit"))

func refresh(submap_name: String, node_ids: Array, current_node: String, info_text: String):
	submap = submap_name
	title_label.text = "Zone: %s" % submap_name.capitalize()
	if info_box.has_method("set_text"):
		info_box.set_text(info_text)
	_rebuild_nodes(node_ids, current_node)

func set_enabled(has_character: bool):
	rest_button.disabled = not has_character
	craft_button.disabled = not has_character
	map_button.disabled = not has_character
	action_bar.set_enabled(has_character)
	for button in nodes_container.get_children():
		if button is Button:
			button.disabled = not has_character

func _rebuild_nodes(node_ids: Array, current_node: String):
	for child in nodes_container.get_children():
		child.queue_free()
	for node_id in node_ids:
		var button = Button.new()
		button.text = _format_node_label(node_id, current_node)
		button.custom_minimum_size = Vector2(0, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): emit_signal("move_to_node", submap, node_id))
		nodes_container.add_child(button)

func _format_node_label(node_id: String, current_node: String) -> String:
	var name = node_id.replace("_", " ").capitalize()
	if node_id == current_node:
		name += " (Here)"
	return name

func _on_close_pressed():
	visible = false
	emit_signal("close_requested")
