extends Node
class_name WordUtils

# --- NEW, SIMPLER FUNCTION ---
# Reads all letters from the slots in order to form a single word.
static func get_single_word_from_slots(slots_container: Control) -> String:
	if not slots_container:
		return ""

	var word := ""
	for slot in slots_container.get_children():
		# Check if the slot has a letter tile in it
		if slot.get_child_count() > 0:
			var tile = slot.get_child(0)
			if tile and tile.has_method("get_letter"):
				word += String(tile.get_letter()).strip_edges()
	
	return word.to_lower()


# --- This is your original, complex function. ---
# We are keeping it in case you need it for something else later,
# but we will no longer use it for the attack button.
static func scan_grid_slots(slots_container: Control, cols: int, rows: int, return_tiles: bool = false) -> Array:
	var found: Array = []
	if not slots_container:
		return found

	var slot_count := slots_container.get_child_count()
	if cols <= 0:
		var grid = slots_container as GridContainer
		if grid:
			cols = grid.columns
		if cols <= 0:
			cols = 1
	if rows <= 0:
		rows = int((slot_count + cols - 1) / cols)

	# Horizontal scan
	for r in range(rows):
		var cur_word := ""
		var cur_tiles := []
		for c in range(cols):
			var idx := r * cols + c
			var pair := _get_letter_and_tile(slots_container, idx, slot_count)
			var letter: String = pair[0]
			var tile: Control = pair[1]

			if letter != "":
				cur_word += letter
				if return_tiles: cur_tiles.append(tile)
			else:
				if cur_word.length() > 1:
					var entry := {"word": cur_word.to_lower()}
					if return_tiles: entry["tiles"] = cur_tiles.duplicate()
					found.append(entry)
				cur_word = ""
				cur_tiles = []
		if cur_word.length() > 1:
			var entry := {"word": cur_word.to_lower()}
			if return_tiles: entry["tiles"] = cur_tiles.duplicate()
			found.append(entry)

	# Vertical scan
	for c in range(cols):
		var cur_word := ""
		var cur_tiles := []
		for r in range(rows):
			var idx := r * cols + c
			var pair := _get_letter_and_tile(slots_container, idx, slot_count)
			var letter: String = pair[0]
			var tile: Control = pair[1]

			if letter != "":
				cur_word += letter
				if return_tiles: cur_tiles.append(tile)
			else:
				if cur_word.length() > 1:
					var entry := {"word": cur_word.to_lower()}
					if return_tiles: entry["tiles"] = cur_tiles.duplicate()
					found.append(entry)
				cur_word = ""
				cur_tiles = []
		if cur_word.length() > 1:
			var entry := {"word": cur_word.to_lower()}
			if return_tiles: entry["tiles"] = cur_tiles.duplicate()
			found.append(entry)
			
	return found


static func _get_letter_and_tile(slots_container: Control, idx: int, slot_count: int) -> Array:
	if idx < 0 or idx >= slot_count:
		return ["", null]
	var slot = slots_container.get_child(idx)
	for child in slot.get_children():
		if child.has_method("get_letter"):
			var l = String(child.get_letter()).strip_edges()
			return [l, child]
	return ["", null]
