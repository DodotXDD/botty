# res://scenes/attack_button.gd
extends Button

# adjust these paths if your scene tree changes
@onready var slots_container = get_node("../../Inventory/SlotsContainer")
@onready var pouch = get_node("../../UIpouch")

# preload the script class, then make an instance in _ready()
const DictionaryLoader = preload("res://scripts/dictionary_loader.gd")
var dict_loader = null

func _ready() -> void:
	# instantiate the dictionary loader (so we can call non-static methods)
	dict_loader = DictionaryLoader.new()
	connect("pressed", Callable(self, "_on_attack_pressed"))

func _on_attack_pressed() -> void:
	if not slots_container or not pouch:
		print("Error: Missing SlotsContainer or UIPouch reference")
		return

	var words = get_words_from_grid()
	print("Words found in grid: ", words)

	var valid_words: Array = []
	for word in words:
		# call the instance method on dict_loader (not on the class)
		if dict_loader and dict_loader.is_valid_word(word):
			valid_words.append(word)

	print("Valid words: ", valid_words)

	# Example: damage = total length of all valid words
	var damage: int = 0
	for w in valid_words:
		damage += w.length()
	print("Damage dealt: ", damage)

	# Example apply damage to enemy (uncomment and adjust path if you have an enemy node)
	# var enemy = get_node("../../Enemy")
	# if enemy and enemy.has_method("take_damage"):
	#     enemy.take_damage(damage)

	# Refresh pouch for next round
	pouch.refresh_pouch(8)


# -----------------------------------------------------
# Collect words from the grid (horizontal + vertical)
# -----------------------------------------------------
func get_words_from_grid() -> Array:
	var words: Array = []

	if not slots_container:
		return words

	var slot_count: int = slots_container.get_child_count()
	if slot_count == 0:
		return words

	var cols: int = int(slots_container.columns)
	if cols <= 0:
		cols = 1
	var rows: int = int((slot_count + cols - 1) / cols)

	# Horizontal scan
	for r in range(rows):
		var current_word := ""
		for c in range(cols):
			var idx = r * cols + c
			var letter = _get_slot_letter(idx, slot_count)
			if letter != "":
				current_word += letter
			else:
				if current_word.length() > 1:
					words.append(current_word.to_lower())
				current_word = ""
		if current_word.length() > 1:
			words.append(current_word.to_lower())

	# Vertical scan
	for c in range(cols):
		var current_word := ""
		for r in range(rows):
			var idx = r * cols + c
			var letter = _get_slot_letter(idx, slot_count)
			if letter != "":
				current_word += letter
			else:
				if current_word.length() > 1:
					words.append(current_word.to_lower())
				current_word = ""
		if current_word.length() > 1:
			words.append(current_word.to_lower())

	return words


# -----------------------------------------------------
# Helper function: get the letter from a slot
# -----------------------------------------------------
func _get_slot_letter(idx: int, slot_count: int) -> String:
	if idx < 0 or idx >= slot_count:
		return ""

	var slot = slots_container.get_child(idx)
	if slot and slot.get_child_count() > 0:
		var tile = slot.get_child(0)  # The LetterTile inside the Slot
		if tile and tile.has_method("get_letter"):
			return tile.get_letter()  # ✅ Now calls letter_tile.gd
	return ""
