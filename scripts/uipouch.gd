# res://scenes/uipouch.gd
extends Control

@onready var letters_container = $Pouch/LettersContainer
@onready var slots_container = $"../Inventory/SlotsContainer"

const LetterTileScene := preload("res://scenes/LetterLabel.tscn")
const LETTER_WEIGHTS: Dictionary = {
	"A": 10, "B": 2, "C": 2, "D": 4, "E": 13, "F": 2, "G": 3,
	"H": 2, "I": 9, "J": 1, "K": 1, "L": 4, "M": 2, "N": 6,
	"O": 8, "P": 2, "Q": 1, "R": 6, "S": 4, "T": 6, "U": 4,
	"V": 2, "W": 2, "X": 1, "Y": 2, "Z": 1
}

func _ready() -> void:
	randomize()
	show_random_letters_in_pouch()

# -----------------------------
# POUCH LETTERS
# -----------------------------
func show_random_letters_in_pouch(count: int = 8) -> void:
	print("[DragDebug][PouchInit] creating=%d container=%s" % [count, letters_container.get_path()])
	for child in letters_container.get_children():
		child.queue_free()

	var letters = get_random_letters(count)
	for ch in letters:
		var tile = LetterTileScene.instantiate()
		letters_container.add_child(tile)
		if tile.has_method("set_letter"):
			tile.set_letter(ch)
		elif tile.has_node("Label"):
			tile.get_node("Label").text = ch
		print("[DragDebug][PouchTile] letter=%s script_attached=%s has_drag_method=%s path=%s visible=%s" % [ch, tile.get_script() != null, tile.has_method("_get_drag_data"), tile.get_path(), tile.is_visible_in_tree()])

func get_random_letters(length: int = 8) -> Array:
	var arr: Array = []
	var total_weight: int = 0
	for weight in LETTER_WEIGHTS.values():
		total_weight += int(weight)

	for _i in range(length):
		var roll = randi_range(1, total_weight)
		for letter in LETTER_WEIGHTS:
			roll -= LETTER_WEIGHTS[letter]
			if roll <= 0:
				arr.append(letter)
				break
	return arr

func refresh_pouch(count: int = 8) -> void:
	show_random_letters_in_pouch(count)

# -----------------------------
# GRID WORD SCANNING
# -----------------------------
func get_words_from_grid(container: Control, cols: int, rows: int) -> Array:
	var words: Array = []

	# Horizontal scan
	for r in range(rows):
		var word = ""
		for c in range(cols):
			var idx = r * cols + c
			if idx >= container.get_child_count():
				continue
			var slot = container.get_child(idx)
			var letter = get_slot_letter(slot)
			if letter != "":
				word += letter
			else:
				if word.length() > 1:
					words.append(word.to_lower())
					print("[Grid] Found horizontal word:", word)
				word = ""
		if word.length() > 1:
			words.append(word.to_lower())
			print("[Grid] Found horizontal word:", word)

	# Vertical scan
	for c in range(cols):
		var word = ""
		for r in range(rows):
			var idx = r * cols + c
			if idx >= container.get_child_count():
				continue
			var slot = container.get_child(idx)
			var letter = get_slot_letter(slot)
			if letter != "":
				word += letter
			else:
				if word.length() > 1:
					words.append(word.to_lower())
					print("[Grid] Found vertical word:", word)
				word = ""
		if word.length() > 1:
			words.append(word.to_lower())
			print("[Grid] Found vertical word:", word)

	print("[Grid] All words found:", words)
	return words

# -----------------------------
# SLOT LETTER HELPER
# -----------------------------
func get_slot_letter(slot: Control) -> String:
	if not slot:
		return ""
	for child in slot.get_children():
		if child.has_method("get_letter"):
			var l = child.get_letter()
			print("[Slot] Slot", slot.name, "has letter:", l)
			return l
	return ""

func highlight_words(valid_words: Array, invalid_words: Array) -> void:
	if not slots_container:
		return

	for child in slots_container.get_children():
		# Assume each slot has a background or Panel node
		if child.has_node("Background"):
			var bg = child.get_node("Background")
			bg.modulate = Color.WHITE  # Reset

	# For simplicity, recolor valid/invalid slots (optional: make it per-word)
	for word in valid_words:
		var indices = _find_word_slots(word)
		for i in indices:
			var slot = slots_container.get_child(i)
			if slot.has_node("Background"):
				slot.get_node("Background").modulate = Color(0.3, 1.0, 0.3) # Green for valid

	for word in invalid_words:
		var indices = _find_word_slots(word)
		for i in indices:
			var slot = slots_container.get_child(i)
			if slot.has_node("Background"):
				slot.get_node("Background").modulate = Color(1.0, 0.4, 0.4) # Red for invalid


# Helper: (you can improve this logic later)
func _find_word_slots(word: String) -> Array:
	var indices: Array = []
	# Example: just match sequential letters horizontally
	# (Adjust depending on how you store letters)
	for i in range(slots_container.get_child_count()):
		var slot = slots_container.get_child(i)
		for c in slot.get_children():
			if c.has_method("get_letter"):
				if c.get_letter().to_lower() == word[0]:
					indices.append(i)
	return indices

# -----------------------------
# WORD VALIDATION (stub)
# -----------------------------
func is_valid_word(word: String) -> bool:
	return word.length() > 1
