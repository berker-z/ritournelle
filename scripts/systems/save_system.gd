extends Node

const Account = preload("res://scripts/core/account.gd")
const Character = preload("res://scripts/core/character.gd")
const Inventory = preload("res://scripts/core/inventory.gd")

const BASE_DIR := "res://userdata"
const STASH_FILE := "sharedstash.json"

func ensure_base_dir():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE_DIR))

func sanitize_name(raw: String, fallback_prefix: String) -> String:
	var name = raw.strip_edges()
	if name.is_empty():
		name = fallback_prefix
	var regex = RegEx.new()
	regex.compile("[^A-Za-z0-9_]+")
	name = regex.sub(name.replace(" ", "_"), "", true)
	if name.is_empty():
		name = fallback_prefix
	return name

func list_accounts() -> Array:
	ensure_base_dir()
	var dir = DirAccess.open(BASE_DIR)
	if dir == null:
		return []
	var names: Array = []
	dir.list_dir_begin()
	while true:
		var entry = dir.get_next()
		if entry == "":
			break
		if dir.current_is_dir() and not entry.begins_with("."):
			names.append(entry)
	dir.list_dir_end()
	names.sort()
	return names

func account_dir(account_name: String) -> String:
	return "%s/%s" % [BASE_DIR, account_name]

func ensure_account(account_name: String):
	ensure_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(account_dir(account_name)))

func create_account(raw_name: String) -> String:
	var cleaned = sanitize_name(raw_name, "account")
	var account_path = ProjectSettings.globalize_path(account_dir(cleaned))
	if not DirAccess.dir_exists_absolute(account_path):
		ensure_account(cleaned)
		_save_stash(cleaned, Inventory.new())
	return cleaned

func list_characters(account_name: String) -> Array:
	var names: Array = []
	var path = account_dir(account_name)
	var dir = DirAccess.open(path)
	if dir == null:
		return names
	dir.list_dir_begin()
	while true:
		var entry = dir.get_next()
		if entry == "":
			break
		if dir.current_is_dir():
			continue
		if entry == STASH_FILE:
			continue
		if entry.ends_with(".json"):
			names.append(entry.replace(".json", ""))
	dir.list_dir_end()
	names.sort()
	return names

func load_account(account_name: String) -> Account:
	ensure_account(account_name)
	var account = Account.new()
	account.shared_stash = _load_stash(account_name)
	var char_files = list_characters(account_name)
	for file_stub in char_files:
		var data = _read_json("%s/%s.json" % [account_dir(account_name), file_stub])
		if typeof(data) == TYPE_DICTIONARY:
			account.characters.append(Character.from_dict(data))
	return account

func save_character(account_name: String, character: Character) -> bool:
	ensure_account(account_name)
	var file_name = sanitize_name(character.name, "char")
	var path = "%s/%s.json" % [account_dir(account_name), file_name]
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Failed to open character save file for writing.")
		return false
	file.store_string(JSON.stringify(character.to_dict()))
	return true

func delete_character(account_name: String, character_name: String) -> bool:
	var file_name = sanitize_name(character_name, "char")
	var path = "%s/%s.json" % [account_dir(account_name), file_name]
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func save_shared_stash(account_name: String, stash: Inventory) -> bool:
	ensure_account(account_name)
	return _save_stash(account_name, stash)

func _save_stash(account_name: String, stash: Inventory) -> bool:
	var path = "%s/%s" % [account_dir(account_name), STASH_FILE]
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Failed to write shared stash.")
		return false
	file.store_string(JSON.stringify(stash.to_dict()))
	return true

func load_shared_stash(account_name: String) -> Inventory:
	return _load_stash(account_name)

func _load_stash(account_name: String) -> Inventory:
	var path = "%s/%s" % [account_dir(account_name), STASH_FILE]
	if not FileAccess.file_exists(path):
		return Inventory.new()
	var data = _read_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		return Inventory.new()
	return Inventory.from_dict(data)

func _read_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content = file.get_as_text()
	return JSON.parse_string(content)
