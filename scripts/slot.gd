# res://scripts/slot.gd
extends Control

var owner_inventory: Node = null
var _last_drop_check_log: String = ""

# --- NEW VARIABLES ---
var is_targeted: bool = false # Highlight Red (Warning)
var is_broken: bool = false   # Locked/Destroyed (Cannot be used)

@onready var background = $Background # Ensure your Slot scene has a Panel/TextureRect named Background

func set_owner_inventory(inv: Node) -> void:
	owner_inventory = inv
	set_meta("owner_inventory", inv)

func _can_drop_data(_position, data) -> bool:
	var incoming := String(data.get_letter()) if data is Control and data.has_method("get_letter") else "<invalid>"
	var accepted := true
	var reason := "ready"
	# If the slot is broken, REJECT all drops.
	if is_broken:
		accepted = false
		reason = "broken slot"
	elif not (data is Control and data.has_method("get_letter")):
		accepted = false
		reason = "invalid payload"
	elif data.get("is_locked"):
		accepted = false
		reason = "incoming tile locked"
	else:
		for child in get_children():
			if child.has_method("get_letter") and child != data and child.get("is_locked"):
				accepted = false
				reason = "occupied by locked tile"
				break
	var check_log := "%s:%s:%s" % [incoming, accepted, reason]
	if check_log != _last_drop_check_log:
		print("[DragDebug][SlotCheck] target=%s incoming=%s accepted=%s reason=%s" % [name, incoming, accepted, reason])
		_last_drop_check_log = check_log
	return accepted

func _drop_data(_position, data) -> void:
	print("[DragDebug][SlotDrop] target=%s incoming=%s source=%s" % [name, data.get_letter() if data and data.has_method("get_letter") else "<invalid>", data.get_parent().get_path() if data and data.get_parent() else "<none>"])
	var source_parent: Node = data.get_parent()
	if source_parent == self:
		return
	var source_index := source_parent.get_children().find(data) if source_parent else -1
	var existing_tile: Node = null
	for child in get_children():
		if child.has_method("get_letter"):
			existing_tile = child
			break
	if existing_tile and existing_tile != data:
		if existing_tile.get("is_locked") or source_parent == null:
			return
		source_parent.remove_child(data)
		remove_child(existing_tile)
		source_parent.add_child(existing_tile)
		if source_index >= 0:
			source_parent.move_child(existing_tile, source_index)
		add_child(data)
		if source_parent.is_in_group("word_slots"):
			_apply_slot_layout(existing_tile)
		else:
			_apply_pouch_layout(existing_tile)
	else:
		if data.get_parent():
			data.get_parent().remove_child(data)
		add_child(data)

	_apply_slot_layout(data)

	await get_tree().process_frame

	if owner_inventory and owner_inventory.has_method("check_words"):
		owner_inventory.check_words()
	if source_parent and source_parent.has_method("check_words") and source_parent != owner_inventory:
		source_parent.check_words()

func _apply_slot_layout(tile: Control) -> void:
	tile.position = Vector2.ZERO
	tile.anchor_left = 0
	tile.anchor_top = 0
	tile.anchor_right = 1
	tile.anchor_bottom = 1
	tile.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tile.grow_vertical = Control.GROW_DIRECTION_BOTH

func _apply_pouch_layout(tile: Control) -> void:
	tile.position = Vector2.ZERO
	tile.anchor_left = 0
	tile.anchor_top = 0
	tile.anchor_right = 0
	tile.anchor_bottom = 0

# --- ENEMY ABILITY FUNCTIONS ---

func mark_as_target() -> void:
	if is_broken: return
	is_targeted = true
	# Visual: Turn Red to warn the player
	if background:
		background.modulate = Color(1, 0.4, 0.4, 1) # Bright Red

func break_slot() -> void:
	if is_broken: return
	
	is_targeted = false
	is_broken = true
	
	# 1. Visual: Turn Dark Grey/Black to show it's destroyed
	if background:
		background.modulate = Color(0.2, 0.2, 0.2, 1) 
	
	# 2. Destroy any tile currently inside!
	for child in get_children():
		if child.has_method("get_letter"):
			child.queue_free() # Poof! Letter gone.
			
			# In slot.gd

# In slot.gd

# NEW FUNCTION: Restore the slot to normal
func repair_slot() -> void:
	is_broken = false
	is_targeted = false
	if background:
		background.modulate = Color.WHITE # Reset color to normal
