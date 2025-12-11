extends Node

var panel: Control

var _log: Callable
var _refresh_status: Callable
var _refresh_open_panels: Callable

func init(account_panel: Control, log_func: Callable, refresh_status_func: Callable, refresh_open_panels_func: Callable):
	panel = account_panel
	_log = log_func
	_refresh_status = refresh_status_func
	_refresh_open_panels = refresh_open_panels_func
	if panel == null:
		return
	if panel.has_signal("create_account_requested"):
		panel.create_account_requested.connect(_on_create_account)
	if panel.has_signal("select_account_requested"):
		panel.select_account_requested.connect(_on_select_account)
	if panel.has_signal("create_character_requested"):
		panel.create_character_requested.connect(_on_create_character)
	if panel.has_signal("select_character_requested"):
		panel.select_character_requested.connect(_on_select_character)
	if panel.has_signal("delete_character_requested"):
		panel.delete_character_requested.connect(_on_delete_character)
	if panel.has_signal("close_requested"):
		panel.close_requested.connect(func(): panel.visible = false)
	refresh_lists()
	sync_visibility()

func refresh_lists():
	if panel == null:
		return
	var accounts = GameState.list_accounts()
	panel.set_accounts(accounts)
	var has_account = GameState.has_account_selected()
	panel.set_enabled(has_account)
	var characters: Array = []
	if has_account:
		characters = GameState.get_character_names()
	panel.set_characters(characters)

func sync_visibility():
	if panel == null:
		return
	if GameState.has_active_character():
		panel.visible = false
	else:
		panel.visible = true

func _on_create_account(name: String):
	_log.call(GameState.create_account(name))
	refresh_lists()
	_refresh_status.call()
	_refresh_open_panels.call()
	sync_visibility()

func _on_select_account(name: String):
	_log.call(GameState.select_account(name))
	refresh_lists()
	_refresh_status.call()
	_refresh_open_panels.call()
	sync_visibility()

func _on_create_character(name: String, archetype: String):
	_log.call(GameState.create_character(name, archetype))
	refresh_lists()
	_refresh_status.call()
	_refresh_open_panels.call()
	sync_visibility()

func _on_select_character(name: String):
	_log.call(GameState.select_character_by_name(name))
	refresh_lists()
	_refresh_status.call()
	_refresh_open_panels.call()
	sync_visibility()

func _on_delete_character(name: String):
	_log.call(GameState.delete_character(name))
	refresh_lists()
	_refresh_status.call()
	_refresh_open_panels.call()
	sync_visibility()
