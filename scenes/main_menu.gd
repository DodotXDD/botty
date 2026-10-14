extends Control
class_name MainMenu

# --- EXISTING REFERENCES ---
@export var start_button: Button
@export var quit_button: Button
# --- NEW REFERENCE ---
@export var settings_button: Button

# --- SETTINGS WINDOW REFERENCES ---
# Ensure these paths match your Scene Tree exactly!
@onready var settings_window = $MainmenuWindow/SettingsWindow
@onready var sound_toggle = $MainmenuWindow/SettingsWindow/VBoxContainer/VBoxContainer/SoundToggle
@onready var language_select = $MainmenuWindow/SettingsWindow/VBoxContainer/VBoxContainer/LanguageSelect
@onready var close_settings_btn = $MainmenuWindow/SettingsWindow/VBoxContainer/VBoxContainer/CloseButton

func _ready():
	# 1. Play Music
	MusicController.play_stream(MusicController.music_Mainmenu)
	
	# 2. Setup Settings UI (Populate Dropdown)
	language_select.clear()
	language_select.add_item("English Translation") # ID 0
	language_select.add_item("Tagalog Translation") # ID 1
	
	# 3. Load Current Values from Global GameSettings
	sound_toggle.button_pressed = GameSettings.sound_enabled
	
	if GameSettings.target_language == "Tagalog":
		language_select.selected = 1
	else:
		language_select.selected = 0

	# 4. Connect Signals
	# (Assuming Start/Quit are connected via Editor, but we connect the new ones here)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	
	if close_settings_btn:
		close_settings_btn.pressed.connect(_on_close_settings_pressed)
		
	sound_toggle.toggled.connect(_on_sound_toggled)
	language_select.item_selected.connect(_on_language_selected)


# --- MAIN BUTTONS ---

func _on_start_button_pressed():
	var error := get_tree().change_scene_to_file("res://scenes/map_zone.tscn")
	if error != OK:
		push_error("Could not open the map progress scene: %s" % error_string(error))

func _on_quit_button_pressed():
	get_tree().quit()

func _on_settings_button_pressed():
	settings_window.visible = true

# --- SETTINGS LOGIC ---

func _on_close_settings_pressed():
	settings_window.visible = false

func _on_sound_toggled(toggled_on: bool) -> void:
	GameSettings.set_sound(toggled_on)

func _on_language_selected(index: int) -> void:
	if index == 0:
		GameSettings.set_language("English")
	else:
		GameSettings.set_language("Tagalog")
