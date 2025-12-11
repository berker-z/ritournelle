extends RefCounted
class_name Account

const Character = preload("res://scripts/core/character.gd")
const Inventory = preload("res://scripts/core/inventory.gd")

var characters: Array = []
var active_index: int = -1
var shared_stash: Inventory = Inventory.new()

func add_character(character: Character):
	characters.append(character)
	active_index = characters.size() - 1

func set_active(index: int) -> bool:
	if index < 0 or index >= characters.size():
		return false
	active_index = index
	return true

func delete_character(index: int) -> bool:
	if index < 0 or index >= characters.size():
		return false
	characters.remove_at(index)
	if characters.is_empty():
		active_index = -1
	elif active_index >= characters.size():
		active_index = characters.size() - 1
	return true

func has_active() -> bool:
	return active_index >= 0 and active_index < characters.size()

func get_active() -> Character:
	if has_active():
		return characters[active_index]
	return null

func get_character_names() -> Array:
	var names: Array = []
	for c in characters:
		names.append(c.name)
	return names

func get_shared_stash() -> Inventory:
	return shared_stash

func to_dict() -> Dictionary:
	var chars: Array = []
	for c in characters:
		chars.append(c.to_dict())
	return {
		"characters": chars,
		"active_index": active_index,
		"shared_stash": shared_stash.to_dict()
	}

static func from_dict(data: Dictionary) -> Account:
	var account = Account.new()
	for c_data in data.get("characters", []):
		account.characters.append(Character.from_dict(c_data))
	account.active_index = int(data.get("active_index", -1))
	if account.active_index >= account.characters.size():
		account.active_index = account.characters.size() - 1
	account.shared_stash = Inventory.from_dict(data.get("shared_stash", {}))
	return account
