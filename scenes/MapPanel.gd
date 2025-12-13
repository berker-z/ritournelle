extends Control

signal close_requested
signal select_zone(submap: String)

@onready var info_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/InfoLabel
@onready var overlay_frame: Control = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/OverlayFrame
@onready var close_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var town_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Zones/Row1/TownButton
@onready var lake_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Zones/Row1/LakeButton
@onready var forest_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Zones/Row2/ForestButton
@onready var mountain_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Zones/Row2/MountainButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	town_button.pressed.connect(func(): _emit_zone("town"))
	lake_button.pressed.connect(func(): _emit_zone("lake"))
	forest_button.pressed.connect(func(): _emit_zone("forest"))
	mountain_button.pressed.connect(func(): _emit_zone("mountain"))
	# ActionBar signals are wired via controllers

func refresh(current_location: String):
	info_label.text = "Current: %s" % current_location

func set_enabled(has_character: bool):
	overlay_frame.set_enabled(has_character)
	town_button.disabled = not has_character
	lake_button.disabled = not has_character
	forest_button.disabled = not has_character
	mountain_button.disabled = not has_character

func set_log_lines(lines: Array):
	overlay_frame.set_log_lines(lines)

func set_status_lines(lines: Array):
	overlay_frame.set_status_lines(lines)

func get_overlay_frame() -> Control:
	return overlay_frame

func _emit_zone(submap: String):
	emit_signal("select_zone", submap)

func _on_close_pressed():
	emit_signal("close_requested")
