extends Control

@onready var scroll_container = $Panel/ScrollContainer
@onready var word_list = $Panel/ScrollContainer/WordList
@onready var details_panel = $Panel/DetailsPanel
@onready var details_scroll = $Panel/DetailsPanel/ScrollContainer
@onready var lbl_word = $Panel/DetailsPanel/Word
@onready var meaning_list = $Panel/DetailsPanel/ScrollContainer/DetailsContent/MeaningList
@onready var title_label: Label = $Panel/TitleLabel
@onready var summary_label: Label = $Panel/SummaryLabel
@onready var empty_state_label: Label = $Panel/EmptyStateLabel
@onready var btn_main_menu: Button = $Panel/MainMenuButton
@onready var btn_replay: Button = $Panel/ReplayButton

var words_data: Array = []
var word_button_group := ButtonGroup.new()

func _ready() -> void:
	hide()
	empty_state_label.hide()

	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu_pressed)
	if btn_replay:
		btn_replay.pressed.connect(_on_replay_pressed)

func show_recap(words: Array, outcome: String = "WORD RECAP") -> void:
	words_data.clear()
	var seen_words: Dictionary = {}
	for word_info in words:
		if typeof(word_info) != TYPE_DICTIONARY:
			continue
		var word := String(word_info.get("word", "")).strip_edges().to_lower()
		if word.is_empty() or seen_words.has(word):
			continue
		seen_words[word] = true
		var normalized_info: Dictionary = word_info.duplicate(true)
		normalized_info["word"] = word
		words_data.append(normalized_info)

	title_label.text = outcome.to_upper()
	var word_count := words_data.size()
	var word_label := "WORD" if word_count == 1 else "WORDS"
	summary_label.text = "BATTLE JOURNAL  |  %d UNIQUE %s" % [word_count, word_label]
	_populate_word_list()
	var has_words := not words_data.is_empty()
	scroll_container.visible = has_words
	details_panel.visible = has_words
	empty_state_label.visible = not has_words
	show()

func _populate_word_list() -> void:
	for child in word_list.get_children():
		child.queue_free()

	word_button_group = ButtonGroup.new()
	for i in range(words_data.size()):
		var word_info = words_data[i]
		var word := String(word_info.get("word", ""))
		var btn = Button.new()
		btn.text = "%s    %d letters" % [word.capitalize(), word.length()]
		btn.tooltip_text = word.capitalize()
		btn.toggle_mode = true
		btn.button_group = word_button_group
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_on_word_clicked.bind(i))
		word_list.add_child(btn)

	if not words_data.is_empty():
		_on_word_clicked(0)

func _on_word_clicked(index: int) -> void:
	if index < 0 or index >= words_data.size():
		return

	var info = words_data[index]
	lbl_word.text = String(info.get("word", "N/A")).to_upper()
	details_scroll.scroll_vertical = 0

	for child in meaning_list.get_children():
		child.queue_free()
	meaning_list.add_theme_constant_override("separation", 8)

	var use_tagalog := GameSettings.target_language == "Tagalog"
	var meanings: Array = info.get("meanings", [])
	var seen_definitions: Array[String] = []
	for meaning in meanings:
		if typeof(meaning) != TYPE_DICTIONARY:
			continue

		var english_definition := String(meaning.get("def", "N/A")).strip_edges()
		var translated_definition := String(meaning.get("def_tl", "")).strip_edges()
		var definition := translated_definition if use_tagalog and not translated_definition.is_empty() else english_definition
		if definition in seen_definitions:
			continue
		seen_definitions.append(definition)

		_add_detail_label(definition, 20, Color(0.08, 0.08, 0.08))

		var speech_part := String(meaning.get("speech_part", "")).strip_edges()
		if not speech_part.is_empty():
			_add_detail_label(speech_part.to_upper(), 14, Color(0.28, 0.28, 0.28))

		if not use_tagalog and not translated_definition.is_empty():
			_add_detail_label("Tagalog: " + translated_definition, 16, Color(0.18, 0.18, 0.18))

		var english_example := String(meaning.get("example", "")).strip_edges()
		var translated_example := String(meaning.get("example_tl", "")).strip_edges()
		var example := translated_example if use_tagalog and not translated_example.is_empty() else english_example
		if not example.is_empty():
			_add_detail_label("Example: \"" + example + "\"", 16, Color(0.18, 0.18, 0.18))

		if not use_tagalog and not translated_example.is_empty():
			_add_detail_label("Tagalog example: \"" + translated_example + "\"", 15, Color(0.28, 0.28, 0.28))

		var synonyms: Array = meaning.get("synonyms", [])
		if not synonyms.is_empty():
			_add_detail_label("Synonyms: " + ", ".join(synonyms), 15, Color(0.28, 0.28, 0.28))

		var separator := HSeparator.new()
		meaning_list.add_child(separator)

	if seen_definitions.is_empty():
		_add_detail_label("No definition is available for this word.", 17, Color(0.18, 0.18, 0.18))

func _add_detail_label(text: String, font_size: int, font_color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	meaning_list.add_child(label)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	LoadingLoader.load_screen_to_scene("res://scenes/main_menu.tscn")

func _on_replay_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
