# res://scripts/letter_tile.gd
extends Control

var letter: String = ""
var points: int = 0 # Variable to store the point value

# --- NEW VARIABLES FOR TERRAIN MECHANIC ---
var is_locked: bool = false
var turns_locked: int = 2

@onready var bg := $Background
@onready var label_node := $Label
@onready var points_label := $PointsLabel # Reference to the new label for points

func _ready() -> void:
	print("\n[LetterTile] READY: name=%s letter=%s" % [name, letter])

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
	# Visual feedback: Turn slightly gray
	modulate = Color(0.7, 0.7, 0.7)
	# Turn off the active green/red glow
	set_glow(false)
	# Turn on the static grey glow
	set_used_glow()

# --- DRAG & DROP ---
func _get_drag_data(_at_position):
	# 1. If locked, REFUSE drag
	if is_locked:
		return null

	var parent_node = get_parent()

	# 2. Check if the tile is being picked up from an inventory slot.
	if parent_node and parent_node.is_in_group("word_slots"):
		# Immediately turn off this tile's glow visually.
		set_glow(false)
		# Note: We removed the 'await' here because it breaks dragging.
		# The board update happens when you drop the tile elsewhere.

	# Create the drag preview (visuals)
	var drag_preview = duplicate()
	drag_preview.modulate.a = 0.5
	drag_preview.anchor_left = 0
	drag_preview.anchor_top = 0
	drag_preview.anchor_right = 0
	drag_preview.anchor_bottom = 0
	drag_preview.size = Vector2(50, 50)
	set_drag_preview(drag_preview)
	
	return self


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
