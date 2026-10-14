extends Area2D

signal level_selected(id: int)

@export var level_id := 1

@onready var label: Label = $Label
@onready var lock: Sprite2D = $Lock
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("level_buttons")
	label.text = str(level_id)
	input_event.connect(_on_input_event)
	mouse_entered.connect(func(): if _unlocked(): scale = Vector2(1.1, 1.1))
	mouse_exited.connect(func(): scale = Vector2.ONE)
	refresh()

func _unlocked() -> bool:
	return Progress.is_unlocked(level_id)

func refresh() -> void:
	var unlocked := _unlocked()
	lock.visible = not unlocked
	label.visible = unlocked
	sprite.modulate = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("is_dragging_map") and cam.is_dragging_map():
			return
		if not _unlocked():
			_shake()
			return
		level_selected.emit(level_id)

func _shake() -> void:
	var t := create_tween()
	t.tween_property(self, "rotation", 0.15, 0.05)
	t.tween_property(self, "rotation", -0.15, 0.1)
	t.tween_property(self, "rotation", 0.0, 0.05)
