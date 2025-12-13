extends Control

@onready var _label: Label = $Panel/MarginContainer/Label

func set_lines(lines: Array) -> void:
	var texts := PackedStringArray()
	for line in lines:
		texts.append(str(line))
	_label.text = "\n".join(texts)
