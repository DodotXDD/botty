# res://scripts/letter_tile.gd
extends Control

var letter: String = ""
var points: int = 0 # Variable to store the point value
var _modulate_before_drag: Color = Color.WHITE
var _is_dragging: bool = false

# --- NEW VARIABLES FOR TERRAIN MECHANIC ---
var is_locked: bool = false
var turns_locked: int = 2

@onready var bg := $Background
@onready var label_node := $Label
@onready var points_label := $PointsLabel # Reference to the new label for points

func _ready() -> void:
	print("\n[LetterTile] READY: name=%s letter=%s" % [name, letter])
	mouse_filter = Control.MOUSE_FILTER_STOP
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	points_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not bg:
		push_warning("[LetterTile][ERROR] Background node missing!")
	if not label_node:
		push_warning("[LetterTile][ERROR] Label node missing!")

	# ✅ Duplicate the material so each tile has its own shader instance
	if bg and bg.material:
		if bg.material is ShaderMaterial:
			bg.material = bg.material.duplicate()
			print("[LetterTile][INIT] Duplicated material for unique glow instance")
		else:
			push_warning("[LetterTile] BG material is not ShaderMaterial!")
	else:
		push_warning("[LetterTile] BG has no material!")

	print("[LetterTile][DEBUG] BG material after duplication:", bg.material)
	update_display()

func update_display() -> void:
	if has_node("Label"):
		$Label.text = letter

func set_letter(l: String) -> void:
	letter = l.to_upper() # Ensure letter is uppercase for lookup
	update_display()
	print("[LetterTile] set_letter('%s')" % l)

	# 1. Look up the point value from our global LetterData script.
	points = LetterData.LETTER_POINTS.get(letter, 1)

	# 2. Update the new PointsLabel on the tile.
	if points_label:
		points_label.text = str(points)

func get_letter() -> String:
	return letter

# --- NEW FUNCTION: LOCK TILE (For Terrain) ---
func lock_tile() -> void:
	is_locked = true
	tooltip_text = "Used word tile: locked for your next turn, then removed."
	# Visual feedback: Turn slightly gray
	modulate = Color(0.7, 0.7, 0.7)
	# Turn off the active green/red glow
	set_glow(false)
	# Turn on the static grey glow
	set_used_glow()

# --- DRAG & DROP ---
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		print("[DragDebug][TileInput] letter=%s pressed=%s locked=%s visible=%s paused=%s path=%s" % [letter, event.pressed, is_locked, is_visible_in_tree(), get_tree().paused, get_path()])

func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_locked:
		print("[DragDebug][DragStart] rejected locked letter=%s path=%s" % [letter, get_path()])
		return null

	var parent_node := get_parent()
	print("[DragDebug][DragStart] letter=%s parent=%s paused=%s" % [letter, parent_node.get_path() if parent_node else "<none>", get_tree().paused])
	if parent_node and parent_node.is_in_group("word_slots"):
		set_glow(false)

	set_drag_preview(_create_drag_preview())
	_modulate_before_drag = modulate
	_is_dragging = true
	modulate.a = 0.0
	return self

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _is_dragging:
		modulate = _modulate_before_drag
		_is_dragging = false

func _create_drag_preview() -> Control:
	var drag_preview_scene: PackedScene = load("res://scenes/LetterLabel.tscn")
	var drag_preview: Control = drag_preview_scene.instantiate()
	drag_preview.set("letter", letter)
	var preview_label: Label = drag_preview.get_node("Label")
	var preview_points: Label = drag_preview.get_node("PointsLabel")
	preview_label.text = letter
	preview_label.visible = true
	preview_points.text = str(points)
	preview_points.visible = true
	print("[DragDebug][Preview] letter=%s label=%s points=%s" % [letter, preview_label.text, preview_points.text])
	drag_preview.modulate = Color.WHITE
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.anchor_left = 0
	drag_preview.anchor_top = 0
	drag_preview.anchor_right = 0
	drag_preview.anchor_bottom = 0
	drag_preview.size = Vector2(50, 50)
	return drag_preview

func _can_drop_data(_at_position: Vector2, data) -> bool:
	var parent_node := get_parent()
	return not is_locked and parent_node != null and parent_node.has_method("_can_drop_data") and parent_node._can_drop_data(parent_node.get_local_mouse_position(), data)

func _drop_data(_at_position: Vector2, data) -> void:
	var parent_node := get_parent()
	print("[DragDebug][TileDrop] target_letter=%s incoming=%s parent=%s" % [letter, data.get_letter() if data and data.has_method("get_letter") else "<invalid>", parent_node.get_path() if parent_node else "<none>"])
	if parent_node and parent_node.has_method("_drop_data"):
		parent_node._drop_data(parent_node.get_local_mouse_position(), data)


# --- GLOW HANDLER ---
# In letter_tile.gd

func set_glow(active: bool, is_valid: bool = true):
	var bg = $Background if has_node("Background") else null
	if not (bg and bg.material and bg.material is ShaderMaterial):
		return

	# --- SMART LOCK LOGIC ---
	if is_locked:
		# If the command is to turn GREEN (Active + Valid), we ALLOW it.
		# This lets a locked tile glow green if it's part of a NEW word.
		if active and is_valid:
			pass # Allow the code below to run
		else:
			# If the command is Red or Off, force it back to GREY (Used look)
			set_used_glow()
			return

	# Standard Glow Application
	var mat: ShaderMaterial = bg.material
	if active:
		mat.set_shader_parameter("glow_strength", 1.0)
		if is_valid:
			mat.set_shader_parameter("glow_color", Color(0, 1, 0)) # Green
		else:
			mat.set_shader_parameter("glow_color", Color(1, 0, 0)) # Red
	else:
		mat.set_shader_parameter("glow_strength", 0.0)

# --- NEW FUNCTION: USED GLOW (GREY) ---
func set_used_glow():
	var bg = $Background if has_node("Background") else null
	if bg and bg.material and bg.material is ShaderMaterial:
		var mat: ShaderMaterial = bg.material
		mat.set_shader_parameter("glow_strength", 1.0)
		mat.set_shader_parameter("glow_color", Color(0.5, 0.5, 0.5)) # Grey

# --- Shader control ---
func _set_glow_shader(active: bool, is_valid: bool = true) -> void:
	print("[LetterTile] _set_glow_shader → active=%s valid=%s" % [str(active), str(is_valid)])
	print("[LetterTile][DEBUG] BG:", bg, " | Material:", bg.material, " | Type:", typeof(bg.material))

	if not bg or not (bg.material is ShaderMaterial):
		print("[LetterTile] ⚠️ No ShaderMaterial found or invalid type!")
		return

	var mat: ShaderMaterial = bg.material
	if not active:
		mat.set_shader_parameter("glow_strength", 0.0)
		print("[LetterTile] Glow OFF")
	else:
		var color := Color(0.0, 1.0, 0.0, 1.0) if is_valid else Color(1.0, 0.0, 0.0, 1.0)
		mat.set_shader_parameter("glow_color", color)
		mat.set_shader_parameter("glow_strength", 1.2)
		print("[LetterTile] Glow ON →", color)
