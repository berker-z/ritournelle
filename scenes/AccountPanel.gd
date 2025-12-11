extends Control

signal create_account_requested(name: String)
signal select_account_requested(name: String)
signal create_character_requested(name: String, archetype: String)
signal select_character_requested(name: String)
signal delete_character_requested(name: String)
signal close_requested

@onready var account_select: OptionButton = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/AccountSection/AccountSelectRow/AccountSelect
@onready var select_account_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/AccountSection/AccountSelectRow/SelectAccountButton
@onready var account_name_input: LineEdit = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/AccountSection/AccountCreateRow/AccountNameInput
@onready var create_account_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/AccountSection/AccountCreateRow/CreateAccountButton

@onready var name_input: LineEdit = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/CharacterSection/CharacterNameRow/NameInput
@onready var create_harvester_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/CharacterSection/CreateRow/CreateHarvesterButton
@onready var create_fighter_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/CharacterSection/CreateRow/CreateFighterButton
@onready var character_select: OptionButton = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/CharacterSection/ManageRow/CharacterSelect
@onready var select_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/CharacterSection/ManageRow/SelectButton
@onready var delete_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/CharacterSection/ManageRow/DeleteButton

@onready var close_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton

func _ready():
	close_button.pressed.connect(func(): emit_signal("close_requested"))
	select_account_button.pressed.connect(_emit_select_account)
	create_account_button.pressed.connect(_emit_create_account)
	create_harvester_button.pressed.connect(func(): _emit_create_character("harvester"))
	create_fighter_button.pressed.connect(func(): _emit_create_character("fighter"))
	select_button.pressed.connect(_emit_select_character)
	delete_button.pressed.connect(_emit_delete_character)

func set_accounts(accounts: Array):
	account_select.clear()
	for i in range(accounts.size()):
		account_select.add_item(accounts[i], i)
	if accounts.size() > 0:
		account_select.select(0)
	else:
		account_select.add_item("No accounts", -1)
		account_select.select(0)
	account_select.disabled = accounts.size() == 0
	select_account_button.disabled = accounts.size() == 0

func set_characters(characters: Array):
	character_select.clear()
	for i in range(characters.size()):
		character_select.add_item(characters[i], i)
	if characters.size() > 0:
		character_select.select(0)
	else:
		character_select.add_item("No characters", -1)
		character_select.select(0)
	character_select.disabled = characters.size() == 0
	select_button.disabled = characters.size() == 0
	delete_button.disabled = characters.size() == 0

func set_enabled(has_active_account: bool):
	# If no account, disable character controls
	var enabled = has_active_account
	name_input.editable = enabled
	create_harvester_button.disabled = not enabled
	create_fighter_button.disabled = not enabled
	character_select.disabled = not enabled or character_select.get_item_count() == 0
	select_button.disabled = not enabled or character_select.disabled
	delete_button.disabled = not enabled or character_select.disabled
	close_button.disabled = not has_active_account

func _emit_create_account():
	emit_signal("create_account_requested", account_name_input.text)
	account_name_input.text = ""

func _emit_select_account():
	if account_select.disabled:
		return
	var name = account_select.get_item_text(account_select.selected)
	emit_signal("select_account_requested", name)

func _emit_create_character(archetype: String):
	emit_signal("create_character_requested", name_input.text, archetype)
	name_input.text = ""

func _emit_select_character():
	if character_select.disabled:
		return
	var name = character_select.get_item_text(character_select.selected)
	emit_signal("select_character_requested", name)

func _emit_delete_character():
	if character_select.disabled:
		return
	var name = character_select.get_item_text(character_select.selected)
	emit_signal("delete_character_requested", name)
