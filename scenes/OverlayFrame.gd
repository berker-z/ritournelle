extends Control

signal open_inventory
signal open_skills
signal save_exit

@onready var _action_bar: Node = $PanelContainer/MarginContainer/VBoxContainer/ActionBar
@onready var _status_bar: Control = $PanelContainer/MarginContainer/VBoxContainer/StatusBar
@onready var _info_box: Control = $PanelContainer/MarginContainer/VBoxContainer/InfoBox

func _ready():
	if _action_bar.has_signal("open_inventory"):
		_action_bar.open_inventory.connect(func(): emit_signal("open_inventory"))
	if _action_bar.has_signal("open_skills"):
		_action_bar.open_skills.connect(func(): emit_signal("open_skills"))
	if _action_bar.has_signal("save_exit"):
		_action_bar.save_exit.connect(func(): emit_signal("save_exit"))

func set_status_lines(lines: Array) -> void:
	if _status_bar:
		_status_bar.set_lines(lines)

func set_log_lines(lines: Array) -> void:
	if _info_box:
		_info_box.set_lines(lines)
		_info_box.scroll_to_end()

func set_enabled(has_character: bool) -> void:
	if _action_bar:
		_action_bar.set_enabled(has_character)
