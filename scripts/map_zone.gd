extends Control

const LEVEL_S1_SCENE := "res://scenes/Levelmap - S1.tscn"
const MAP_NORMAL_COLOR := Color.WHITE
const MAP_HOVER_COLOR := Color(0.28, 0.28, 0.28, 1.0)

@onready var base_map: Sprite2D = $Map
@onready var s1_map: Sprite2D = $S1Map
@onready var location_maps: Array[Sprite2D] = [
	$S1Map,
	$S2Map,
	$S3Map,
	$S4Map
]
@onready var map_name_label: Label = $"Map Name Container/Map Name"

var scene_change_started := false

func _ready() -> void:
	map_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	var mouse_position := get_viewport().get_mouse_position()
	var hovered_location_index := -1
	for index in range(location_maps.size()):
		var location_map := location_maps[index]
		var local_mouse_position := location_map.get_global_transform_with_canvas().affine_inverse() * mouse_position
		var hovered := location_map.is_pixel_opaque(local_mouse_position)
		if location_map.visible != hovered:
			location_map.visible = hovered

		if hovered:
			hovered_location_index = index

	var hovering_location := hovered_location_index >= 0
	base_map.modulate = MAP_HOVER_COLOR if hovering_location else MAP_NORMAL_COLOR
	map_name_label.text = "Region %d" % (hovered_location_index + 1) if hovering_location else "Select a Region"

func _input(event: InputEvent) -> void:
	if scene_change_started or not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var click_position: Vector2 = event.position
	var local_map_position := s1_map.get_global_transform_with_canvas().affine_inverse() * click_position
	var local_label_position := map_name_label.get_global_transform_with_canvas().affine_inverse() * click_position
	var clicked_s1 := s1_map.is_pixel_opaque(local_map_position)
	var clicked_region_label := map_name_label.get_rect().has_point(local_label_position)
	if clicked_s1 or clicked_region_label:
		scene_change_started = true
		LoadingLoader.load_screen_to_scene(LEVEL_S1_SCENE)
		get_viewport().set_input_as_handled()

func _on_back_button_pressed() -> void:
	LoadingLoader.load_screen_to_scene("res://scenes/main_menu.tscn")
