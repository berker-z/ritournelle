extends Control

var _ui_controller

func _ready():
	_ui_controller = preload("res://scenes/UIController.gd").new()
	add_child(_ui_controller)
	_ui_controller.init(self)
