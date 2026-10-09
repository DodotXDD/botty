extends TextureButton
class_name CustomTextureButton

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var hover_audio: AudioStream
@export var click_audio: AudioStream
@export var pressed_position_delta: Vector2 = Vector2(1.5, 1.5)
@export var enable_mask: bool = false

var in_animation: bool = false

func _ready() -> void:
	if enable_mask && texture_normal:
		texture_click_mask = BitMap.new()
		texture_click_mask.create_from_image_alpha(texture_normal.get_image())

func on_mouse_entered() -> void:
	# Play hover audio
	if !hover_audio:
		return 
	audio_stream_player_2d.stream = hover_audio
	audio_stream_player_2d.play()


func on_pressed() -> void:
	# Play click audio
	if click_audio:
		audio_stream_player_2d.stream = click_audio
		audio_stream_player_2d.play()


func on_button_down() -> void:
	if in_animation:
		return 
	in_animation = true
	position += pressed_position_delta


func on_button_up() -> void:
	in_animation = false
	position -= pressed_position_delta
