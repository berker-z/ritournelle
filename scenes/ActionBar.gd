extends HBoxContainer

@onready var inventory_button: Button = $InventoryButton
@onready var skills_button: Button = $SkillsButton
@onready var save_exit_button: Button = $SaveExitButton

func _ready():
	inventory_button.pressed.connect(func(): SignalBus.inventory_requested.emit())
	skills_button.pressed.connect(func(): SignalBus.skills_requested.emit())
	save_exit_button.pressed.connect(func(): SignalBus.save_exit_requested.emit())

func set_enabled(has_character: bool):
	inventory_button.disabled = not has_character
	skills_button.disabled = not has_character
	save_exit_button.disabled = false
