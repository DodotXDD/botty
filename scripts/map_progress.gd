extends Control

const DESIGN_SIZE := Vector2(1154.0, 652.0)
const LEVEL_CENTERS := [
	Vector2(238.0, 194.0),
	Vector2(408.0, 334.0),
	Vector2(590.0, 230.0),
	Vector2(770.0, 402.0),
	Vector2(954.0, 270.0)
]

const OUTER_COLOR := Color(0.36, 0.21, 0.15)
const EDGE_COLOR := Color(0.78, 0.52, 0.29)
const LAND_COLOR := Color(0.98, 0.89, 0.66)
const ROUTE_COLOR := Color(0.23, 0.22, 0.18)
const ISLAND_COLOR := Color(0.36, 0.40, 0.31)

var level_buttons: Array[Button] = []
var back_button: Button
var title_label: Label
var subtitle_label: Label
var status_label: Label

func _ready() -> void:
	_create_ui()
	resized.connect(_layout_ui)
	_layout_ui()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.94, 0.91))
	for x in range(8, int(size.x), 24):
		for y in range(8, int(size.y), 24):
			draw_circle(Vector2(x, y), 1.2, Color(0.80, 0.85, 0.81))

	var scale_factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	if scale_factor <= 0.0:
		return
	var origin := (size - DESIGN_SIZE * scale_factor) * 0.5
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	_draw_map()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _create_ui() -> void:
	back_button = Button.new()
	back_button.text = "MAIN MENU"
	back_button.tooltip_text = "Return to the main menu"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.add_theme_font_size_override("font_size", 15)
	back_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.90, 0.83, 0.67), OUTER_COLOR))
	back_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.96, 0.89, 0.73), OUTER_COLOR))
	back_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.81, 0.68, 0.48), OUTER_COLOR))
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

	title_label = Label.new()
	title_label.text = "JOURNEY MAP"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", OUTER_COLOR)
	title_label.add_theme_font_size_override("font_size", 28)
	add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Choose a level to continue your journey"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", Color(0.35, 0.34, 0.27))
	subtitle_label.add_theme_font_size_override("font_size", 15)
	add_child(subtitle_label)

	status_label = Label.new()
	status_label.text = "LEVEL 1 AVAILABLE  |  LEVELS 2-5 COMING SOON"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", OUTER_COLOR)
	status_label.add_theme_font_size_override("font_size", 15)
	add_child(status_label)

	for level_index in range(LEVEL_CENTERS.size()):
		var button := Button.new()
		button.text = str(level_index + 1)
		button.tooltip_text = "Start Level 1" if level_index == 0 else "Level %d is coming soon" % (level_index + 1)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 22)
		var active := level_index == 0
		var fill := Color(0.82, 0.27, 0.22) if active else Color(0.76, 0.72, 0.61)
		var border := Color(0.42, 0.18, 0.15) if active else Color(0.52, 0.47, 0.38)
		button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.87))
		button.add_theme_stylebox_override("normal", _make_button_style(fill, border))
		button.add_theme_stylebox_override("hover", _make_button_style(fill.lightened(0.12), border))
		button.add_theme_stylebox_override("pressed", _make_button_style(fill.darkened(0.12), border))
		button.pressed.connect(_on_level_pressed.bind(level_index))
		level_buttons.append(button)
		add_child(button)

func _layout_ui() -> void:
	if not is_instance_valid(back_button) or size.x <= 0.0 or size.y <= 0.0:
		return
	var scale_factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var origin := (size - DESIGN_SIZE * scale_factor) * 0.5
	back_button.position = origin + Vector2(32.0, 24.0) * scale_factor
	back_button.size = Vector2(142.0, 42.0) * scale_factor
	title_label.position = origin + Vector2(392.0, 17.0) * scale_factor
	title_label.size = Vector2(370.0, 38.0) * scale_factor
	subtitle_label.position = origin + Vector2(377.0, 53.0) * scale_factor
	subtitle_label.size = Vector2(400.0, 26.0) * scale_factor
	status_label.position = origin + Vector2(322.0, 594.0) * scale_factor
	status_label.size = Vector2(510.0, 28.0) * scale_factor
	for level_index in range(level_buttons.size()):
		var button_size := Vector2.ONE * (62.0 * scale_factor)
		var marker_position: Vector2 = LEVEL_CENTERS[level_index] + Vector2(38.0, -14.0)
		level_buttons[level_index].size = button_size
		level_buttons[level_index].position = origin + marker_position * scale_factor - button_size * 0.5

func _draw_map() -> void:
	var outer := PackedVector2Array([
		Vector2(194, 18), Vector2(540, 18), Vector2(540, 42), Vector2(736, 42),
		Vector2(736, 18), Vector2(930, 18), Vector2(930, 52), Vector2(990, 52),
		Vector2(990, 82), Vector2(1032, 82), Vector2(1032, 118), Vector2(1080, 118),
		Vector2(1080, 142), Vector2(1128, 142), Vector2(1128, 194), Vector2(1104, 194),
		Vector2(1104, 294), Vector2(1142, 294), Vector2(1142, 354), Vector2(1110, 354),
		Vector2(1110, 430), Vector2(1132, 430), Vector2(1132, 510), Vector2(1098, 510),
		Vector2(1098, 558), Vector2(1018, 558), Vector2(1018, 590), Vector2(900, 590),
		Vector2(900, 574), Vector2(790, 574), Vector2(790, 614), Vector2(652, 614),
		Vector2(652, 638), Vector2(476, 638), Vector2(476, 612), Vector2(338, 612),
		Vector2(338, 588), Vector2(230, 588), Vector2(230, 616), Vector2(120, 616),
		Vector2(120, 582), Vector2(62, 582), Vector2(62, 510), Vector2(28, 510),
		Vector2(28, 450), Vector2(58, 450), Vector2(58, 370), Vector2(24, 370),
		Vector2(24, 238), Vector2(58, 238), Vector2(58, 196), Vector2(84, 196),
		Vector2(84, 156), Vector2(44, 156), Vector2(44, 124), Vector2(18, 124),
		Vector2(18, 90), Vector2(54, 90), Vector2(54, 68), Vector2(116, 68),
		Vector2(116, 52), Vector2(194, 52)
	])
	draw_colored_polygon(outer, OUTER_COLOR)

	var edge := PackedVector2Array([
		Vector2(208, 32), Vector2(526, 32), Vector2(526, 56), Vector2(750, 56),
		Vector2(750, 32), Vector2(916, 32), Vector2(916, 66), Vector2(976, 66),
		Vector2(976, 96), Vector2(1018, 96), Vector2(1018, 132), Vector2(1066, 132),
		Vector2(1066, 156), Vector2(1114, 156), Vector2(1114, 180), Vector2(1090, 180),
		Vector2(1090, 308), Vector2(1128, 308), Vector2(1128, 340), Vector2(1096, 340),
		Vector2(1096, 444), Vector2(1118, 444), Vector2(1118, 496), Vector2(1084, 496),
		Vector2(1084, 544), Vector2(1004, 544), Vector2(1004, 576), Vector2(914, 576),
		Vector2(914, 560), Vector2(776, 560), Vector2(776, 600), Vector2(638, 600),
		Vector2(638, 624), Vector2(490, 624), Vector2(490, 598), Vector2(324, 598),
		Vector2(324, 574), Vector2(244, 574), Vector2(244, 602), Vector2(134, 602),
		Vector2(134, 568), Vector2(76, 568), Vector2(76, 496), Vector2(42, 496),
		Vector2(42, 464), Vector2(72, 464), Vector2(72, 356), Vector2(38, 356),
		Vector2(38, 252), Vector2(72, 252), Vector2(72, 210), Vector2(98, 210),
		Vector2(98, 142), Vector2(58, 142), Vector2(58, 138), Vector2(32, 138),
		Vector2(32, 104), Vector2(68, 104), Vector2(68, 82), Vector2(130, 82),
		Vector2(130, 66), Vector2(208, 66)
	])
	draw_colored_polygon(edge, EDGE_COLOR)

	var land := PackedVector2Array([
		Vector2(220, 42), Vector2(514, 42), Vector2(514, 68), Vector2(762, 68),
		Vector2(762, 42), Vector2(902, 42), Vector2(902, 78), Vector2(962, 78),
		Vector2(962, 108), Vector2(1004, 108), Vector2(1004, 144), Vector2(1052, 144),
		Vector2(1052, 168), Vector2(1100, 168), Vector2(1100, 194), Vector2(1076, 194),
		Vector2(1076, 318), Vector2(1114, 318), Vector2(1114, 330), Vector2(1082, 330),
		Vector2(1082, 456), Vector2(1104, 456), Vector2(1104, 482), Vector2(1070, 482),
		Vector2(1070, 530), Vector2(990, 530), Vector2(990, 562), Vector2(928, 562),
		Vector2(928, 546), Vector2(762, 546), Vector2(762, 586), Vector2(624, 586),
		Vector2(624, 610), Vector2(504, 610), Vector2(504, 584), Vector2(310, 584),
		Vector2(310, 560), Vector2(258, 560), Vector2(258, 588), Vector2(148, 588),
		Vector2(148, 554), Vector2(90, 554), Vector2(90, 482), Vector2(56, 482),
		Vector2(56, 478), Vector2(86, 478), Vector2(86, 342), Vector2(52, 342),
		Vector2(52, 266), Vector2(86, 266), Vector2(86, 224), Vector2(112, 224),
		Vector2(112, 128), Vector2(72, 128), Vector2(72, 124), Vector2(46, 124),
		Vector2(46, 118), Vector2(82, 118), Vector2(82, 96), Vector2(144, 96),
		Vector2(144, 80), Vector2(220, 80)
	])
	draw_colored_polygon(land, LAND_COLOR)

	_draw_dotted_routes()
	for center in LEVEL_CENTERS:
		_draw_island(center)
	_draw_pin(LEVEL_CENTERS[0] + Vector2(-28.0, -54.0))
	_draw_map_details()

func _draw_dotted_routes() -> void:
	for index in range(LEVEL_CENTERS.size() - 1):
		var start: Vector2 = LEVEL_CENTERS[index] + Vector2(18.0, 6.0)
		var finish: Vector2 = LEVEL_CENTERS[index + 1] - Vector2(18.0, 4.0)
		var horizontal_distance := finish.x - start.x
		var bend := -46.0 if index % 2 == 0 else 46.0
		_draw_dotted_curve(
			start,
			start + Vector2(horizontal_distance * 0.34, bend),
			finish - Vector2(horizontal_distance * 0.34, bend),
			finish
		)

func _draw_dotted_curve(start: Vector2, control_a: Vector2, control_b: Vector2, finish: Vector2) -> void:
	var previous := start
	for step in range(1, 48):
		var t := float(step) / 48.0
		var point := _bezier_point(start, control_a, control_b, finish, t)
		if step % 2 == 1:
			draw_line(previous, point, ROUTE_COLOR, 2.6, true)
		previous = point

func _bezier_point(start: Vector2, control_a: Vector2, control_b: Vector2, finish: Vector2, t: float) -> Vector2:
	var inverse := 1.0 - t
	return inverse * inverse * inverse * start \
		+ 3.0 * inverse * inverse * t * control_a \
		+ 3.0 * inverse * t * t * control_b \
		+ t * t * t * finish

func _draw_island(center: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-44, 9), center + Vector2(-31, 0), center + Vector2(-14, 4),
		center + Vector2(-1, -2), center + Vector2(15, 3), center + Vector2(34, 1),
		center + Vector2(46, 10), center + Vector2(24, 14), center + Vector2(-23, 14)
	]), Color(0.72, 0.60, 0.39))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-37, 7), center + Vector2(-23, 2), center + Vector2(-9, 6),
		center + Vector2(4, 1), center + Vector2(18, 6), center + Vector2(33, 4),
		center + Vector2(40, 9), center + Vector2(19, 11), center + Vector2(-18, 11)
	]), ISLAND_COLOR)

	for tree_index in range(3):
		var trunk_base := center + Vector2(float(tree_index - 1) * 15.0, 3.0)
		var crown := trunk_base + Vector2(float(tree_index - 1) * 2.0 - 2.0, -23.0 - float(tree_index % 2) * 5.0)
		draw_line(trunk_base, crown, Color(0.32, 0.25, 0.19), 2.3, true)
		for frond_index in range(6):
			var angle := -PI * 0.90 + float(frond_index) * PI * 0.30
			var tip := crown + Vector2(cos(angle) * 13.0, sin(angle) * 9.0)
			draw_line(crown, tip, Color(0.30, 0.37, 0.29), 2.2, true)
			draw_line(tip, tip + Vector2(cos(angle + 0.55) * 5.0, 4.0), Color(0.30, 0.37, 0.29), 1.8, true)

func _draw_pin(position: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-5.0, 8.0),
		position + Vector2(3.0, 8.0),
		position + Vector2(-3.0, 32.0)
	]), Color(0.78, 0.16, 0.14))
	draw_circle(position, 12.0, Color(0.78, 0.16, 0.14))
	draw_circle(position + Vector2(-3.0, -3.0), 3.0, Color(1.0, 0.89, 0.75))

func _draw_map_details() -> void:
	draw_polyline(PackedVector2Array([
		Vector2(118, 294), Vector2(160, 276), Vector2(196, 282), Vector2(222, 269)
	]), Color(0.75, 0.62, 0.40, 0.32), 2.0, true)
	draw_polyline(PackedVector2Array([
		Vector2(830, 160), Vector2(870, 145), Vector2(905, 151), Vector2(934, 136)
	]), Color(0.75, 0.62, 0.40, 0.32), 2.0, true)
	draw_polyline(PackedVector2Array([
		Vector2(216, 492), Vector2(258, 478), Vector2(292, 486), Vector2(322, 472)
	]), Color(0.75, 0.62, 0.40, 0.32), 2.0, true)

func _make_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.shadow_color = Color(0.25, 0.19, 0.14, 0.34)
	style.shadow_size = 3
	style.set_content_margin_all(4.0)
	return style

func _on_level_pressed(level_index: int) -> void:
	if level_index == 0:
		LoadingLoader.load_screen_to_scene("res://scenes/battle_scene.tscn")
	else:
		status_label.text = "LEVEL %d IS A PLACEHOLDER FOR A FUTURE STAGE" % (level_index + 1)

func _on_back_pressed() -> void:
	LoadingLoader.load_screen_to_scene("res://scenes/main_menu.tscn")
