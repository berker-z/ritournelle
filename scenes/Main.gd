extends Control

# UI references
@onready var log_box: Control = $ScrollContainer/MarginContainer/VBoxContainer/LogBox
@onready var status_label: Label = $ScrollContainer/MarginContainer/VBoxContainer/Status
@onready var map_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/NavigationRow/MapButton
@onready var primary_action_bar: Control = $ScrollContainer/MarginContainer/VBoxContainer/NavigationRow/PrimaryActionBar
@onready var inventory_panel: Control = $InventoryPanel
@onready var skills_panel: Control = $SkillsPanel
@onready var map_panel: Control = $MapPanel
@onready var town_panel: Control = $TownPanel
@onready var zone_panel: Control = $ZonePanel
@onready var node_panel: Control = $NodePanel
@onready var account_panel: Control = $AccountPanel

var _inventory_skills_controller
var _account_controller
var _navigation_controller
var _action_controller
var _log_lines: Array[String] = []

func _ready():
	_setup_controllers()
	_connect_buttons()
	_append_log("Pick or create an account to begin.")
	
	# Listen to global state changes
	GameState.state_changed.connect(_on_state_changed)
	
	if _account_controller:
		_account_controller.refresh_lists()
		_account_controller.sync_visibility()
	_refresh_status()
	_refresh_visibility()
	_refresh_open_panels()

func _setup_controllers():
	_account_controller = preload("res://scripts/controllers/account_controller.gd").new()
	add_child(_account_controller)
	_account_controller.init(account_panel)
	_account_controller.log_produced.connect(_append_logs_variant)
	_account_controller.state_changed.connect(_on_state_changed)

	_inventory_skills_controller = preload("res://scripts/controllers/inventory_skills_controller.gd").new()
	add_child(_inventory_skills_controller)
	_inventory_skills_controller.init(inventory_panel, skills_panel)
	_inventory_skills_controller.log_produced.connect(_append_logs_variant)
	_inventory_skills_controller.state_changed.connect(_on_state_changed)
	_inventory_skills_controller.save_exit_requested.connect(_on_save_exit_pressed)

	_navigation_controller = preload("res://scripts/controllers/navigation_controller.gd").new()
	add_child(_navigation_controller)
	_navigation_controller.init(map_panel, town_panel, zone_panel, node_panel)
	_navigation_controller.log_produced.connect(_append_logs_variant)
	_navigation_controller.state_changed.connect(_on_state_changed)

	_action_controller = preload("res://scripts/controllers/action_controller.gd").new()
	add_child(_action_controller)
	_action_controller.init(node_panel, zone_panel, town_panel)
	_action_controller.log_produced.connect(_append_logs_variant)
	_action_controller.state_changed.connect(_on_state_changed)

	# Town Controller removed. Signals wired manually in connect_buttons or implicitly by other controllers.

func _process(delta):
	var updates = GameState.tick(delta)
	if updates.size() > 0:
		_append_logs(updates)
		_refresh_status()
		_refresh_open_panels()

func _connect_buttons():
	map_button.pressed.connect(func(): _navigation_controller._on_open_map_requested())
	
	# SignalBus connections for global actions
	SignalBus.inventory_requested.connect(_on_inventory_pressed)
	SignalBus.skills_requested.connect(_on_skills_pressed)
	SignalBus.save_exit_requested.connect(_on_save_exit_pressed)

	# Close requests are still handled here for now, or could move to controller
	map_panel.close_requested.connect(func(): map_panel.visible = false)
	town_panel.close_requested.connect(func(): town_panel.visible = false)
	zone_panel.close_requested.connect(func(): zone_panel.visible = false)
	node_panel.close_requested.connect(func(): 
		node_panel.visible = false
		var sub = GameState.get_current_submap()
		if sub != "":
			if _navigation_controller:
				_navigation_controller._on_open_zone_from_node()
	)
	
	# Other signals are handled by controllers init() wiring
	# ActionBar signals (open_inventory, etc.) are now handled via SignalBus, so panel proxying is removed.
	
	# Town Panel signals (manual wiring since TownController is gone)
	town_panel.open_map.connect(func(): _navigation_controller._on_open_map_requested())
	# Rest/Craft handled by ActionController via init wiring
	


func _on_state_changed():
	_refresh_status()
	_refresh_open_panels()

func _append_logs_variant(msg):
	# Controllers might emit Variant (String or Array)
	# But we defined signal log_produced(message) which is usually one arg
	# Check if message is Array or String
	# Actually my controller code emits strings line by line in loop for Array.
	# So msg is String.
	_append_log(str(msg))

func _on_inventory_pressed():
	if _inventory_skills_controller:
		_inventory_skills_controller.request_inventory()

func _on_skills_pressed():
	if _inventory_skills_controller:
		_inventory_skills_controller.request_skills()

func _on_save_exit_pressed():
	if GameState.has_active_character():
		SaveSystem.save_character(GameState.account_name, GameState.player)
	_append_log("Saved. Exiting.")
	get_tree().quit()


# Removed _on_harvest_pressed, _on_combat_pressed, _on_return_pressed, _on_craft_pressed, _on_rest_pressed, _on_map_pressed
# Removed _on_map_zone_selected, _on_open_zone_from_node, _on_move_to_node_requested, _do_rest, _do_craft


func _append_log(line: String):
	_log_lines.append(line)
	if _log_lines.size() > 50:
		_log_lines.remove_at(0)
	_refresh_log_outputs()

func _append_logs(lines: Array):
	for line in lines:
		_append_log(str(line))

func _refresh_log_outputs():
	if log_box != null:
		log_box.set_lines(_log_lines)
		log_box.scroll_to_end()
	if node_panel != null:
		node_panel.set_log_lines(_log_lines)

func _refresh_status():
	var p = GameState.player
	var status_lines: Array = []
	if not GameState.has_account_selected():
		status_lines.append("No account selected.")
	elif p == null:
		status_lines.append("No active character. Create or select one.")
	else:
		status_lines.append("Location: %s" % GameState.get_location_text())
		status_lines.append("HP %d/%d | Energy %.1f/%.1f" % [p.stats.hp, p.stats.hp_max, p.stats.energy, p.stats.energy_max])
		var equipped_entries = GameState.get_equipped_entries()
		equipped_entries.sort_custom(func(a, b): return a.get("slot", "") < b.get("slot", ""))
		var eq_parts: Array = []
		for entry in equipped_entries:
			var slot = entry.get("slot", "")
			var name = entry.get("name", "")
			eq_parts.append("%s: %s" % [slot.capitalize(), name if name != "" else "Empty"])
		status_lines.append("Equipped: " + ", ".join(eq_parts))
		status_lines.append("Open Inventory/Skills to manage gear and view XP.")
	status_label.text = "\n".join(status_lines)
	_set_action_buttons_enabled(p != null)
	if _inventory_skills_controller:
		_inventory_skills_controller.refresh_if_visible()
	_refresh_open_panels()

# Removed _refresh_map_panel, _open_town_panel, _open_zone_panel, _open_node_panel
# _hide_sub_panels is kept for now or removed if no longer used.
# _set_action_buttons_enabled uses it.
func _hide_sub_panels():
	map_panel.visible = false
	town_panel.visible = false
	zone_panel.visible = false
	node_panel.visible = false


func _refresh_open_panels():
	var has_character = GameState.has_active_character()
	if _account_controller:
		_account_controller.refresh_lists()
		_account_controller.sync_visibility()
	primary_action_bar.set_enabled(has_character)
	if not has_character:
		_hide_sub_panels()
	
	if _navigation_controller:
		# Navigation controller handles map, town, zone, node panels
		_navigation_controller.refresh_panels()
	
	if node_panel.visible:
		_refresh_log_outputs()

func _refresh_visibility():
	if _account_controller:
		_account_controller.sync_visibility()
	if not GameState.has_active_character():
		inventory_panel.visible = false
		skills_panel.visible = false
		_hide_sub_panels()

func _set_action_buttons_enabled(enabled: bool):
	map_button.disabled = not enabled
	primary_action_bar.set_enabled(enabled)
	map_panel.set_enabled(enabled)
	town_panel.set_enabled(enabled)
	zone_panel.set_enabled(enabled)
	node_panel.set_enabled(enabled)
	if not enabled:
		inventory_panel.visible = false
		skills_panel.visible = false
		_hide_sub_panels()
