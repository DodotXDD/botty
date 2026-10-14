extends Camera2D

@export var map_sprite: Sprite2D
@export var friction := 5.0          # higher = stops faster
@export var drag_threshold := 8.0    # pixels before a click counts as a drag

var dragging := false
var drag_distance := 0.0
var velocity := Vector2.ZERO

func _ready() -> void:
	_set_limits_from_sprite()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if event.pressed:
			drag_distance = 0.0
			velocity = Vector2.ZERO

	elif event is InputEventMouseMotion and dragging:
		var move: Vector2 = -event.relative / zoom
		position += move
		drag_distance += event.relative.length()
		velocity = move / maxf(get_process_delta_time(), 0.001)

func _process(delta: float) -> void:
	if not dragging and velocity.length() > 5.0:
		position += velocity * delta
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)

func is_dragging_map() -> bool:
	return drag_distance > drag_threshold

func _set_limits_from_sprite() -> void:
	var size := map_sprite.texture.get_size() * map_sprite.scale
	var top_left := map_sprite.global_position - size / 2.0  # Sprite2D is centered by default
	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(top_left.x + size.x)
	limit_bottom = int(top_left.y + size.y)
