class_name SessionService extends RefCounted

const Character = preload("res://scripts/core/character.gd")
const Account = preload("res://scripts/core/account.gd")
const AccountSelectionResult = preload("res://scripts/core/account_selection_result.gd")
const AccountCreationResult = preload("res://scripts/core/account_creation_result.gd")
const CharacterCreationResult = preload("res://scripts/core/character_creation_result.gd")
const CharacterSelectionResult = preload("res://scripts/core/character_selection_result.gd")
const CharacterDeletionResult = preload("res://scripts/core/character_deletion_result.gd")
# SaveSystem and CraftingSystem are Autoloads, so accessible globally.

func list_accounts() -> Array[String]:
	return SaveSystem.list_accounts()

func select_account(name: String) -> AccountSelectionResult:
	var result: AccountSelectionResult = AccountSelectionResult.new()
	if name.is_empty():
		result.error = "Pick an account from the list."
		return result
	if not SaveSystem.list_accounts().has(name):
		result.error = "Account not found."
		return result

	result.account = SaveSystem.load_account(name)
	result.log = "Selected account: %s" % name
	return result

func create_account(raw_name: String) -> AccountCreationResult:
	var result: AccountCreationResult = AccountCreationResult.new()
	var target_name = SaveSystem.sanitize_name(raw_name, "account")
	var existed = SaveSystem.list_accounts().has(target_name)
	var created_name = SaveSystem.create_account(raw_name)
	var account = SaveSystem.load_account(created_name)
	var msg = "Selected existing account: %s" % created_name if existed else "Created account: %s" % created_name
	result.account = account
	result.account_name = created_name
	result.log = msg
	return result

func get_character_names(account: Account) -> Array[String]:
	var names: Array[String] = []
	if account == null:
		return names
	return account.get_character_names()

func create_character(account: Account, account_name: String, name: String, background: String) -> CharacterCreationResult:
	var result: CharacterCreationResult = CharacterCreationResult.new()
	if account == null:
		result.error = "Select or create an account first."
		return result
	var safe_name = name.strip_edges()
	if safe_name.is_empty():
		safe_name = "Wanderer"

	var file_stub = SaveSystem.sanitize_name(safe_name, "char")
	for existing_name in account.get_character_names():
		if existing_name == safe_name:
			result.error = "Character with that name already exists."
			return result
		if SaveSystem.sanitize_name(existing_name, "char") == file_stub:
			result.error = "Character with that name already exists."
			return result

	var character = Character.new_with_background(safe_name, background)
	_seed_inventory(character)
	account.characters.append(character)
	character.location = GameConstants.SUBMAP_TOWN
	SaveSystem.save_character(account_name, character)
	result.character = character
	result.log = "Created %s (%s) and set active." % [safe_name, background]
	return result

func select_character_by_name(account: Account, character_name: String) -> CharacterSelectionResult:
	var result: CharacterSelectionResult = CharacterSelectionResult.new()
	if account == null:
		result.error = "Select or create an account first."
		return result
	for c in account.characters:
		if c.name == character_name:
			result.character = c
			result.log = "Selected %s." % c.name
			return result
	result.error = "Character not found."
	return result

func delete_character(account: Account, account_name: String, character_name: String, current_player: Character) -> CharacterDeletionResult:
	var result: CharacterDeletionResult = CharacterDeletionResult.new()
	if account == null:
		result.error = "Select or create an account first."
		return result
	for c in account.characters:
		if c.name == character_name:
			account.characters.erase(c)
			SaveSystem.delete_character(account_name, character_name)
			var reset_player: bool = (current_player == c)
			result.success = true
			result.reset_player = reset_player
			result.log = "Deleted %s." % character_name
			return result
	result.error = "Character not found."
	return result

func _seed_inventory(character: Character):
	character.inventory.add("log", 3)
	character.inventory.add("herb", 2)
	character.inventory.add("camping_supplies", 100)
	character.inventory.add("rusty_sword", 1)
	character.inventory.add("wooden_sword", 1)
	character.inventory.add("leather_hat", 1)
	character.inventory.add("leather_armor", 1)
