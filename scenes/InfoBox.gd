extends Control

@onready var text_label: RichTextLabel = $PanelContainer/MarginContainer/ScrollContainer/RichTextLabel

func set_text(value: String):
	text_label.text = value

func set_lines(lines: Array):
	text_label.text = "\n".join(lines)

func scroll_to_end():
	text_label.scroll_to_line(text_label.get_line_count())
