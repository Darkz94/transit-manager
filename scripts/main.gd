extends Control

var c_header_title := Color("#FFFFFF")
var c_header_subtitle := Color("#BEE6FF")
var c_province_border := Color("#FFFFFF")
var c_info_bg := Color("#FFFFFF")
var c_info_detail := Color("#E65100")
var c_footer_text := Color("#BEE6FF")
var c_bg := Color("#DCEEFF")
var c_map := Color("#BFE8FF")
var c_topbar := Color("#0B3A5A")
var c_country := Color("#FFF8DC")
var c_cyan := Color("#0B3A5A")
var c_city := Color("#0B3A5A")
var c_text := Color("#0B3A5A")
var c_muted := Color("#5A7A8A")
var c_gold := Color("#E65100")
var c_orange := Color("#FF7A00")
var c_divider := Color("#BFE8FF")
var c_route_shadow := Color("#FFFFFF")
var c_marker_outline := Color("#FFFFFF")
var c_terminal_outline := Color("#FFFFFF")
var c_owned_terminal := Color("#16A34A")
var c_button := Color("#FFFFFF")
var c_button_text := Color("#0B3A5A")
var c_button_border := Color("#FF7A00")
var c_legend := Color(1.0, 1.0, 1.0, 0.9)
var route_colors: Dictionary = {}
var theme_mode := 0 # 0 daytime, 1 nighttime
var theme_button_rect := Rect2()
var clock_button_rect := Rect2()
var startup_status := ""
var autosave_elapsed := 0.0
var last_clock_label := ""
var company_name := "Transit Freight"
var company_cash := 250000
var screen_mode := 0 # 0 map, 1 operations
var operations_tab := 0 # 0 local jobs, 1 long-haul contracts
var operations_ready := false
var operation_buttons: Array = []

var map_mode := 0 # 0 country, 1 province, 2 city
var selected_province := "Western Cape"
var selected_city := "Cape Town"
var city_focus_lat := -33.9249
var city_focus_lon := 18.4241
var selected_place := "South Africa"
var selected_item: Dictionary = {"name": "South Africa", "type": "Map view"}
var map_rect := Rect2()
var info_rect := Rect2()
var controls_rect := Rect2()
var world_bounds := Vector4(15.8, -35.7, 33.2, -21.0) # west, south, east, north
var world_cos := 0.85
var provinces: Array = []
var municipalities: Array = []
var settlements: Array = []
var suburbs: Array = []
var terminals: Array = []
var corridors: Array = []
var hit_places: Array = []
var view_buttons: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	SimulationClock.time_changed.connect(_on_clock_changed)
	var saved_state: Dictionary = GameSave.load_game()
	if saved_state.is_empty():
		SimulationClock.restore(6.0 * 60.0 * 60.0, 1, 0.0)
		CompanyOperations.start_new_game(SimulationClock.game_time_seconds)
		startup_status = "New offline company created. Your progress is saved on this device."
	else:
		company_name = str(saved_state.get("company_name", company_name))
		company_cash = int(saved_state.get("company_cash", company_cash))
		theme_mode = int(saved_state.get("theme_mode", theme_mode))
		map_mode = int(saved_state.get("map_mode", map_mode))
		selected_province = str(saved_state.get("selected_province", selected_province))
		selected_city = str(saved_state.get("selected_city", selected_city))
		selected_place = str(saved_state.get("selected_place", selected_place))
		selected_item = {"name": selected_place, "type": "Map view"}
		screen_mode = clampi(int(saved_state.get("screen_mode", 0)), 0, 1)
		city_focus_lat = float(saved_state.get("city_focus_lat", city_focus_lat))
		city_focus_lon = float(saved_state.get("city_focus_lon", city_focus_lon))
		map_mode = clampi(map_mode, 0, 2)
		theme_mode = clampi(theme_mode, 0, 1)
		var saved_time := float(saved_state.get("game_time_seconds", 6.0 * 60.0 * 60.0))
		var saved_speed := int(saved_state.get("speed_index", 1))
		var elapsed_real := maxf(0.0, float(Time.get_unix_time_from_system() - int(saved_state.get("last_saved_unix", Time.get_unix_time_from_system()))))
		var caught_up := SimulationClock.restore(saved_time, saved_speed, elapsed_real)
		var operation_data: Dictionary = saved_state.get("operations", {})
		if operation_data.is_empty():
			CompanyOperations.start_new_game(SimulationClock.game_time_seconds)
		else:
			CompanyOperations.load_state(operation_data, SimulationClock.game_time_seconds)
		if caught_up > 0.0:
			startup_status = "Offline time advanced %s. Catch-up is capped at 12 game hours." % _format_game_duration(caught_up)
		elif GameSave.recovered_backup:
			startup_status = "Recovered your last complete local save."
	operations_ready = true
	CompanyOperations.state_changed.connect(_on_operations_changed)
	CompanyOperations.message_changed.connect(_on_operations_message_changed)
	provinces = _read_json("res://data/south_africa_provinces.geojson").get("features", [])
	municipalities = _read_json("res://data/municipalities.json")
	settlements = _read_json("res://data/stage1_settlements.json")
	suburbs = _read_json("res://data/cape_town_suburbs.json")
	terminals = _read_json("res://data/stage1_terminals.json")
	corridors = _read_json("res://data/stage1_corridors.json")
	_apply_theme()
	last_clock_label = SimulationClock.clock_label()
	_save_progress()
	queue_redraw()


func _process(delta: float) -> void:
	autosave_elapsed += delta
	if autosave_elapsed >= 30.0:
		autosave_elapsed = 0.0
		_save_progress()


func _on_clock_changed(_game_time_seconds: float) -> void:
	if operations_ready:
		CompanyOperations.advance_to(_game_time_seconds)
		company_cash = CompanyOperations.cash
	var current_label := SimulationClock.clock_label()
	if current_label != last_clock_label:
		last_clock_label = current_label
		queue_redraw()


func _on_operations_changed() -> void:
	company_cash = CompanyOperations.cash
	queue_redraw()


func _on_operations_message_changed(_message: String) -> void:
	startup_status = ""
	queue_redraw()


func _format_game_duration(game_seconds: float) -> String:
	var total_minutes := int(floor(game_seconds / 60.0))
	var hours := int(total_minutes / 60)
	var minutes := total_minutes % 60
	if hours > 0:
		return "%d game hours %d minutes" % [hours, minutes]
	return "%d game minutes" % minutes


func _save_progress() -> void:
	company_cash = CompanyOperations.cash
	var state := {
		"game_time_seconds": SimulationClock.game_time_seconds,
		"speed_index": SimulationClock.speed_index,
		"company_name": company_name,
		"company_cash": company_cash,
		"theme_mode": theme_mode,
		"map_mode": map_mode,
		"selected_province": selected_province,
		"selected_city": selected_city,
		"selected_place": selected_place,
		"city_focus_lat": city_focus_lat,
		"city_focus_lon": city_focus_lon,
		"screen_mode": screen_mode,
		"operations": CompanyOperations.snapshot()
	}
	GameSave.save_game(state)


func _apply_theme() -> void:
	if theme_mode == 0:
		c_header_title = Color("#FFFFFF")
		c_header_subtitle = Color("#BEE6FF")
		c_province_border = Color("#FFFFFF")
		c_info_bg = Color("#FFFFFF")
		c_info_detail = Color("#E65100")
		c_footer_text = Color("#BEE6FF")
		c_bg = Color("#DCEEFF")
		c_map = Color("#BFE8FF")
		c_topbar = Color("#0B3A5A")
		c_country = Color("#FFF8DC")
		c_cyan = Color("#0B3A5A")
		c_city = Color("#0B3A5A")
		c_text = Color("#0B3A5A")
		c_muted = Color("#5A7A8A")
		c_gold = Color("#E65100")
		c_orange = Color("#FF7A00")
		c_divider = Color("#BFE8FF")
		c_route_shadow = Color("#FFFFFF")
		c_marker_outline = Color("#FFFFFF")
		c_terminal_outline = Color("#FFFFFF")
		c_owned_terminal = Color("#16A34A")
		c_button = Color("#FFFFFF")
		c_button_text = Color("#0B3A5A")
		c_button_border = Color("#FF7A00")
		c_legend = Color(1.0, 1.0, 1.0, 0.9)
		route_colors = {"N1": Color("#E53935"), "N2": Color("#B77900"), "N3": Color("#E65100"), "N4": Color("#2D8DFF")}
	else:
		c_header_title = Color("#FFFFFF")
		c_header_subtitle = Color("#94A3B8")
		c_province_border = Color("#2DD4FF")
		c_info_bg = Color("#0B223A")
		c_info_detail = Color("#FFFFFF")
		c_footer_text = Color("#94A3B8")
		c_bg = Color("#050B16")
		c_map = Color("#0A1628")
		c_topbar = Color("#0B223A")
		c_country = Color("#101E33")
		c_cyan = Color("#2DD4FF")
		c_city = Color("#7EE8FF")
		c_text = Color("#FFFFFF")
		c_muted = Color("#94A3B8")
		c_gold = Color("#FFD400")
		c_orange = Color("#FF7A00")
		c_divider = Color("#1A2F4A")
		c_route_shadow = Color("#07101D")
		c_marker_outline = Color("#FFFFFF")
		c_terminal_outline = Color("#FFD400")
		c_owned_terminal = Color("#34D399")
		c_button = Color("#1A2F4A")
		c_button_text = Color("#FFFFFF")
		c_button_border = Color("#FF7A00")
		c_legend = Color(0.0, 0.0, 0.0, 0.72)
		route_colors = {"N1": Color("#FF2D2D"), "N2": Color("#FFD400"), "N3": Color("#FF7A00"), "N4": Color("#2D8DFF")}


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed != null else []


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var font := ThemeDB.fallback_font
	if font == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), c_bg, true)

	var header_h := 70.0
	var controls_h := 46.0
	var info_h := 48.0
	draw_rect(Rect2(0, 0, w, header_h), c_topbar, true)
	draw_line(Vector2(0, header_h), Vector2(w, header_h), c_divider, 1.0)
	var theme_name := "DAYTIME" if theme_mode == 0 else "NIGHT"
	var screen_title := "SOUTH AFRICA MAP - " + theme_name if screen_mode == 0 else "TRANSIT MANAGER - OPERATIONS"
	var subtitle := "9 PROVINCES  •  TERMINALS  •  CITIES  •  N1 / N2 / N3 / N4" if screen_mode == 0 else "CAPE TOWN LOCAL FREIGHT • OFFLINE COMPANY"
	draw_string(font, Vector2(0, 29), screen_title, HORIZONTAL_ALIGNMENT_CENTER, w, 23, c_header_title)
	draw_string(font, Vector2(0, 52), subtitle, HORIZONTAL_ALIGNMENT_CENTER, w, 10, c_muted)
	draw_string(font, Vector2(15, 23), SimulationClock.clock_label(), HORIZONTAL_ALIGNMENT_LEFT, 160, 11, c_header_title)
	clock_button_rect = Rect2(12.0, 34.0, 150.0, 27.0)
	draw_rect(clock_button_rect, c_button, true)
	draw_rect(clock_button_rect, c_button_border, false, 2.0)
	draw_string(font, clock_button_rect.position + Vector2(0, 18), SimulationClock.speed_label(), HORIZONTAL_ALIGNMENT_CENTER, clock_button_rect.size.x, 10, c_button_text)
	theme_button_rect = Rect2(w - 132.0, 11.0, 120.0, 48.0)
	draw_rect(theme_button_rect, c_button, true)
	draw_rect(theme_button_rect, c_button_border, false, 2.0)
	draw_string(font, theme_button_rect.position + Vector2(0, 29), "NIGHT MODE" if theme_mode == 0 else "DAY MODE", HORIZONTAL_ALIGNMENT_CENTER, theme_button_rect.size.x, 11, c_button_text)

	map_rect = Rect2(0, header_h, w, maxf(120.0, h - header_h - info_h - controls_h))
	info_rect = Rect2(0, map_rect.end.y, w, info_h)
	controls_rect = Rect2(0, info_rect.end.y, w, h - info_rect.end.y)
	if screen_mode == 0:
		draw_rect(map_rect, c_map, true)
		draw_rect(map_rect, c_divider, false, 1.0)
		_set_bounds()
		_draw_map(font)
		_draw_markers(font)
		_draw_map_legend(font)
		_draw_scale(font)
	else:
		_draw_operations_screen(font)

	draw_rect(info_rect, c_info_bg, true)
	draw_line(info_rect.position, Vector2(info_rect.end.x, info_rect.position.y), c_divider, 1.0)
	if screen_mode == 0:
		_draw_info(font)
	else:
		_draw_operations_info(font)

	draw_rect(controls_rect, c_topbar, true)
	_draw_view_buttons(font)
	if screen_mode == 0:
		draw_string(font, Vector2(8, h - 4), "Made with Natural Earth • Open Admin Data (CC BY 4.0) • Map routes are illustrative", HORIZONTAL_ALIGNMENT_LEFT, w - 16, 8, c_muted)


func _set_bounds() -> void:
	if map_mode == 1:
		world_bounds = _province_bounds(selected_province)
	elif map_mode == 2:
		var lon_radius := 0.43 if selected_city == "Cape Town" else 0.34
		var lat_radius := 0.34 if selected_city == "Cape Town" else 0.28
		world_bounds = Vector4(city_focus_lon - lon_radius, city_focus_lat - lat_radius, city_focus_lon + lon_radius, city_focus_lat + lat_radius)
	else:
		world_bounds = Vector4(15.8, -35.7, 33.2, -21.0)
	world_cos = cos(deg_to_rad((world_bounds.y + world_bounds.w) * 0.5))


func _province_bounds(province_name: String) -> Vector4:
	var west := 180.0
	var south := 90.0
	var east := -180.0
	var north := -90.0
	for feature in provinces:
		var props: Dictionary = feature.get("properties", {})
		if str(props.get("name", "")) != province_name:
			continue
		var geometry: Dictionary = feature.get("geometry", {})
		var polygons: Array = _geometry_polygons(geometry)
		for polygon in polygons:
			for ring in polygon:
				for coord in ring:
					west = minf(west, float(coord[0]))
					south = minf(south, float(coord[1]))
					east = maxf(east, float(coord[0]))
					north = maxf(north, float(coord[1]))
	if west > east:
		return Vector4(16.0, -35.4, 25.4, -31.0)
	var lon_pad := maxf(0.35, (east - west) * 0.06)
	var lat_pad := maxf(0.3, (north - south) * 0.06)
	return Vector4(west - lon_pad, south - lat_pad, east + lon_pad, north + lat_pad)


func _geometry_polygons(geometry: Dictionary) -> Array:
	if geometry.get("type", "") == "Polygon":
		return [geometry.get("coordinates", [])]
	if geometry.get("type", "") == "MultiPolygon":
		return geometry.get("coordinates", [])
	return []


func _map_point(lon: float, lat: float) -> Vector2:
	var west := world_bounds.x * world_cos
	var east := world_bounds.z * world_cos
	var south := world_bounds.y
	var north := world_bounds.w
	var content := map_rect.grow(-12.0)
	var world_w := maxf(0.001, east - west)
	var world_h := maxf(0.001, north - south)
	var scale := minf(content.size.x / world_w, content.size.y / world_h)
	var offset := Vector2(content.position.x + (content.size.x - world_w * scale) * 0.5, content.position.y + (content.size.y - world_h * scale) * 0.5)
	return Vector2(offset.x + (lon * world_cos - west) * scale, offset.y + (north - lat) * scale)


func _draw_map(font: Font) -> void:
	if map_mode != 2:
		for feature in provinces:
			var props: Dictionary = feature.get("properties", {})
			var province_name := str(props.get("name", ""))
			if map_mode == 1 and province_name != selected_province:
				continue
			var polygons: Array = _geometry_polygons(feature.get("geometry", {}))
			for polygon in polygons:
				if polygon.is_empty():
					continue
				var outer: Array = polygon[0]
				var points := PackedVector2Array()
				for coord in outer:
					points.append(_map_point(float(coord[0]), float(coord[1])))
				if points.size() >= 3:
					draw_colored_polygon(points, c_country)
					draw_polyline(points, c_province_border, 1.5, true)
			if map_mode == 0:
				var label_pos := _map_point(float(props.get("label_lon", 0.0)), float(props.get("label_lat", 0.0)))
				var label_size := 10 if province_name in ["Gauteng", "Mpumalanga", "Free State"] else 12
				draw_string(font, label_pos + Vector2(-35, 4), province_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 70, label_size, c_cyan)

	if map_mode == 0:
		_draw_neighbor_labels(font)
	_draw_corridors()
	if map_mode == 2:
		_draw_local_links()


func _draw_neighbor_labels(font: Font) -> void:
	var neighbor_labels := [
		{"name": "NAMIBIA", "lon": 16.2, "lat": -25.1},
		{"name": "BOTSWANA", "lon": 23.5, "lat": -22.0},
		{"name": "ZIMBABWE", "lon": 29.6, "lat": -21.8},
		{"name": "MOZAMBIQUE", "lon": 32.7, "lat": -24.4},
		{"name": "ESWATINI", "lon": 31.4, "lat": -26.5},
		{"name": "LESOTHO", "lon": 28.3, "lat": -29.5}
	]
	for item in neighbor_labels:
		var p := _map_point(float(item["lon"]), float(item["lat"]))
		draw_string(font, p, item["name"], HORIZONTAL_ALIGNMENT_CENTER, 90, 10, c_muted)
	draw_string(font, _map_point(16.2, -33.2), "SOUTH ATLANTIC OCEAN", HORIZONTAL_ALIGNMENT_LEFT, 180, 11, c_cyan)
	draw_string(font, _map_point(32.5, -33.5), "INDIAN OCEAN", HORIZONTAL_ALIGNMENT_LEFT, 130, 11, c_cyan)


func _draw_corridors() -> void:
	for corridor in corridors:
		var route_name := str(corridor.get("name", ""))
		var route_color: Color = route_colors.get(route_name, c_cyan)
		var coords: Array = corridor.get("points", [])
		for i in range(coords.size() - 1):
			var a := _map_point(float(coords[i][0]), float(coords[i][1]))
			var b := _map_point(float(coords[i + 1][0]), float(coords[i + 1][1]))
			if map_rect.grow(-2).has_point(a) and map_rect.grow(-2).has_point(b):
				draw_line(a, b, c_route_shadow, 7.0, true)
				draw_line(a, b, route_color, 3.2, true)
		if coords.size() > 2:
			var middle: Array = coords[coords.size() / 2]
			var mp := _map_point(float(middle[0]), float(middle[1]))
			if map_rect.grow(-15).has_point(mp):
				draw_string(ThemeDB.fallback_font, mp + Vector2(5, -5), route_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, route_color)


func _draw_local_links() -> void:
	var center := _map_point(city_focus_lon, city_focus_lat)
	var local_places := _marker_data()
	for item in local_places:
		if item.get("type", "") != "suburb_district":
			continue
		var p := _map_point(float(item.get("lon", 0.0)), float(item.get("lat", 0.0)))
		if map_rect.grow(-4).has_point(p):
			draw_line(center, p, c_route_shadow, 5.0, true)
			draw_line(center, p, c_orange, 2.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(map_rect.position.x + 14, map_rect.position.y + 20), "SAMPLE LOCAL LINKS • NOT STREET ROUTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_gold)


func _marker_data() -> Array:
	var result: Array = []
	if map_mode == 2 and selected_city == "Cape Town":
		result.append_array(suburbs)
	for item in settlements:
		if _inside_bounds(float(item.get("lon", 0.0)), float(item.get("lat", 0.0))):
			result.append(item)
	for item in municipalities:
		if _inside_bounds(float(item.get("lon", 0.0)), float(item.get("lat", 0.0))):
			result.append(item)
	for item in terminals:
		if _inside_bounds(float(item.get("lon", 0.0)), float(item.get("lat", 0.0))):
			result.append(item)
	return result


func _inside_bounds(lon: float, lat: float) -> bool:
	return lon >= world_bounds.x and lon <= world_bounds.z and lat >= world_bounds.y and lat <= world_bounds.w


func _draw_markers(font: Font) -> void:
	hit_places.clear()
	var marker_list := _marker_data()
	var local_center := _map_point(city_focus_lon, city_focus_lat)
	if map_mode == 2:
		draw_circle(local_center, 8.0, c_route_shadow)
		draw_circle(local_center, 5.0, c_city)

	for item in marker_list:
		var lon := float(item.get("lon", 0.0))
		var lat := float(item.get("lat", 0.0))
		var p := _map_point(lon, lat)
		if not map_rect.grow(-5).has_point(p):
			continue
		var name := str(item.get("name", "Place"))
		var kind := str(item.get("type", "municipality"))
		var is_terminal := kind == "terminal"
		var is_city := kind == "city" or kind == "town"
		if is_terminal:
			var terminal_rect := Rect2(p - Vector2(6, 6), Vector2(12, 12))
			var owned := CompanyOperations.owned_terminals.has(str(item.get("city", name)))
			draw_rect(terminal_rect, c_owned_terminal if owned else c_orange, true)
			draw_rect(terminal_rect, c_terminal_outline, false, 2.0)
		else:
			draw_circle(p, 6.0 if is_city else 3.4, c_marker_outline)
			draw_circle(p, 4.0 if is_city else 2.2, c_city)
		var terminal_at_city := false
		if is_city:
			for terminal in terminals:
				if absf(float(terminal.get("lat", 99.0)) - lat) < 0.01 and absf(float(terminal.get("lon", 99.0)) - lon) < 0.01:
					terminal_at_city = true
					break
		var should_label := is_terminal or (is_city and not terminal_at_city) or kind == "suburb_district" or map_mode == 2
		if map_mode == 0:
			if is_terminal:
				should_label = str(item.get("city", "")) in ["Cape Town", "Kimberley", "Gqeberha", "Bloemfontein", "Durban", "Johannesburg"]
			elif is_city:
				should_label = not terminal_at_city and name in ["Springbok", "Upington", "De Aar", "George", "Mossel Bay", "Knysna", "East London", "Mthatha", "Pietermaritzburg", "Richards Bay", "Newcastle", "Rustenburg", "Polokwane", "Mbombela"]
		if should_label:
			var label := str(item.get("map_label", item.get("name", "")))
			draw_string(font, p + Vector2(8, -4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10 if map_mode == 2 else 11, c_text)
		hit_places.append({"name": name, "position": p, "radius": 15.0 if is_terminal else 12.0, "item": item})


func _draw_map_legend(font: Font) -> void:
	var box := Rect2(map_rect.position.x + 12, map_rect.end.y - 70, 198, 60)
	draw_rect(box, c_legend, true)
	var legend_routes := ["N1", "N2", "N3", "N4"]
	for i in range(legend_routes.size()):
		var route_name: String = legend_routes[i]
		var y := box.position.y + 14 + float(i % 2) * 17
		var x := box.position.x + 10 + float(i / 2) * 92
		draw_line(Vector2(x, y), Vector2(x + 20, y), route_colors[route_name], 3.0, true)
		draw_string(font, Vector2(x + 25, y + 4), route_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)
	var y2 := box.position.y + 50
	draw_circle(Vector2(box.position.x + 18, y2 - 3), 3.5, c_city)
	draw_string(font, Vector2(box.position.x + 27, y2), "City", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)
	draw_rect(Rect2(box.position.x + 83, y2 - 7, 7, 7), c_orange, true)
	draw_string(font, Vector2(box.position.x + 96, y2), "Terminal", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)


func _draw_scale(font: Font) -> void:
	var content := map_rect.grow(-12.0)
	var west := world_bounds.x * world_cos
	var east := world_bounds.z * world_cos
	var world_w := maxf(0.001, east - west)
	var world_h := maxf(0.001, world_bounds.w - world_bounds.y)
	var pixels_per_degree := minf(content.size.x / world_w, content.size.y / world_h)
	var choices := [1000.0, 500.0, 200.0, 100.0, 50.0, 20.0, 10.0, 5.0, 2.0, 1.0]
	var distance_km := 1.0
	for candidate in choices:
		var bar_width := float(candidate) * pixels_per_degree / 111.32
		if bar_width <= 112.0 and bar_width >= 42.0:
			distance_km = float(candidate)
			break
	var width := distance_km * pixels_per_degree / 111.32
	var x := map_rect.end.x - width - 20.0
	var y := map_rect.end.y - 20.0
	draw_line(Vector2(x, y), Vector2(x + width, y), c_text, 2.0, true)
	draw_line(Vector2(x, y - 5.0), Vector2(x, y + 2.0), c_text, 2.0, true)
	draw_line(Vector2(x + width, y - 5.0), Vector2(x + width, y + 2.0), c_text, 2.0, true)
	draw_string(font, Vector2(x, y - 7.0), str(int(distance_km)) + " km", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)


func _draw_info(font: Font) -> void:
	var title := "South Africa • 9 provinces"
	if map_mode == 1:
		title = selected_province + " • Province view"
	elif map_mode == 2:
		title = selected_city + " • City routes"
	var detail := str(selected_item.get("info", selected_place))
	if startup_status != "":
		title = "" if GameSave.recovered_backup else "Offline company ready"
		detail = startup_status
	if selected_item.get("type", "") == "terminal":
		var terminal_city := str(selected_item.get("city", selected_place))
		if CompanyOperations.owned_terminals.has(terminal_city):
			detail = str(selected_item.get("info", selected_place)) + " • Owned by your company"
		elif terminal_city in ["Gqeberha", "Bloemfontein", "Johannesburg", "Durban"]:
			detail = str(selected_item.get("info", selected_place)) + " • Purchase in Operations to unlock line-haul jobs"
		else:
			detail = str(selected_item.get("info", selected_place)) + " • Not yet available in the terminal market"
	draw_string(font, Vector2(14, info_rect.position.y + 19), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c_cyan)
	draw_string(font, Vector2(14, info_rect.position.y + 38), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_info_detail)


func _draw_operations_info(font: Font) -> void:
	draw_string(font, Vector2(14, info_rect.position.y + 19), "COMPANY UPDATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c_cyan)
	draw_string(font, Vector2(14, info_rect.position.y + 38), CompanyOperations.message, HORIZONTAL_ALIGNMENT_LEFT, info_rect.size.x - 24.0, 10, c_info_detail)


func _draw_operations_screen(font: Font) -> void:
	operation_buttons.clear()
	draw_rect(map_rect, c_bg, true)
	draw_string(font, Vector2(20, map_rect.position.y + 28), "CASH  R%s" % CompanyOperations.commas(CompanyOperations.cash), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, c_cyan)
	draw_string(font, Vector2(20, map_rect.position.y + 48), CompanyOperations.fleet_summary(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_text)
	var gap := 16.0
	var card_y := map_rect.position.y + 64.0
	var card_h := maxf(170.0, map_rect.size.y - 78.0)
	var card_w := (map_rect.size.x - 48.0 - gap) * 0.5
	var left := Rect2(16.0, card_y, card_w, card_h)
	var right := Rect2(left.end.x + gap, card_y, card_w, card_h)
	draw_rect(left, c_info_bg, true)
	draw_rect(left, c_divider, false, 1.0)
	draw_rect(right, c_info_bg, true)
	draw_rect(right, c_divider, false, 1.0)
	draw_string(font, left.position + Vector2(16, 24), "FLEET & DRIVERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c_cyan)
	draw_string(font, left.position + Vector2(16, 52), CompanyOperations.vehicle_label(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 11, c_text)
	_draw_operation_button("cycle_vehicle", "SELECT VEHICLE", Rect2(left.position.x + 12.0, left.position.y + 62.0, card_w - 24.0, 32.0), font)
	_draw_operation_button("buy_vehicle", "BUY: " + CompanyOperations.next_vehicle_label(), Rect2(left.position.x + 12.0, left.position.y + 100.0, card_w - 24.0, 38.0), font)
	draw_string(font, left.position + Vector2(16, 165), CompanyOperations.driver_label(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 11, c_text)
	_draw_operation_button("cycle_driver", "SELECT DRIVER", Rect2(left.position.x + 12.0, left.position.y + 175.0, card_w - 24.0, 32.0), font)
	_draw_operation_button("hire_driver", "HIRE: " + CompanyOperations.next_driver_label(), Rect2(left.position.x + 12.0, left.position.y + 213.0, card_w - 24.0, 38.0), font)
	draw_string(font, left.position + Vector2(16, 275), "Driver wages are charged once per game day.", HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 9, c_muted)
	draw_string(font, left.position + Vector2(16, 305), "TERMINAL NETWORK • %d / 5 OWNED" % CompanyOperations.owned_terminals.size(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 10, c_cyan)
	_draw_operation_button("cycle_terminal", "NEXT TERMINAL: " + CompanyOperations.next_terminal_label(), Rect2(left.position.x + 12.0, left.position.y + 314.0, card_w - 24.0, 32.0), font)
	_draw_operation_button("buy_terminal", "BUY SELECTED TERMINAL", Rect2(left.position.x + 12.0, left.position.y + 352.0, card_w - 24.0, 36.0), font)

	var tab_w := (card_w - 36.0) / 3.0
	_draw_operation_button("tab_local", "LOCAL", Rect2(right.position.x + 12.0, right.position.y + 10.0, tab_w, 30.0), font)
	_draw_operation_button("tab_contracts", "CONTRACTS", Rect2(right.position.x + 18.0 + tab_w, right.position.y + 10.0, tab_w, 30.0), font)
	_draw_operation_button("tab_network", "NETWORK", Rect2(right.position.x + 24.0 + tab_w * 2.0, right.position.y + 10.0, tab_w, 30.0), font)
	if operations_tab == 0:
		draw_string(font, right.position + Vector2(16, 62), "CAPE TOWN LOCAL JOB MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c_cyan)
		draw_string(font, right.position + Vector2(16, 90), CompanyOperations.job_label(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 11, c_text)
		draw_string(font, right.position + Vector2(16, 117), "One-way distance; vehicle returns to Cape Town.", HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 9, c_muted)
		_draw_operation_button("next_job", "NEXT LOCAL JOB", Rect2(right.position.x + 12.0, right.position.y + 130.0, card_w - 24.0, 34.0), font)
		_draw_operation_button("dispatch", "DISPATCH SELECTED JOB", Rect2(right.position.x + 12.0, right.position.y + 171.0, card_w - 24.0, 42.0), font)
		draw_string(font, right.position + Vector2(16, 245), "ACTIVE DELIVERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c_cyan)
		draw_string(font, right.position + Vector2(16, 267), CompanyOperations.trip_summary(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 10, c_text)
	elif operations_tab == 1:
		draw_string(font, right.position + Vector2(16, 62), "SOUTH AFRICA LONG-HAUL BOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c_cyan)
		draw_string(font, right.position + Vector2(16, 92), CompanyOperations.contract_label(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 11, c_text)
		draw_string(font, right.position + Vector2(16, 135), CompanyOperations.contract_deadline_label(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 10, c_muted)
		_draw_operation_button("next_contract", "CONTRACT RESERVED" if CompanyOperations.accepted_contract_id != "" else "NEXT CONTRACT OFFER", Rect2(right.position.x + 12.0, right.position.y + 153.0, card_w - 24.0, 36.0), font)
		_draw_operation_button("contract_action", CompanyOperations.contract_action_label(), Rect2(right.position.x + 12.0, right.position.y + 196.0, card_w - 24.0, 42.0), font)
		draw_string(font, right.position + Vector2(16, 264), "Eligible rigid or refrigerated trucks only. Late returns pay 75%; the bond is forfeited.", HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 9, c_muted)
	else:
		draw_string(font, right.position + Vector2(16, 62), "OWNED TERMINAL LINE-HAULS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c_cyan)
		draw_string(font, right.position + Vector2(16, 92), CompanyOperations.network_job_label(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 11, c_text)
		draw_string(font, right.position + Vector2(16, 137), "Jobs run from Cape Town to an owned terminal and return.", HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 9, c_muted)
		_draw_operation_button("next_network_job", "NEXT LINE-HAUL JOB", Rect2(right.position.x + 12.0, right.position.y + 153.0, card_w - 24.0, 36.0), font)
		_draw_operation_button("dispatch_network", "DISPATCH LINE-HAUL", Rect2(right.position.x + 12.0, right.position.y + 196.0, card_w - 24.0, 42.0), font)
		draw_string(font, right.position + Vector2(16, 264), "Terminal purchase unlocks daily freight demand at that destination.", HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 9, c_muted)
	draw_string(font, right.position + Vector2(16, card_h - 18.0), CompanyOperations.trip_summary(), HORIZONTAL_ALIGNMENT_LEFT, card_w - 32.0, 10, c_text)


func _draw_operation_button(button_id: String, label: String, rect: Rect2, font: Font) -> void:
	operation_buttons.append({"id": button_id, "rect": rect})
	draw_rect(rect, c_button, true)
	draw_rect(rect, c_button_border, false, 1.5)
	draw_string(font, rect.position + Vector2(6, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 10, c_button_text)


func _draw_view_buttons(font: Font) -> void:
	view_buttons.clear()
	var labels := ["COUNTRY", "PROVINCE", "CITY / TOWN", "OPERATIONS"] if screen_mode == 0 else ["BACK TO MAP"]
	var button_w := 126.0 if screen_mode == 0 else 176.0
	var gap := 10.0
	var total := button_w * float(labels.size()) + gap * float(maxi(0, labels.size() - 1))
	var start_x := maxf(8.0, (controls_rect.size.x - total) * 0.5)
	for i in range(labels.size()):
		var rect := Rect2(start_x + float(i) * (button_w + gap), controls_rect.position.y + 2.0, button_w, 32.0)
		var active := (screen_mode == 0 and i == map_mode) or screen_mode == 1
		draw_rect(rect, c_divider if not active else c_orange, true)
		draw_rect(rect, c_gold, false, 1.0)
		draw_string(font, rect.position + Vector2(0, 21), labels[i], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 10, c_text)
		view_buttons.append(rect)


func _set_selected_city(item: Dictionary) -> void:
	selected_item = item
	selected_place = str(item.get("name", "Place"))
	selected_city = str(item.get("city", selected_place))
	selected_province = str(item.get("province", selected_province))
	var focus_found := false
	for place in settlements:
		if str(place.get("name", "")) == selected_city:
			city_focus_lat = float(place.get("lat", city_focus_lat))
			city_focus_lon = float(place.get("lon", city_focus_lon))
			focus_found = true
			break
	if not focus_found:
		city_focus_lat = float(item.get("lat", city_focus_lat))
		city_focus_lon = float(item.get("lon", city_focus_lon))
	map_mode = 2


func _feature_at_position(position: Vector2) -> Dictionary:
	for feature in provinces:
		var props: Dictionary = feature.get("properties", {})
		var province_name := str(props.get("name", ""))
		var polygons := _geometry_polygons(feature.get("geometry", {}))
		for polygon in polygons:
			if polygon.is_empty():
				continue
			var points := PackedVector2Array()
			for coord in polygon[0]:
				points.append(_map_point(float(coord[0]), float(coord[1])))
			if points.size() >= 3 and Geometry2D.is_point_in_polygon(position, points):
				return {"name": province_name, "properties": props}
	return {}


func _handle_operation_action(action: String) -> void:
	match action:
		"buy_vehicle":
			CompanyOperations.buy_vehicle()
		"hire_driver":
			CompanyOperations.hire_driver()
		"cycle_vehicle":
			CompanyOperations.cycle_vehicle()
		"cycle_driver":
			CompanyOperations.cycle_driver()
		"next_job":
			CompanyOperations.cycle_job()
		"dispatch":
			CompanyOperations.dispatch(SimulationClock.game_time_seconds)
		"next_contract":
			CompanyOperations.cycle_contract()
		"contract_action":
			if CompanyOperations.accepted_contract_id == "":
				CompanyOperations.bid_contract()
			else:
				CompanyOperations.dispatch_contract(SimulationClock.game_time_seconds)
		"buy_terminal":
			CompanyOperations.buy_terminal()
		"cycle_terminal":
			CompanyOperations.cycle_terminal_offer()
		"next_network_job":
			CompanyOperations.cycle_network_job()
		"dispatch_network":
			CompanyOperations.dispatch_network(SimulationClock.game_time_seconds)
		"tab_local":
			operations_tab = 0
		"tab_contracts":
			operations_tab = 1
		"tab_network":
			operations_tab = 2


func _handle_tap(position: Vector2) -> void:
	if clock_button_rect.has_point(position):
		SimulationClock.cycle_speed()
		startup_status = ""
		_save_progress()
		queue_redraw()
		accept_event()
		return
	if theme_button_rect.has_point(position):
		theme_mode = 1 - theme_mode
		_apply_theme()
		startup_status = ""
		_save_progress()
		queue_redraw()
		accept_event()
		return
	if screen_mode == 1:
		for button in operation_buttons:
			if button["rect"].has_point(position):
				_handle_operation_action(str(button["id"]))
				_save_progress()
				queue_redraw()
				accept_event()
				return

	for i in range(view_buttons.size()):
		if view_buttons[i].has_point(position):
			startup_status = ""
			if screen_mode == 1:
				screen_mode = 0
			elif i == 3:
				screen_mode = 1
			elif i == 0:
				map_mode = 0
				selected_place = "South Africa"
				selected_item = {"name": selected_place, "type": "Map view"}
			elif i == 1:
				map_mode = 1
				selected_place = selected_province
				selected_item = {"name": selected_province, "type": "Province", "province": selected_province}
			else:
				map_mode = 2
				selected_place = selected_city
				selected_item = {"name": selected_city, "type": "City", "province": selected_province}
			_save_progress()
			queue_redraw()
			accept_event()
			return
	if screen_mode == 1:
		return

	if not map_rect.has_point(position):
		return

	for i in range(hit_places.size() - 1, -1, -1):
		var entry: Dictionary = hit_places[i]
		if position.distance_to(entry["position"]) > entry["radius"]:
			continue
		var item: Dictionary = entry["item"]
		startup_status = ""
		var kind := str(item.get("type", "municipality"))
		if kind in ["terminal", "city", "town", "suburb_district"]:
			_set_selected_city(item)
		else:
			selected_item = item
			selected_place = str(item.get("name", "Place"))
			if map_mode != 2:
				var province := str(item.get("province", ""))
				if province != "":
					selected_province = province
					map_mode = 1
		queue_redraw()
		accept_event()
		return

	if map_mode == 0:
		var feature := _feature_at_position(position)
		if not feature.is_empty():
			startup_status = ""
			selected_province = str(feature.get("name", selected_province))
			selected_place = selected_province
			selected_item = {"name": selected_province, "type": "Province", "province": selected_province}
			map_mode = 1
			queue_redraw()
			accept_event()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
