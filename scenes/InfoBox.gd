extends Control

@onready var text_label: RichTextLabel = $PanelContainer/MarginContainer/ScrollContainer/RichTextLabel

func set_text(value: String) -> void:
	text_label.text = value

func set_lines(lines: Array) -> void:
	var texts := PackedStringArray()
	for line in lines:
		texts.append(str(line))
	text_label.text = "\n".join(texts)

func scroll_to_end() -> void:
	var last_line_index: int = text_label.get_line_count() - 1
	if last_line_index < 0:
		last_line_index = 0
	text_label.scroll_to_line(last_line_index)
