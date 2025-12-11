class_name SessionService extends RefCounted

const Character = preload("res://scripts/core/character.gd")
const Account = preload("res://scripts/core/account.gd")
# SaveSystem and CraftingSystem are Autoloads, so accessible globally.

func list_accounts() -> Array[String]:
	return SaveSystem.list_accounts()

func select_account(name: String) -> Dictionary:
	if name.is_empty():
		return {"error": "Pick an account from the list."}
	if not SaveSystem.list_accounts().has(name):
		return {"error": "Account not found."}
	
	var account = SaveSystem.load_account(name)
	CraftingSystem.reset()
	return {"account": account, "log": "Selected account: %s" % name}

func create_account(raw_name: String) -> Dictionary:
	var target_name = SaveSystem.sanitize_name(raw_name, "account")
	var existed = SaveSystem.list_accounts().has(target_name)
	var created_name = SaveSystem.create_account(raw_name)
	var account = SaveSystem.load_account(created_name)
	CraftingSystem.reset()
	var msg = "Selected existing account: %s" % created_name if existed else "Created account: %s" % created_name
	return {"account": account, "account_name": created_name, "log": msg}

func get_character_names(account: Account) -> Array[String]:
	if account == null:
		return []
	return account.get_character_names()

func create_character(account: Account, account_name: String, name: String, background: String) -> Dictionary:
	if account == null:
		return {"error": "Select or create an account first."}
	var safe_name = name.strip_edges()
	if safe_name.is_empty():
		safe_name = "Wanderer"
		
	var file_stub = SaveSystem.sanitize_name(safe_name, "char")
	for existing_name in account.get_character_names():
		if existing_name == safe_name:
			return {"error": "Character with that name already exists."}
		if SaveSystem.sanitize_name(existing_name, "char") == file_stub:
			return {"error": "Character with that name already exists."}
			
	var character = Character.new_with_background(safe_name, background)
	_seed_inventory(character)
	account.characters.append(character)
	# Set as active implicitly by return?
	# GameState usually sets player, location, saves.
	character.location = GameConstants.SUBMAP_TOWN
	SaveSystem.save_character(account_name, character)
	CraftingSystem.reset()
	return {"character": character, "log": "Created %s (%s) and set active." % [safe_name, background]}

func select_character_by_name(account: Account, character_name: String) -> Dictionary:
	if account == null:
		return {"error": "Select or create an account first."}
	for c in account.characters:
		if c.name == character_name:
			CraftingSystem.reset()
			return {"character": c, "log": "Selected %s." % c.name}
	return {"error": "Character not found."}

func delete_character(account: Account, account_name: String, character_name: String, current_player: Character) -> Dictionary:
	if account == null:
		return {"error": "Select or create an account first."}
	for c in account.characters:
		if c.name == character_name:
			account.characters.erase(c)
			SaveSystem.delete_character(account_name, character_name)
			var reset_player = (current_player == c)
			if reset_player:
				CraftingSystem.reset()
			return {"success": true, "reset_player": reset_player, "log": "Deleted %s." % character_name}
	return {"error": "Character not found."}

func _seed_inventory(character: Character):
	character.inventory.add("log", 3)
	character.inventory.add("herb", 2)
	character.inventory.add("camping_supplies", 100)
	character.inventory.add("rusty_sword", 1)
	character.inventory.add("wooden_sword", 1)
	character.inventory.add("leather_hat", 1)
	character.inventory.add("leather_armor", 1)
