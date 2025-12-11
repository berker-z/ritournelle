class_name AccountController extends Node

signal log_produced(message)
signal state_changed

var _panel: Control

func init(account_panel: Control):
	_panel = account_panel
	
	if _panel == null:
		return
		
	_connect_signals()
	refresh_lists()
	sync_visibility()

func _connect_signals():
	if _panel.has_signal("create_account_requested"):
		_panel.create_account_requested.connect(_on_create_account)
	if _panel.has_signal("select_account_requested"):
		_panel.select_account_requested.connect(_on_select_account)
	if _panel.has_signal("create_character_requested"):
		_panel.create_character_requested.connect(_on_create_character)
	if _panel.has_signal("select_character_requested"):
		_panel.select_character_requested.connect(_on_select_character)
	if _panel.has_signal("delete_character_requested"):
		_panel.delete_character_requested.connect(_on_delete_character)
	if _panel.has_signal("close_requested"):
		_panel.close_requested.connect(func(): _panel.visible = false)

func refresh_lists():
	if _panel == null:
		return
	var accounts = GameState.list_accounts()
	_panel.set_accounts(accounts)
		
	var has_account = GameState.has_account_selected()
	_panel.set_enabled(has_account)
		
	var characters: Array[String] = []
	if has_account:
		characters = GameState.get_character_names()
	_panel.set_characters(characters)

func sync_visibility():
	if _panel == null:
		return
	if GameState.has_active_character():
		_panel.visible = false
	else:
		_panel.visible = true

func _on_create_account(name: String):
	var logs: Array[String] = GameState.create_account(name)
	_emit_logs(logs)
	refresh_lists()
	state_changed.emit()
	sync_visibility()

func _on_select_account(name: String):
	var logs: Array[String] = GameState.select_account(name)
	_emit_logs(logs)
	refresh_lists()
	state_changed.emit()
	sync_visibility()

func _on_create_character(name: String, archetype: String):
	var logs: Array[String] = GameState.create_character(name, archetype)
	_emit_logs(logs)
	refresh_lists()
	state_changed.emit()
	sync_visibility()

func _on_select_character(name: String):
	var logs: Array[String] = GameState.select_character_by_name(name)
	_emit_logs(logs)
	refresh_lists()
	state_changed.emit()
	sync_visibility()

func _on_delete_character(name: String):
	var logs: Array[String] = GameState.delete_character(name)
	_emit_logs(logs)
	refresh_lists()
	state_changed.emit()
	sync_visibility()

func _emit_logs(logs):
	if logs is Array:
		for line in logs:
			log_produced.emit(str(line))
	else:
		log_produced.emit(str(logs))
