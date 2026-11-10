extends Control

const COLOR_NAVY := Color("#0b1628")
const COLOR_PANEL := Color("#13243b")
const COLOR_PANEL_LIGHT := Color("#1b304b")
const COLOR_GOLD := Color("#f0b840")
const COLOR_TEXT := Color("#f4f0e7")
const COLOR_MUTED := Color("#a8b5c7")
const COLOR_MAP := Color("#d8cfad")
const COLOR_ROAD := Color("#87927d")
const COLOR_SEA := Color("#4a8691")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var font := ThemeDB.fallback_font
	if font == null:
		return

	# Main application frame
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_NAVY, true)
	draw_rect(Rect2(0, 0, w, 68), COLOR_PANEL, true)
	draw_rect(Rect2(0, 68, 76, h - 68), COLOR_PANEL, true)
	draw_line(Vector2(0, 68), Vector2(w, 68), Color("#31435b"), 1.0)
	draw_line(Vector2(76, 68), Vector2(76, h), Color("#31435b"), 1.0)

	# Header
	draw_string(font, Vector2(24, 43), "TRANSIT MANAGER", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, COLOR_TEXT)
	draw_string(font, Vector2(263, 42), "STAGE 0  /  PROJECT SHELL", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_GOLD)
	draw_string(font, Vector2(w - 250, 41), "OFFLINE  •  LANDSCAPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_MUTED)

	# Navigation rail
	var nav_labels := ["MAP", "FLEET", "CONTRACTS", "COMPANY"]
	for i in range(nav_labels.size()):
		var y := 115.0 + float(i) * 66.0
		var active := i == 0
		if active:
			draw_rect(Rect2(8, y - 25, 60, 46), Color("#263c55"), true)
		draw_string(font, Vector2(20, y + 5), nav_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_GOLD if active else COLOR_MUTED)

	# Map canvas placeholder (intentionally not real map data)
	var map_rect := Rect2(96, 88, maxf(420.0, w - 440.0), h - 112.0)
	draw_rect(map_rect, COLOR_MAP, true)
	draw_rect(map_rect, Color("#f1e8cd"), false, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(map_rect.position.x, map_rect.position.y + map_rect.size.y * 0.69),
		Vector2(map_rect.position.x + map_rect.size.x * 0.33, map_rect.position.y + map_rect.size.y * 0.65),
		Vector2(map_rect.position.x + map_rect.size.x * 0.34, map_rect.position.y + map_rect.size.y),
		Vector2(map_rect.position.x, map_rect.position.y + map_rect.size.y)
	]), COLOR_SEA)

	# Schematic route strokes demonstrate the future map layer without claiming real geography.
	var points := PackedVector2Array([
		Vector2(map_rect.position.x + map_rect.size.x * 0.16, map_rect.position.y + map_rect.size.y * 0.26),
		Vector2(map_rect.position.x + map_rect.size.x * 0.40, map_rect.position.y + map_rect.size.y * 0.31),
		Vector2(map_rect.position.x + map_rect.size.x * 0.54, map_rect.position.y + map_rect.size.y * 0.48),
		Vector2(map_rect.position.x + map_rect.size.x * 0.77, map_rect.position.y + map_rect.size.y * 0.44),
		Vector2(map_rect.position.x + map_rect.size.x * 0.84, map_rect.position.y + map_rect.size.y * 0.68)
	])
	draw_polyline(points, Color("#f5f0df"), 13.0, true)
	draw_polyline(points, COLOR_ROAD, 6.0, true)
	for point in points:
		draw_circle(point, 7.0, COLOR_GOLD)
		draw_circle(point, 3.0, COLOR_NAVY)

	draw_string(font, Vector2(map_rect.position.x + 20, map_rect.position.y + 35), "SOUTH AFRICA MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#344437"))
	draw_string(font, Vector2(map_rect.position.x + 20, map_rect.position.y + 60), "Schematic placeholder • geographic map begins in Stage 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#53604e"))

	# Stage 0 handoff panel
	var panel_x := map_rect.end.x + 18.0
	var panel_w := maxf(270.0, w - panel_x - 22.0)
	var panel_rect := Rect2(panel_x, 88, panel_w, h - 112.0)
	draw_rect(panel_rect, COLOR_PANEL, true)
	draw_rect(panel_rect, Color("#31435b"), false, 1.0)
	draw_string(font, Vector2(panel_x + 20, 124), "FOUNDATION READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COLOR_GOLD)
	draw_string(font, Vector2(panel_x + 20, 163), "National network goal", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
	draw_string(font, Vector2(panel_x + 20, 187), "All nine provinces", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_MUTED)
	draw_string(font, Vector2(panel_x + 20, 210), "Cities, towns and metro districts", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_MUTED)
	draw_line(Vector2(panel_x + 20, 234), Vector2(panel_x + panel_w - 20, 234), Color("#31435b"), 1.0)
	draw_string(font, Vector2(panel_x + 20, 267), "CORE GAMEPLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_GOLD)
	draw_string(font, Vector2(panel_x + 20, 296), "Local delivery", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
	draw_string(font, Vector2(panel_x + 20, 324), "Terminal line haul", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
	draw_string(font, Vector2(panel_x + 20, 352), "Long-haul contracts", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
	draw_line(Vector2(panel_x + 20, 376), Vector2(panel_x + panel_w - 20, 376), Color("#31435b"), 1.0)
	draw_string(font, Vector2(panel_x + 20, 411), "NEXT  /  STAGE 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_GOLD)
	draw_string(font, Vector2(panel_x + 20, 441), "Build the South Africa map", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
	draw_string(font, Vector2(panel_x + 20, 466), "and detailed Western Cape view.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_MUTED)

	# Footer status
	draw_string(font, Vector2(96, h - 12), "GODOT 4.7  •  OFFLINE-FIRST  •  DATA-DRIVEN WORLD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_MUTED)
