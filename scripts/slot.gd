# res://scripts/slot.gd
extends Control

var owner_inventory: Node = null

# --- NEW VARIABLES ---
var is_targeted: bool = false # Highlight Red (Warning)
var is_broken: bool = false   # Locked/Destroyed (Cannot be used)

@onready var background = $Background # Ensure your Slot scene has a Panel/TextureRect named Background

func set_owner_inventory(inv: Node) -> void:
	owner_inventory = inv
	set_meta("owner_inventory", inv)

func _can_drop_data(_position, data) -> bool:
	# If the slot is broken, REJECT all drops.
	if is_broken:
		return false
	return data is Control and data.has_method("get_letter")

func _drop_data(_position, data) -> void:
	var existing_tile: Node = null
	for child in get_children():
		if child.has_method("get_letter"):
			existing_tile = child
			break
	if existing_tile and existing_tile != data:
		var pouch = get_tree().get_first_node_in_group("pouch")
		var letters_container = pouch.get_node_or_null("Pouch/LettersContainer") if pouch else null
		if letters_container:
			letters_container.add_child(existing_tile)

	if data.get_parent():
		data.get_parent().remove_child(data)
	add_child(data)

	data.position = Vector2.ZERO
	data.anchor_left = 0
	data.anchor_top = 0
	data.anchor_right = 1
	data.anchor_bottom = 1
	data.grow_horizontal = Control.GROW_DIRECTION_BOTH
	data.grow_vertical = Control.GROW_DIRECTION_BOTH

	await get_tree().process_frame

	if owner_inventory and owner_inventory.has_method("check_words"):
		owner_inventory.check_words()

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
