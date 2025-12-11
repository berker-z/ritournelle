extends Control

signal close_requested
signal select_zone(submap: String)

@onready var info_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/InfoLabel
@onready var action_bar = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ActionRow/ActionBar
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
	# ActionBar handles its own signals via SignalBus

func refresh(current_location: String):
	info_label.text = "Current: %s" % current_location

func set_enabled(has_character: bool):
	action_bar.set_enabled(has_character)
	town_button.disabled = not has_character
	lake_button.disabled = not has_character
	forest_button.disabled = not has_character
	mountain_button.disabled = not has_character

func _emit_zone(submap: String):
	emit_signal("select_zone", submap)

func _on_close_pressed():
	visible = false
	emit_signal("close_requested")
