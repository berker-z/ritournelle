extends Control

signal close_requested
signal rest_pressed
signal craft_pressed
signal open_map

@onready var info_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/InfoLabel
@onready var info_box: Control = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/InfoBox
@onready var rest_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ActionRow/RestButton
@onready var craft_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ActionRow/CraftButton
@onready var map_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ActionRow/MapButton
@onready var close_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var action_bar = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/BottomRow/ActionBar

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	rest_button.pressed.connect(func(): emit_signal("rest_pressed"))
	craft_button.pressed.connect(func(): emit_signal("craft_pressed"))
	map_button.pressed.connect(func(): emit_signal("open_map"))
	# ActionBar handles its own signals

func refresh(info_text: String):
	info_label.text = info_text

func set_enabled(has_character: bool):
	rest_button.disabled = not has_character
	craft_button.disabled = not has_character
	map_button.disabled = not has_character
	action_bar.set_enabled(has_character)

func set_log_lines(lines: Array):
	if info_box:
		info_box.set_lines(lines)
		info_box.scroll_to_end()

func _on_close_pressed():
	emit_signal("close_requested")
