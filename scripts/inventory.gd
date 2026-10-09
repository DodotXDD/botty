# res://scripts/inventory.gd
extends Control

signal damage_updated(total_damage)

@onready var slots_container = $SlotsContainer
var SlotScene = preload("res://scenes/Slot.tscn")
@onready var ui_pouch = $"../UIpouch"

const COLUMNS = 8
const ROWS = 5

var dict_loader: Node = null
var played_words: Array = [] 

func set_dictionary_loader(loader: Node) -> void:
	dict_loader = loader
	print("[Inventory] dictionary loader set:", dict_loader)

func _ready() -> void:
	populate_slots(COLUMNS * ROWS)
	check_words()

# ----------------------------------------------------------
# Slot management
# ----------------------------------------------------------
func populate_slots(count: int) -> void:
	for child in slots_container.get_children():
		child.queue_free()
	for i in range(count):
		var slot = SlotScene.instantiate()
		if slot.has_method("set_owner_inventory"):
			slot.set_owner_inventory(self)
		slots_container.add_child(slot)
	check_words()

func get_slot(x: int, y: int) -> Node:
	var idx = y * COLUMNS + x
	if idx >= 0 and idx < slots_container.get_child_count():
		return slots_container.get_child(idx)
	return null

# ----------------------------------------------------------
# Main word check logic
# ----------------------------------------------------------
func check_words():
	reset_all_tile_glows()

	var valid_words: Array = []
	var words_found: Array = []
	var word_tiles_found: Array = []
	var word_data_to_return: Array = []

	var grid := []
	for y in range(ROWS):
		grid.append([])
		for x in range(COLUMNS):
			var slot = get_slot(x, y)
			var letter := ""
			if slot:
				for child in slot.get_children():
					if child.has_method("get_letter"):
						letter = child.get_letter()
						break
			grid[y].append(letter)

	# --- Horizontal word detection ---
	for y in range(ROWS):
		var word := ""
		var current_tiles := []
		for x in range(COLUMNS):
			if grid[y][x] != "":
				word += grid[y][x]
				var tile_node = get_tile(x, y)
				if tile_node: current_tiles.append(tile_node)
			else:
				if word.length() >= 3:
					words_found.append(word.to_lower())
					word_tiles_found.append(current_tiles.duplicate())
				word = ""
				current_tiles.clear()
		if word.length() >= 3:
			words_found.append(word.to_lower())
			word_tiles_found.append(current_tiles.duplicate())

	# --- Vertical word detection ---
	for x in range(COLUMNS):
		var word := ""
		var current_tiles := []
		for y in range(ROWS):
			if grid[y][x] != "":
				word += grid[y][x]
				var tile_node = get_tile(x, y)
				if tile_node: current_tiles.append(tile_node)
			else:
				if word.length() >= 3:
					words_found.append(word.to_lower())
					word_tiles_found.append(current_tiles.duplicate())
				word = ""
				current_tiles.clear()
		if word.length() >= 3:
			words_found.append(word.to_lower())
			word_tiles_found.append(current_tiles.duplicate())

	# --- Pre-calculate validity for all words ---
	var word_validity_map = []
	for i in range(words_found.size()):
		var w = words_found[i]
		var is_valid := false
		if dict_loader and dict_loader.has_method("is_valid_word"):
			is_valid = dict_loader.is_valid_word(w)
		else:
			is_valid = _is_valid_word_fallback_local(w)
		
		word_validity_map.append(is_valid)

	# --- PASS 1: Apply Grey (Used) and Red (Invalid) first ---
	# This ensures they are the "background" colors
	for i in range(words_found.size()):
		var w = words_found[i]
		var tiles = word_tiles_found[i]
		var is_valid = word_validity_map[i]

		if w in played_words:
			# Used word -> Grey
			for tile in tiles:
				if tile.has_method("set_used_glow"):
					tile.set_used_glow()
		elif not is_valid:
			# Invalid word -> Red
			for tile in tiles:
				if tile.has_method("set_glow"):
					tile.set_glow(true, false)

	# --- PASS 2: Apply Green (New Valid) last ---
	# This overrides any Grey/Red colors if a tile is part of a NEW valid word
	for i in range(words_found.size()):
		var w = words_found[i]
		var tiles = word_tiles_found[i]
		var is_valid = word_validity_map[i]

		# Only process if it's valid AND NOT already played
		if is_valid and not (w in played_words):
			valid_words.append(w)
			word_data_to_return.append({"word": w, "tiles": tiles})
			for tile in tiles:
				if tile.has_method("set_glow"):
					# Force Green (Valid)
					tile.set_glow(true, true)

	print("✅ Valid words:", valid_words)
	
	var total_damage = 0
	for word in valid_words:
		for char in word.to_upper():
			total_damage += LetterData.LETTER_POINTS.get(char, 0)
	
	damage_updated.emit(total_damage)

	return word_data_to_return

# ----------------------------------------------------------
# Helper functions
# ----------------------------------------------------------
func get_tile(x: int, y: int):
	var slot = get_slot(x, y)
	if slot and slot.get_child_count() > 0:
		for child in slot.get_children():
			if child.has_method("get_letter"):
				return child
	return null

func _find_dict_loader_in_node(node: Node) -> Node:
	if node == null: return null
	if node.has_method("is_valid_word"): return node
	for child in node.get_children():
		var found = _find_dict_loader_in_node(child)
		if found: return found
	return null

func _is_valid_word_fallback_local(word: String) -> bool:
	var sample = ["jerk", "rod", "dog", "cat", "vex", "red", "apple", "tree", "bat", "pig", "sit", "done", "gun", "bay", "dub"]
	return word.to_lower() in sample

func reset_all_tile_glows() -> void:
	for slot in slots_container.get_children():
		for child in slot.get_children():
			if child and child.has_method("set_glow"):
				child.set_glow(false)

# In inventory.gd

# ... (keep all your existing code) ...

# ----------------------------------------------------------
# ENEMY ATTACK LOGIC
# ----------------------------------------------------------

# Call this to execute the attack on slots that were ALREADY marked red
func trigger_enemy_destruction() -> void:
	for slot in slots_container.get_children():
		if slot.get("is_targeted"):
			slot.break_slot()
	# Re-check words in case a valid word was destroyed
	check_words()

# Call this to pick NEW slots to warn the player about
func choose_new_enemy_targets(amount: int = 2) -> void:
	var valid_slots = []
	
	# Find all slots that are not already broken or targeted
	for slot in slots_container.get_children():
		if not slot.get("is_broken") and not slot.get("is_targeted"):
			valid_slots.append(slot)
	
	valid_slots.shuffle()
	
	# Mark the first few as targets
	for i in range(min(amount, valid_slots.size())):
		valid_slots[i].mark_as_target()
		
# In inventory.gd

# NEW FUNCTION: Fix all broken slots from the previous turn
func repair_all_broken_slots() -> void:
	for slot in slots_container.get_children():
		if slot.has_method("repair_slot") and slot.get("is_broken"):
			slot.repair_slot()
