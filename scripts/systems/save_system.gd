extends Node

const Account = preload("res://scripts/core/account.gd")
const Character = preload("res://scripts/core/character.gd")
const Inventory = preload("res://scripts/core/inventory.gd")

const PRIMARY_BASE_DIR := "res://userdata"
const FALLBACK_BASE_DIR := "user://userdata"
const STASH_FILE := "sharedstash.json"

func _base_dirs() -> Array:
	return [PRIMARY_BASE_DIR, FALLBACK_BASE_DIR]

func ensure_base_dirs():
	for dir in _base_dirs():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

func _first_existing_base_dir() -> String:
	for dir in _base_dirs():
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
			return dir
	return PRIMARY_BASE_DIR

func _base_dir_for_account(account_name: String) -> String:
	for dir in _base_dirs():
		var path = ProjectSettings.globalize_path(account_dir(account_name, dir))
		if DirAccess.dir_exists_absolute(path):
			return dir
	return _first_existing_base_dir()

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
	ensure_base_dirs()
	var names: Array = []
	var seen := {}
	for base_dir in _base_dirs():
		var dir = DirAccess.open(base_dir)
		if dir == null:
			continue
		dir.list_dir_begin()
		while true:
			var entry = dir.get_next()
			if entry == "":
				break
			if dir.current_is_dir() and not entry.begins_with(".") and not seen.has(entry):
				seen[entry] = true
				names.append(entry)
		dir.list_dir_end()
	names.sort()
	return names

func account_dir(account_name: String, base_dir: String = PRIMARY_BASE_DIR) -> String:
	return "%s/%s" % [base_dir, account_name]

func ensure_account(account_name: String):
	ensure_base_dirs()
	for base_dir in _base_dirs():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(account_dir(account_name, base_dir)))

func create_account(raw_name: String) -> String:
	var cleaned = sanitize_name(raw_name, "account")
	ensure_account(cleaned)
	_save_stash_all(cleaned, Inventory.new())
	return cleaned

func list_characters(account_name: String) -> Array:
	var names: Array = []
	var seen := {}
	for base_dir in _base_dirs():
		var path = account_dir(account_name, base_dir)
		var dir = DirAccess.open(path)
		if dir == null:
			continue
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
				var cleaned = entry.replace(".json", "")
				if not seen.has(cleaned):
					seen[cleaned] = true
					names.append(cleaned)
		dir.list_dir_end()
	names.sort()
	return names

func load_account(account_name: String) -> Account:
	ensure_account(account_name)
	var base_dir = _base_dir_for_account(account_name)
	var account = Account.new()
	account.shared_stash = _load_stash(account_name, base_dir)
	for file_stub in list_characters(account_name):
		var loaded := false
		for dir in _base_dirs():
			var path = "%s/%s.json" % [account_dir(account_name, dir), file_stub]
			if FileAccess.file_exists(path):
				var data = _read_json(path)
				if typeof(data) == TYPE_DICTIONARY:
					account.characters.append(Character.from_dict(data))
					loaded = true
				break
		if not loaded:
			push_warning("Failed to load character %s for account %s" % [file_stub, account_name])
	return account

func save_character(account_name: String, character: Character) -> bool:
	ensure_account(account_name)
	var ok := true
	for base_dir in _base_dirs():
		var file_name = sanitize_name(character.name, "char")
		var path = "%s/%s.json" % [account_dir(account_name, base_dir), file_name]
		if not _write_json(path, character.to_dict()):
			ok = false
	return ok

func delete_character(account_name: String, character_name: String) -> bool:
	var success := false
	var file_name = sanitize_name(character_name, "char")
	for base_dir in _base_dirs():
		var path = "%s/%s.json" % [account_dir(account_name, base_dir), file_name]
		if FileAccess.file_exists(path):
			success = DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK or success
	return success

func save_shared_stash(account_name: String, stash: Inventory) -> bool:
	ensure_account(account_name)
	return _save_stash_all(account_name, stash)

func _save_stash(account_name: String, stash: Inventory) -> bool:
	var path = "%s/%s" % [account_dir(account_name), STASH_FILE]
	return _write_json(path, stash.to_dict())

func _save_stash_all(account_name: String, stash: Inventory) -> bool:
	var ok := true
	for base_dir in _base_dirs():
		var path = "%s/%s" % [account_dir(account_name, base_dir), STASH_FILE]
		if not _write_json(path, stash.to_dict()):
			ok = false
	return ok

func load_shared_stash(account_name: String) -> Inventory:
	return _load_stash(account_name, _first_existing_base_dir())

func _load_stash(account_name: String, base_dir: String) -> Inventory:
	for dir in _base_dirs():
		var path = "%s/%s" % [account_dir(account_name, dir), STASH_FILE]
		if FileAccess.file_exists(path):
			var data = _read_json(path)
			if typeof(data) == TYPE_DICTIONARY:
				return Inventory.from_dict(data)
	return Inventory.new()

func _read_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content = file.get_as_text()
	return JSON.parse_string(content)

func _write_json(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Failed to write file: %s" % path)
		return false
	file.store_string(JSON.stringify(data))
	return true
