extends HBoxContainer

signal open_inventory
signal open_skills
signal save_exit

@onready var inventory_button: Button = $InventoryButton
@onready var skills_button: Button = $SkillsButton
@onready var save_exit_button: Button = $SaveExitButton

func _ready():
	inventory_button.pressed.connect(func(): emit_signal("open_inventory"))
	skills_button.pressed.connect(func(): emit_signal("open_skills"))
	save_exit_button.pressed.connect(func(): emit_signal("save_exit"))

func set_enabled(has_character: bool):
	inventory_button.disabled = not has_character
	skills_button.disabled = not has_character
	save_exit_button.disabled = false
