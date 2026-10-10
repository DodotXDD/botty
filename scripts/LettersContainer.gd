# res://scenes/letters_container.gd
extends GridContainer

func _can_drop_data(_pos: Vector2, data) -> bool:
	return data is Control and data.has_method("set_letter") and not data.get("is_locked")

func _drop_data(pos: Vector2, data) -> void:
	var source_parent: Node = data.get_parent()
	print("[DragDebug][PouchDrop] incoming=%s source=%s" % [data.get_letter(), source_parent.get_path() if source_parent else "<none>"])
	if source_parent == self:
		return
	var source_index := source_parent.get_children().find(data) if source_parent else -1
	var target_tile: Control = null
	for child in get_children():
		if child is Control and child != data and child.get_rect().has_point(pos):
			target_tile = child
			break

	if target_tile and source_parent and source_parent.is_in_group("word_slots"):
		if target_tile.get("is_locked"):
			print("[DragDebug][PouchDrop] rejected; target backpack tile is locked")
			return
		source_parent.remove_child(data)
		remove_child(target_tile)
		source_parent.add_child(target_tile)
		_apply_slot_layout(target_tile)
		var owner_inventory: Node = source_parent.get_meta("owner_inventory") if source_parent.has_meta("owner_inventory") else null
		if owner_inventory and owner_inventory.has_method("check_words"):
			owner_inventory.check_words()
	else:
		if data.get_parent():
			data.get_parent().remove_child(data)
		add_child(data)
		if target_tile:
			move_child(data, target_tile.get_index())

	_apply_pouch_layout(data)
	if source_parent and source_parent.has_method("check_words"):
		source_parent.check_words()

func _apply_pouch_layout(tile: Control) -> void:
	tile.position = Vector2.ZERO
	tile.anchor_left = 0
	tile.anchor_top = 0
	tile.anchor_right = 0
	tile.anchor_bottom = 0

func _apply_slot_layout(tile: Control) -> void:
	tile.position = Vector2.ZERO
	tile.anchor_left = 0
	tile.anchor_top = 0
	tile.anchor_right = 1
	tile.anchor_bottom = 1
	tile.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tile.grow_vertical = Control.GROW_DIRECTION_BOTH
