extends Control
# Keep this scene internal; no global class_name to avoid conflicts.
# class_name SkillsPanel

@onready var skills_list: ItemList = $Panel/MarginContainer/VBoxContainer/SkillsList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/SkillsHeader/CloseSkillsButton

func _ready():
	close_button.pressed.connect(close_panel)

func open_panel(skill_lines: Array):
	visible = true
	refresh(skill_lines)

func close_panel():
	visible = false

func refresh(skill_lines: Array):
	skills_list.clear()
	for line in skill_lines:
		skills_list.add_item(str(line))
