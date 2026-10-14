extends Node2D

func _ready() -> void:
	for btn in get_tree().get_nodes_in_group("level_buttons"):
		btn.level_selected.connect(_on_level_selected)

func _on_level_selected(id: int) -> void:
	Progress.current_level = id
	print("Selected level ", id)
	# get_tree().change_scene_to_file("res://battle_scene.tscn")
