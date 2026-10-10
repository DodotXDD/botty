extends Control
class_name PauseMenu

func _ready() -> void:
	# Hide the pause menu initially
	hide()
	# Set process mode so this node still works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# Use _input instead of _process for better input handling
	if event.is_action_pressed("ui_cancel"):
		var tutorial = get_parent().get_node_or_null("Tutorial")
		if tutorial and tutorial.visible:
			return
		if get_tree().paused:
			resume()
		else:
			pause()

func resume() -> void:
	hide()
	get_tree().paused = false
	MusicController.process_mode = Node.PROCESS_MODE_INHERIT
	MusicController.play_stream(MusicController.music_Gameplay)

func pause() -> void:
	show()
	# Set MusicController to keep running when paused
	if MusicController:
		MusicController.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	# Play pause music
	MusicController.play_stream(MusicController.music_Pause)

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	# Unpause before changing scenes
	get_tree().paused = false
	# Main menu will handle its own music
	LoadingLoader.load_screen_to_scene("res://scenes/main_menu.tscn")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
