extends Control

@onready var scroll_container = $Panel/ScrollContainer
# --- UPDATED PATH to match your screenshot ---
@onready var word_list = $Panel/ScrollContainer/GridContainer/WordList
@onready var details_panel = $Panel/DetailsPanel
@onready var details_content = $Panel/DetailsPanel/ScrollContainer/DetailsContent
@onready var lbl_word = $Panel/DetailsPanel/ScrollContainer/DetailsContent/Word
@onready var meaning_list = $Panel/DetailsPanel/ScrollContainer/DetailsContent/MeaningList
@onready var lbl_speech = $Panel/DetailsPanel/ScrollContainer/DetailsContent/SpeechPart
@onready var lbl_synonyms = $Panel/DetailsPanel/ScrollContainer/DetailsContent/Synonyms
@onready var title_label: Label = $Panel/TitleLabel
@onready var btn_main_menu: Button = $Panel/MainMenuButton
@onready var btn_replay: Button = $Panel/ReplayButton
@onready var btn_close_details = $Panel/DetailsPanel/CloseButton

var words_data: Array = []

func _ready() -> void:
	hide()
	details_panel.hide()

	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu_pressed)
	if btn_replay:
		btn_replay.pressed.connect(_on_replay_pressed)
	if btn_close_details:
		btn_close_details.pressed.connect(_on_close_details_pressed)

func show_recap(words: Array, outcome: String = "WORD RECAP") -> void:
	words_data = words
	title_label.text = outcome
	_populate_word_list()
	details_panel.hide()
	show()

func _populate_word_list() -> void:
	for child in word_list.get_children():
		child.queue_free()

	for i in range(words_data.size()):
		var word_info = words_data[i]
		var btn = Button.new()
		btn.text = word_info["word"].capitalize()
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(150, 40)
		btn.pressed.connect(_on_word_clicked.bind(i))
		word_list.add_child(btn)

func _on_word_clicked(index: int) -> void:
	if index < 0 or index >= words_data.size():
		return

	var info = words_data[index]
	lbl_word.text = "Word: " + info.get("word", "N/A")

	# Clear previous meanings
	for child in meaning_list.get_children():
		child.queue_free()

	var use_tagalog := GameSettings.target_language == "Tagalog"
	if info.has("meanings"):
		var meanings = info["meanings"]
		var seen_defs := []

		for meaning in meanings:
			var english_definition = String(meaning.get("def", "N/A"))
			var translated_definition = String(meaning.get("def_tl", "")).strip_edges()
			var def_text = translated_definition if use_tagalog and not translated_definition.is_empty() else english_definition
			if def_text in seen_defs:
				continue
			seen_defs.append(def_text)

			var def_label = Label.new()
			def_label.text = "🟢 " + def_text
			def_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			meaning_list.add_child(def_label)

			# --- This part automatically handles the translation label ---
			if not use_tagalog and not translated_definition.is_empty():
				var tl_label = Label.new()
				tl_label.text = " 🔹 Translation: " + translated_definition
				tl_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				meaning_list.add_child(tl_label)

			var speech_label = Label.new()
			speech_label.text = " 📘 Part of Speech: " + meaning.get("speech_part", "N/A")
			speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			meaning_list.add_child(speech_label)

			var english_example = String(meaning.get("example", ""))
			var translated_example = String(meaning.get("example_tl", "")).strip_edges()
			var example_text = translated_example if use_tagalog and not translated_example.is_empty() else english_example
			if not example_text.is_empty():
				var ex_label = Label.new()
				ex_label.text = " 💬 Example: " + example_text
				ex_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				meaning_list.add_child(ex_label)

			if not use_tagalog and not translated_example.is_empty():
				var ex_tl_label = Label.new()
				ex_tl_label.text = " 💭 TL Example: " + translated_example
				ex_tl_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				meaning_list.add_child(ex_tl_label)

			if meaning.has("synonyms") and meaning["synonyms"].size() > 0:
				var syn_label = Label.new()
				syn_label.text = " 🔁 Synonyms: " + ", ".join(meaning["synonyms"])
				syn_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				meaning_list.add_child(syn_label)

			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 10)
			meaning_list.add_child(spacer)

	lbl_speech.text = ""
	lbl_synonyms.text = ""
	details_panel.show()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	LoadingLoader.load_screen_to_scene("res://scenes/main_menu.tscn")

func _on_replay_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_close_details_pressed() -> void:
	details_panel.hide()

# --- NEW HELPER FUNCTION ---
func _add_shadow_to(node: Control) -> void:
	# Adds a semi-transparent black shadow, offset by 2 pixels right and down
	node.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	node.add_theme_constant_override("shadow_offset_x", 4)
	node.add_theme_constant_override("shadow_offset_y", 4)
