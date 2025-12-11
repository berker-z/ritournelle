extends Control
# Keep this scene internal; no global class_name to avoid conflicts.
# class_name InventoryPanel

signal equip_item(item_id: String)
signal unequip_slot(slot: String)

@onready var equipped_list: ItemList = $Panel/MarginContainer/VBoxContainer/EquippedList
@onready var equipment_list: ItemList = $Panel/MarginContainer/VBoxContainer/EquipmentList
@onready var items_list: ItemList = $Panel/MarginContainer/VBoxContainer/ItemsList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/InventoryHeader/CloseInventoryButton

func _ready():
	close_button.pressed.connect(close_panel)
	equipped_list.item_selected.connect(_on_equipped_selected)
	equipment_list.item_selected.connect(_on_equipment_selected)

func open_panel(equipped_entries: Array, equipment_entries: Array, item_entries: Array):
	visible = true
	refresh(equipped_entries, equipment_entries, item_entries)

func close_panel():
	visible = false

func refresh(equipped_entries: Array, equipment_entries: Array, item_entries: Array):
	equipped_list.clear()
	equipment_list.clear()
	items_list.clear()

	var sorted_equipped = equipped_entries.duplicate()
	sorted_equipped.sort_custom(func(a, b): return a.get("slot", "") < b.get("slot", ""))
	for entry in sorted_equipped:
		var slot: String = entry.get("slot", "").capitalize()
		var item_id: String = entry.get("item_id", "")
		var name: String = entry.get("name", "")
		var label = "%s: %s" % [slot, name if name != "" else "(empty)"]
		var idx = equipped_list.add_item(label)
		equipped_list.set_item_metadata(idx, entry)

	for entry in equipment_entries:
		var label = "%s x%d" % [entry.get("name", entry.get("item_id", "")), int(entry.get("count", 0))]
		var slot_tag = entry.get("slot", "")
		if slot_tag != "":
			label += " [%s]" % slot_tag
		var idx = equipment_list.add_item(label)
		equipment_list.set_item_metadata(idx, entry)

	for entry in item_entries:
		var label = "%s x%d" % [entry.get("name", entry.get("item_id", "")), int(entry.get("count", 0))]
		items_list.add_item(label)

func _on_equipped_selected(index: int):
	var data = equipped_list.get_item_metadata(index)
	var slot = data.get("slot", "")
	if slot == "":
		return
	emit_signal("unequip_slot", slot)

func _on_equipment_selected(index: int):
	var data = equipment_list.get_item_metadata(index)
	var item_id = data.get("item_id", "")
	if item_id == "":
		return
	emit_signal("equip_item", item_id)
