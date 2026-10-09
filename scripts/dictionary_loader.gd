extends Node

var dict: Dictionary = {}

# Loads all JSON dictionary chunks inside "res://dictionary/"
func load_all_chunks():
	var dir_path = "res://dictionary/"
	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_error("Dictionary folder not found: " + dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = dir_path + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()
				var data = JSON.parse_string(json_string)
				# ✅ SAFETY CHECK
				if typeof(data) == TYPE_DICTIONARY:
					for k in data.keys():
						dict[k.to_lower()] = data[k]
				else:
					push_warning("Invalid JSON format in " + file_name)
			else:
				push_warning("Failed to open: " + file_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("Loaded dictionary entries:", dict.size())

# Checks if a word exists in the dictionary
func is_valid_word(word: String) -> bool:
	return dict.has(word.to_lower())

# Returns data for a given word
func get_word_data(word: String) -> Variant:
	var lw = word.to_lower()
	if dict.has(lw):
		return dict[lw]
	return {}
