extends Button

# Vertices use the source illustration's normalized coordinates, so the outline
# follows the painted object even when KEEP_ASPECT_COVERED crops the background.
var outline := PackedVector2Array()
var source_size := Vector2(1536, 1024)
# When false the hotspot keeps its polygon hit area and hover tooltip but draws
# no frame at all; the scene's own sign or label carries the visual instead
# (used for market plaques so buildings are no longer circled by gold borders).
var draw_frame := true

func _polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	var scale_factor := maxf(size.x / source_size.x, size.y / source_size.y)
	var drawn := source_size * scale_factor
	var offset := (size - drawn) * 0.5
	for point in outline: points.append(point * drawn + offset)
	return points

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _polygon()) if outline.size() >= 3 else Rect2(Vector2.ZERO, size).has_point(point)

func _draw() -> void:
	if not draw_frame or outline.size() < 3: return
	var points := _polygon()
	var active := is_hovered() or has_focus()
	draw_colored_polygon(points, Color(1, 0.78, 0.32, 0.12 if active else 0.02))
	points.append(points[0])
	draw_polyline(points, Color(1, 0.83, 0.43, 1.0 if active else 0.75), 4.0 if active else 2.0, true)

func _ready() -> void:
	flat = false
	resized.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.07, 0.05, 0.025)
	normal.border_color = Color(0.85, 0.71, 0.42, 0.34)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.85, 0.71, 0.42, 0.16)
	hover.border_color = Color(0.95, 0.82, 0.52, 0.95)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(10)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("focus", hover)
	add_theme_stylebox_override("pressed", hover)
	if not outline.is_empty() or not draw_frame:
		for state in ["normal", "hover", "focus", "pressed"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
