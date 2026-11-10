extends Control

const COLOR_NAVY := Color("#0b1628")
const COLOR_PANEL := Color("#13243b")
const COLOR_PANEL_LIGHT := Color("#1b304b")
const COLOR_GOLD := Color("#f0b840")
const COLOR_TEXT := Color("#f4f0e7")
const COLOR_MUTED := Color("#a8b5c7")
const COLOR_LAND := Color("#c8c5a6")
const COLOR_SEA := Color("#315f70")
const COLOR_BORDER := Color("#e4dfc5")
const COLOR_ROUTE := Color("#e3a33a")
const COLOR_MUNICIPALITY := Color("#536b5c")
const FONT_SIZE := 12

var map_mode := 0 # 0 national, 1 Western Cape, 2 Cape Town metro
var map_rect := Rect2()
var world_bounds := Vector4(16.0, -35.3, 33.3, -21.8) # west, south, east, north
var world_cos := 0.84
var provinces: Array = []
var municipalities: Array = []
var settlements: Array = []
var suburbs: Array = []
var terminals: Array = []
var corridors: Array = []
var selected_place := "South Africa"
var selected_item: Dictionary = {"name": "South Africa", "type": "National map", "province": "All nine provinces"}
var hit_places: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	provinces = _read_json("res://data/south_africa_provinces.geojson").get("features", [])
	municipalities = _read_json("res://data/municipalities.json")
	settlements = _read_json("res://data/stage1_settlements.json")
	suburbs = _read_json("res://data/cape_town_suburbs.json")
	terminals = _read_json("res://data/stage1_terminals.json")
	corridors = _read_json("res://data/stage1_corridors.json")
	queue_redraw()


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return {}
	var parsed := JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed != null else {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var font := ThemeDB.fallback_font
	if font == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), COLOR_NAVY, true)
	draw_rect(Rect2(0, 0, w, 70), COLOR_PANEL, true)
	draw_rect(Rect2(0, 70, 76, h - 70), COLOR_PANEL, true)
	draw_line(Vector2(0, 70), Vector2(w, 70), Color("#31435b"), 1.0)
	draw_line(Vector2(76, 70), Vector2(76, h), Color("#31435b"), 1.0)

	draw_string(font, Vector2(22, 43), "TRANSIT MANAGER", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COLOR_TEXT)
	draw_string(font, Vector2(259, 42), "STAGE 1  /  SOUTH AFRICA MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_GOLD)
	draw_string(font, Vector2(w - 236, 41), "OFFLINE  •  LANDSCAPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_MUTED)

	var nav_labels := ["MAP", "FLEET", "CONTRACTS", "COMPANY"]
	for i in range(nav_labels.size()):
		var y := 114.0 + float(i) * 66.0
		var active := i == 0
		if active:
			draw_rect(Rect2(8, y - 25, 60, 46), Color("#263c55"), true)
		draw_string(font, Vector2(18, y + 4), nav_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_GOLD if active else COLOR_MUTED)

	var compact := w < 1150.0
	var panel_x := maxf(850.0, w - 414.0)
	if compact:
		map_rect = Rect2(86, 96, w - 106.0, h - 126.0)
	else:
		map_rect = Rect2(96, 96, panel_x - 114.0, h - 126.0)
	draw_rect(map_rect, COLOR_SEA, true)
	draw_rect(map_rect, Color("#214a5b"), false, 2.0)

	var mode_names := ["SOUTH AFRICA", "WESTERN CAPE", "CAPE TOWN METRO"]
	var mode_button := Rect2(map_rect.position.x + 14, map_rect.position.y + 12, 190, 34)
	draw_rect(mode_button, Color("#122b3c"), true)
	draw_rect(mode_button, Color("#6f8790"), false, 1.0)
	draw_string(font, mode_button.position + Vector2(12, 22), mode_names[map_mode] + "  ▾", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)
	draw_string(font, Vector2(map_rect.end.x - 232, map_rect.position.y + 33), "Tap a place • tap view to zoom", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d4dfd8"))

	_set_bounds()
	_draw_map_data(font)
	_draw_place_markers(font)

	if compact:
		var compact_rect := Rect2(map_rect.position.x + 10.0, map_rect.end.y - 79.0, map_rect.size.x - 20.0, 66.0)
		draw_rect(compact_rect, Color("#10243a"), true)
		draw_rect(compact_rect, Color("#526a78"), false, 1.0)
		_draw_compact_info(font, compact_rect)
	else:
		var panel_rect := Rect2(panel_x, 96, w - panel_x - 22.0, h - 126.0)
		draw_rect(panel_rect, COLOR_PANEL, true)
		draw_rect(panel_rect, Color("#31435b"), false, 1.0)
		_draw_info_panel(font, panel_rect)

	draw_string(font, Vector2(96, h - 11), "NATURAL EARTH • OPEN ADMIN DATA (CC BY 4.0) • OFFLINE MAP DATA", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COLOR_MUTED)


func _set_bounds() -> void:
	if map_mode == 1:
		world_bounds = Vector4(16.0, -35.4, 25.4, -31.0)
	elif map_mode == 2:
		world_bounds = Vector4(18.15, -34.15, 18.83, -33.55)
	else:
		world_bounds = Vector4(16.0, -35.4, 33.3, -21.8)
	world_cos = cos(deg_to_rad((world_bounds.y + world_bounds.w) * 0.5))


func _map_point(lon: float, lat: float) -> Vector2:
	var west := world_bounds.x * world_cos
	var east := world_bounds.z * world_cos
	var south := world_bounds.y
	var north := world_bounds.w
	var content := map_rect.grow(-22.0)
	content.position.y += 38.0
	content.size.y -= 38.0
	var world_w := east - west
	var world_h := north - south
	var scale := minf(content.size.x / world_w, content.size.y / world_h)
	var offset := Vector2(content.position.x + (content.size.x - world_w * scale) * 0.5, content.position.y + (content.size.y - world_h * scale) * 0.5)
	return Vector2(offset.x + (lon * world_cos - west) * scale, offset.y + (north - lat) * scale)


func _draw_map_data(font: Font) -> void:
	if map_mode != 2:
		for feature in provinces:
			var props: Dictionary = feature.get("properties", {})
			var name: String = props.get("name", "")
			if map_mode == 1 and name != "Western Cape":
				continue
			var geometry: Dictionary = feature.get("geometry", {})
			var polygons: Array = []
			if geometry.get("type", "") == "Polygon":
				polygons = [geometry.get("coordinates", [])]
			elif geometry.get("type", "") == "MultiPolygon":
				polygons = geometry.get("coordinates", [])
			for polygon in polygons:
				if polygon.is_empty():
					continue
				var ring: Array = polygon[0]
				var points := PackedVector2Array()
				for coord in ring:
					points.append(_map_point(float(coord[0]), float(coord[1])))
				if points.size() >= 3:
					var fill := Color("#b9c39a") if name == "Western Cape" else COLOR_LAND
					draw_colored_polygon(points, fill)
					draw_polyline(points, COLOR_BORDER, 1.2, true)
			if map_mode == 0:
				var lp := _map_point(float(props.get("label_lon", 0.0)), float(props.get("label_lat", 0.0)))
				draw_string(font, lp + Vector2(-font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x * 0.5, 4), name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#485444"))

	_draw_corridors(font)


func _draw_corridors(font: Font) -> void:
	for corridor in corridors:
		var points_data: Array = corridor.get("points", [])
		var points := PackedVector2Array()
		for coord in points_data:
			var p := _map_point(float(coord[0]), float(coord[1]))
			if map_rect.has_point(p):
				points.append(p)
		if points.size() >= 2:
			draw_polyline(points, Color("#f7e9be"), 5.0, true)
			draw_polyline(points, COLOR_ROUTE, 2.0, true)
			var mid := points[points.size() / 2]
			draw_string(ThemeDB.fallback_font, mid + Vector2(5, -5), str(corridor.get("name", "N")), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#fff1c7"))


func _draw_place_markers(font: Font) -> void:
	hit_places.clear()
	var marker_list: Array = []
	if map_mode == 2:
		marker_list = suburbs
		for item in terminals:
			if item.get("city", "") == "Cape Town":
				marker_list.append(item)
	else:
		for item in municipalities:
			if map_mode == 0 or item.get("province", "") == "Western Cape":
				marker_list.append(item)
		for item in settlements:
			if map_mode == 0 or item.get("province", "") == "Western Cape":
				marker_list.append(item)
		for item in terminals:
			if map_mode == 0 or item.get("province", "") == "Western Cape":
				marker_list.append(item)

	for item in marker_list:
		var p := _map_point(float(item.get("lon", 0.0)), float(item.get("lat", 0.0)))
		if not map_rect.grow(-5).has_point(p):
			continue
		var name := str(item.get("name", "Place"))
		var kind := str(item.get("type", "Municipality"))
		var is_terminal := kind == "terminal"
		var is_major := kind in ["city", "suburb_district", "terminal"]
		var radius := 5.2 if is_terminal else (4.2 if is_major else 2.3)
		var tint := COLOR_GOLD if name == selected_place else (Color("#f6efe0") if is_major else COLOR_MUNICIPALITY)
		if is_terminal:
			draw_rect(Rect2(p - Vector2(radius + 2.0, radius + 2.0), Vector2((radius + 2.0) * 2.0, (radius + 2.0) * 2.0)), Color("#172b34"), true)
			draw_rect(Rect2(p - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), tint, true)
		else:
			draw_circle(p, radius + 2.0, Color("#172b34"))
			draw_circle(p, radius, tint)
		if is_major or map_mode == 2:
			draw_string(font, p + Vector2(7, 4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#fff7e5"))
		hit_places.append({"name": name, "position": p, "radius": 13.0, "item": item})


func _draw_compact_info(font: Font, rect: Rect2) -> void:
	var title := ["NATIONAL NETWORK", "WESTERN CAPE", "CAPE TOWN METRO"][map_mode]
	draw_string(font, rect.position + Vector2(12, 21), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_GOLD)
	draw_string(font, rect.position + Vector2(12, 45), selected_place, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
	var summary := "9 provinces • 213 municipality anchors" if map_mode == 0 else ("Regional anchors + sample towns" if map_mode == 1 else "11 sample suburb districts")
	draw_string(font, Vector2(rect.position.x + rect.size.x - 270.0, rect.position.y + 38.0), summary, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_MUTED)


func _draw_info_panel(font: Font, rect: Rect2) -> void:
	var x := rect.position.x + 20.0
	var y := rect.position.y + 32.0
	var line_end := rect.end.x - 20.0
	draw_string(font, Vector2(x, y), "MAP EXPLORER", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, COLOR_GOLD)
	y += 38.0
	draw_string(font, Vector2(x, y), ["National network", "Western Cape", "Cape Town metro"][map_mode], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COLOR_TEXT)
	y += 28.0
	draw_string(font, Vector2(x, y), "SELECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_MUTED)
	y += 21.0
	draw_string(font, Vector2(x, y), selected_place, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_TEXT)
	y += 23.0
	var selected_kind := str(selected_item.get("type", "Place"))
	var selected_parent := str(selected_item.get("province", selected_item.get("district", "")))
	draw_string(font, Vector2(x, y), selected_kind.replace("_", " ").capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_GOLD)
	y += 20.0
	if selected_parent != "":
		draw_string(font, Vector2(x, y), selected_parent, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_MUTED)
		y += 20.0
	if selected_kind == "terminal":
		draw_string(font, Vector2(x, y), "Demo terminal • not yet owned", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_MUTED)
		y += 21.0
	else:
		y += 5.0
	y += 8.0
	draw_line(Vector2(x, y), Vector2(line_end, y), Color("#31435b"), 1.0)
	y += 28.0

	if map_mode == 0:
		draw_string(font, Vector2(x, y), "9 provinces", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		y += 22.0
		draw_string(font, Vector2(x, y), "213 municipality anchors", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_MUTED)
		y += 22.0
		draw_string(font, Vector2(x, y), "20 sample cities and towns", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_MUTED)
	elif map_mode == 1:
		draw_string(font, Vector2(x, y), "Western Cape network seed", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_TEXT)
		y += 22.0
		draw_string(font, Vector2(x, y), "Municipal anchors + key towns", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_MUTED)
	else:
		draw_string(font, Vector2(x, y), "Cape Town suburb seed", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_TEXT)
		y += 22.0
		draw_string(font, Vector2(x, y), "11 sample districts", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_MUTED)

	y += 32.0
	draw_line(Vector2(x, y), Vector2(line_end, y), Color("#31435b"), 1.0)
	y += 27.0
	draw_string(font, Vector2(x, y), "LONG-HAUL NETWORK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_GOLD)
	y += 24.0
	draw_string(font, Vector2(x, y), "N1  •  N2  •  N3  •  N4  •  N7", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)
	y += 23.0
	draw_string(font, Vector2(x, y), "Illustrative corridor strokes", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_MUTED)
	y += 19.0
	draw_string(font, Vector2(x, y), "not routing geometry or distances.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_MUTED)
	y += 30.0
	draw_line(Vector2(x, y), Vector2(line_end, y), Color("#31435b"), 1.0)
	y += 27.0
	draw_string(font, Vector2(x, y), "STAGE 1 SCOPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_GOLD)
	y += 22.0
	draw_string(font, Vector2(x, y), "National overview + Western Cape", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_TEXT)
	y += 18.0
	draw_string(font, Vector2(x, y), "zoom + Cape Town district seed.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_TEXT)
	y += 29.0
	draw_string(font, Vector2(x, y), "Tap the map to change view.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_MUTED)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.x < 76.0:
			return
		if event.position.x >= map_rect.position.x and event.position.x <= map_rect.end.x:
			if event.position.y < map_rect.position.y + 55.0:
				map_mode = (map_mode + 1) % 3
				selected_place = ["South Africa", "Western Cape", "Cape Town"][map_mode]
				queue_redraw()
				accept_event()
				return
			for entry in hit_places:
				if event.position.distance_to(entry["position"]) <= entry["radius"]:
					selected_place = entry["name"]
					selected_item = entry["item"]
					queue_redraw()
					accept_event()
					return
			if map_rect.has_point(event.position):
				return
