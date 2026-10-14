extends Control

@onready var level_status: Label = $LevelStatus

func _on_level_1_pressed() -> void:
	LoadingLoader.load_screen_to_scene("res://scenes/battle_scene.tscn")

func _on_level_2_pressed() -> void:
	_show_future_level(2)

func _on_level_3_pressed() -> void:
	_show_future_level(3)

func _on_level_4_pressed() -> void:
	_show_future_level(4)

func _on_level_5_pressed() -> void:
	_show_future_level(5)

func _on_back_pressed() -> void:
	LoadingLoader.load_screen_to_scene("res://scenes/main_menu.tscn")

func _show_future_level(level_number: int) -> void:
	level_status.text = "LEVEL %d IS A PLACEHOLDER FOR A FUTURE STAGE" % level_number
