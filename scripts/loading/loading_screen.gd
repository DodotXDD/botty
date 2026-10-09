extends CanvasLayer

@export_file('*.tscn') var next_scene_path: String

func _ready() -> void:
	ResourceLoader.load_threaded_request(next_scene_path)

func _process(delta: float) -> void:
	if ResourceLoader.load_threaded_get_status(next_scene_path) == ResourceLoader.THREAD_LOAD_LOADED:
		# only for debug timeout
		#set_process(false)
		#await get_tree().create_timer(1).timeout
		
		var new_scene: PackedScene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
