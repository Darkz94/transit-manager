extends Control

const UI_TEXT_SCALE := 1.3

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
var c_secondary_road := Color("#52798A")
var c_marker_outline := Color("#FFFFFF")
var c_terminal_outline := Color("#FFFFFF")
var c_owned_terminal := Color("#16A34A")
var c_button := Color("#FFFFFF")
var c_button_text := Color("#0B3A5A")
var c_button_border := Color("#FF7A00")
var c_surface_raised := Color("#FFFFFF")
var c_panel_stroke := Color("#C6D6E2")
var c_positive := Color("#54D6A0")
var c_shadow := Color(0.015, 0.04, 0.075, 0.32)
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
var operations_section := 3 # overview, fleet, drivers, dispatch, depots, workshop
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
var map_control_buttons: Array[Dictionary] = []
var map_zoom_factor := 1.0
var map_center := Vector2.ZERO
var map_center_custom := false
var show_map_routes := true
var show_map_places := true
var show_map_terminals := true
var touch_positions: Dictionary = {}
var touch_start_position := Vector2.ZERO
var touch_last_center := Vector2.ZERO
var touch_last_distance := 0.0
var touch_moved := false
var touch_multitouch := false
var mouse_map_dragging := false
var mouse_drag_start := Vector2.ZERO
var mouse_last_position := Vector2.ZERO
var mouse_drag_moved := false


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
		operations_section = clampi(int(saved_state.get("operations_section", operations_section)), 0, 5)
		city_focus_lat = float(saved_state.get("city_focus_lat", city_focus_lat))
		city_focus_lon = float(saved_state.get("city_focus_lon", city_focus_lon))
		map_zoom_factor = clampf(float(saved_state.get("map_zoom_factor", 1.0)), 1.0, 10.0)
		map_center = Vector2(float(saved_state.get("map_center_lon", 0.0)), float(saved_state.get("map_center_lat", 0.0)))
		map_center_custom = bool(saved_state.get("map_center_custom", false))
		show_map_routes = bool(saved_state.get("show_map_routes", true))
		show_map_places = bool(saved_state.get("show_map_places", true))
		show_map_terminals = bool(saved_state.get("show_map_terminals", true))
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
	suburbs = _read_json("res://data/stage1_metro_districts.json")
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
		"map_zoom_factor": map_zoom_factor,
		"map_center_lon": map_center.x,
		"map_center_lat": map_center.y,
		"map_center_custom": map_center_custom,
		"show_map_routes": show_map_routes,
		"show_map_places": show_map_places,
		"show_map_terminals": show_map_terminals,
		"screen_mode": screen_mode,
		"operations_section": operations_section,
		"operations": CompanyOperations.snapshot()
	}
	GameSave.save_game(state)


func _apply_theme() -> void:
	if theme_mode == 0:
		c_header_title = Color("#FFFFFF")
		c_header_subtitle = Color("#BEE6FF")
		c_province_border = Color("#F7F4E9")
		c_info_bg = Color("#F6F8FA")
		c_info_detail = Color("#42596D")
		c_footer_text = Color("#BEE6FF")
		c_bg = Color("#E5EDF2")
		c_map = Color("#9ECFE2")
		c_topbar = Color("#10243A")
		c_country = Color("#E6DFC2")
		c_cyan = Color("#137F9D")
		c_city = Color("#173B57")
		c_text = Color("#183148")
		c_muted = Color("#687F90")
		c_gold = Color("#BD741B")
		c_orange = Color("#F27A32")
		c_divider = Color("#CBD8E1")
		c_route_shadow = Color("#6F9CAE")
		c_secondary_road = Color("#A56B3F")
		c_marker_outline = Color("#FFFFFF")
		c_terminal_outline = Color("#FFF6E8")
		c_owned_terminal = Color("#168A64")
		c_button = Color("#EAF0F4")
		c_button_text = Color("#183148")
		c_button_border = Color("#C7D5DE")
		c_surface_raised = Color("#FFFFFF")
		c_panel_stroke = Color("#D6E0E7")
		c_positive = Color("#168A64")
		c_shadow = Color(0.10, 0.18, 0.25, 0.16)
		c_legend = Color(0.97, 0.99, 1.0, 0.96)
		route_colors = {"N1": Color("#E53935"), "N2": Color("#B77900"), "N3": Color("#E65100"), "N4": Color("#2D8DFF")}
	else:
		c_header_title = Color("#FFFFFF")
		c_header_subtitle = Color("#94A3B8")
		c_province_border = Color("#2DD4FF")
		c_info_bg = Color("#101E30")
		c_info_detail = Color("#CDD9E5")
		c_footer_text = Color("#94A3B8")
		c_bg = Color("#080F1C")
		c_map = Color("#0B1C2D")
		c_topbar = Color("#101E30")
		c_country = Color("#263D4A")
		c_cyan = Color("#53D9F2")
		c_city = Color("#D6F6FB")
		c_text = Color("#E8F0F8")
		c_muted = Color("#96A9BB")
		c_gold = Color("#F6C867")
		c_orange = Color("#F58A42")
		c_divider = Color("#263A50")
		c_route_shadow = Color("#0A1725")
		c_secondary_road = Color("#5B8EAA")
		c_marker_outline = Color("#FFFFFF")
		c_terminal_outline = Color("#FFE2A1")
		c_owned_terminal = Color("#4AD5A1")
		c_button = Color("#1A2B40")
		c_button_text = Color("#E8F0F8")
		c_button_border = Color("#344A61")
		c_surface_raised = Color("#17283C")
		c_panel_stroke = Color("#2A4058")
		c_positive = Color("#55D5A4")
		c_shadow = Color(0.0, 0.0, 0.0, 0.35)
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

	var header_h := 78.0
	var controls_h := 90.0 if screen_mode == 0 else 78.0
	var info_h := 80.0 if screen_mode == 0 else 56.0
	draw_rect(Rect2(0, 0, w, header_h), c_topbar, true)
	draw_rect(Rect2(0, header_h - 2.0, w, 2.0), c_orange, true)
	var brand_mark := Rect2(12.0, 8.0, 48.0, 60.0)
	var brand_style := StyleBoxFlat.new()
	brand_style.bg_color = c_orange
	brand_style.set_corner_radius_all(9)
	brand_style.draw(get_canvas_item(), brand_mark)
	_draw_text(font, brand_mark.position + Vector2(0, 37), "TM", HORIZONTAL_ALIGNMENT_CENTER, brand_mark.size.x, 16, Color.WHITE)
	_draw_text(font, Vector2(67, 23), SimulationClock.clock_label(), HORIZONTAL_ALIGNMENT_LEFT, 150, 11, c_header_title)
	clock_button_rect = Rect2(64.0, 37.0, 142.0, 34.0)
	_draw_ui_card(clock_button_rect, c_button, c_panel_stroke, 7)
	_draw_text(font, clock_button_rect.position + Vector2(0, 23), SimulationClock.speed_label(), HORIZONTAL_ALIGNMENT_CENTER, clock_button_rect.size.x, 10, c_button_text)
	var header_context := "NATIONAL NETWORK  •  9 PROVINCES"
	if map_mode == 1:
		header_context = "PROVINCE MAP  •  " + selected_province.to_upper()
	elif map_mode == 2:
		header_context = "CITY MAP  •  " + selected_city.to_upper()
	if screen_mode == 1:
		header_context = "OPERATIONS DESK  •  " + _operations_section_title().to_upper()
	var header_identity_x := 232.0
	var header_stats_x := w - 540.0
	var header_identity_width := maxf(185.0, header_stats_x - header_identity_x - 18.0)
	_draw_text(font, Vector2(header_identity_x, 31), company_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, header_identity_width, 16, c_header_title)
	_draw_text(font, Vector2(header_identity_x, 56), header_context, HORIZONTAL_ALIGNMENT_LEFT, header_identity_width, 9, c_header_subtitle)
	_draw_hud_stat(font, Rect2(w - 540.0, 10.0, 92.0, 56.0), "TRUCKS", str(CompanyOperations.fleet.size()), c_cyan)
	var active_runs := active_count_on_road()
	_draw_hud_stat(font, Rect2(w - 440.0, 10.0, 98.0, 56.0), "ON ROAD", str(active_runs), c_positive if active_runs > 0 else c_muted)
	theme_button_rect = Rect2(w - 210.0, 0.0, 210.0, 70.0)
	var theme_visual_rect := Rect2(w - 142.0, 10.0, 130.0, 56.0)
	_draw_ui_card(theme_visual_rect, c_button, c_panel_stroke, 8)
	_draw_text(font, theme_visual_rect.position + Vector2(0, 35), "NIGHT MODE" if theme_mode == 0 else "DAY MODE", HORIZONTAL_ALIGNMENT_CENTER, theme_visual_rect.size.x, 10, c_button_text)
	var cash_badge := Rect2(w - 322.0, 10.0, 166.0, 56.0)
	_draw_ui_card(cash_badge, c_surface_raised, c_panel_stroke, 8)
	_draw_text(font, cash_badge.position + Vector2(11, 18), "COMPANY CASH", HORIZONTAL_ALIGNMENT_LEFT, cash_badge.size.x - 22.0, 8, c_muted)
	_draw_text(font, cash_badge.position + Vector2(11, 42), "R%s" % CompanyOperations.commas(CompanyOperations.cash), HORIZONTAL_ALIGNMENT_LEFT, cash_badge.size.x - 22.0, 15, c_cyan)

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
		_draw_map_controls(font)
		_draw_map_activity_panel(font)
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
		_draw_text(font, Vector2(8, h - 4), "Made with Natural Earth • Open Admin Data (CC BY 4.0) • Map routes are illustrative", HORIZONTAL_ALIGNMENT_LEFT, w - 16, 8, c_muted)


func _set_bounds() -> void:
	var base_bounds := _default_map_bounds()
	var center := Vector2((base_bounds.x + base_bounds.z) * 0.5, (base_bounds.y + base_bounds.w) * 0.5)
	if map_center_custom:
		center = map_center
	var width := (base_bounds.z - base_bounds.x) / map_zoom_factor
	var height := (base_bounds.w - base_bounds.y) / map_zoom_factor
	world_bounds = Vector4(center.x - width * 0.5, center.y - height * 0.5, center.x + width * 0.5, center.y + height * 0.5)
	world_cos = cos(deg_to_rad((world_bounds.y + world_bounds.w) * 0.5))
	if not map_center_custom:
		map_center = center


func _default_map_bounds() -> Vector4:
	if map_mode == 1:
		return _province_bounds(selected_province)
	elif map_mode == 2:
		var lat_radius := 0.30 if selected_city == "Cape Town" else 0.22
		var center_cos := maxf(0.5, cos(deg_to_rad(city_focus_lat)))
		var view_aspect := map_rect.size.x / maxf(1.0, map_rect.size.y)
		var lon_radius := lat_radius * view_aspect / center_cos
		return Vector4(city_focus_lon - lon_radius, city_focus_lat - lat_radius, city_focus_lon + lon_radius, city_focus_lat + lat_radius)
	return Vector4(15.8, -35.7, 33.2, -21.0)


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
			if not _polygon_in_sa_extent(polygon):
				continue
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


func _polygon_in_sa_extent(polygon: Array) -> bool:
	if polygon.is_empty() or polygon[0].is_empty():
		return false
	var ring: Array = polygon[0]
	var west := 180.0
	var east := -180.0
	var south := 90.0
	var north := -90.0
	for coord in ring:
		west = minf(west, float(coord[0]))
		east = maxf(east, float(coord[0]))
		south = minf(south, float(coord[1]))
		north = maxf(north, float(coord[1]))
	var center_lon := (west + east) * 0.5
	var center_lat := (south + north) * 0.5
	return center_lon >= 15.8 and center_lon <= 33.2 and center_lat >= -35.7 and center_lat <= -21.0


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


func _screen_to_geo(position: Vector2) -> Vector2:
	var west := world_bounds.x * world_cos
	var east := world_bounds.z * world_cos
	var north := world_bounds.w
	var content := map_rect.grow(-12.0)
	var world_w := maxf(0.001, east - west)
	var world_h := maxf(0.001, north - world_bounds.y)
	var scale := minf(content.size.x / world_w, content.size.y / world_h)
	var offset := Vector2(content.position.x + (content.size.x - world_w * scale) * 0.5, content.position.y + (content.size.y - world_h * scale) * 0.5)
	return Vector2((position.x - offset.x) / scale / maxf(0.001, world_cos) + world_bounds.x, north - (position.y - offset.y) / scale)


func _zoom_map(factor: float, anchor: Vector2) -> void:
	if screen_mode != 0 or not map_rect.has_point(anchor):
		return
	_set_bounds()
	var new_zoom := clampf(map_zoom_factor * factor, 1.0, 10.0)
	if is_equal_approx(new_zoom, map_zoom_factor):
		return
	var anchor_geo := _screen_to_geo(anchor)
	var fraction_x := clampf((anchor_geo.x - world_bounds.x) / maxf(0.001, world_bounds.z - world_bounds.x), 0.0, 1.0)
	var fraction_y := clampf((world_bounds.w - anchor_geo.y) / maxf(0.001, world_bounds.w - world_bounds.y), 0.0, 1.0)
	map_zoom_factor = new_zoom
	var base := _default_map_bounds()
	var new_width := (base.z - base.x) / map_zoom_factor
	var new_height := (base.w - base.y) / map_zoom_factor
	map_center = Vector2(anchor_geo.x + (0.5 - fraction_x) * new_width, anchor_geo.y + (fraction_y - 0.5) * new_height)
	map_center_custom = true
	_clamp_map_center()
	queue_redraw()


func _pan_map(screen_delta: Vector2) -> void:
	if screen_mode != 0 or screen_delta.length_squared() < 0.01:
		return
	_set_bounds()
	var content := map_rect.grow(-12.0)
	var projected_w := maxf(0.001, (world_bounds.z - world_bounds.x) * world_cos)
	var world_h := maxf(0.001, world_bounds.w - world_bounds.y)
	var scale := minf(content.size.x / projected_w, content.size.y / world_h)
	map_center.x -= screen_delta.x / (scale * maxf(0.001, world_cos))
	map_center.y += screen_delta.y / scale
	map_center_custom = true
	_clamp_map_center()
	queue_redraw()


func _clamp_map_center() -> void:
	var base := _default_map_bounds()
	var half_width := (base.z - base.x) / map_zoom_factor * 0.5
	var half_height := (base.w - base.y) / map_zoom_factor * 0.5
	var pad_x := (base.z - base.x) * 0.03
	var pad_y := (base.w - base.y) * 0.03
	map_center.x = clampf(map_center.x, base.x + half_width - pad_x, base.z - half_width + pad_x)
	map_center.y = clampf(map_center.y, base.y + half_height - pad_y, base.w - half_height + pad_y)


func _reset_map_view() -> void:
	map_zoom_factor = 1.0
	map_center_custom = false
	map_center = Vector2.ZERO


func _draw_map(font: Font) -> void:
	for feature in provinces:
		var props: Dictionary = feature.get("properties", {})
		var province_name := str(props.get("name", ""))
		if map_mode in [1, 2] and province_name != selected_province:
			continue
		var polygons: Array = _geometry_polygons(feature.get("geometry", {}))
		for polygon in polygons:
			if polygon.is_empty() or not _polygon_in_sa_extent(polygon):
				continue
			var geographic_points := PackedVector2Array()
			for coord in polygon[0]:
				geographic_points.append(Vector2(float(coord[0]), float(coord[1])))
			var shapes: Array[PackedVector2Array] = [geographic_points]
			if map_mode == 2:
				var bounds_clip := PackedVector2Array([
					Vector2(world_bounds.x, world_bounds.y),
					Vector2(world_bounds.z, world_bounds.y),
					Vector2(world_bounds.z, world_bounds.w),
					Vector2(world_bounds.x, world_bounds.w)
				])
				shapes = Geometry2D.clip_polygons(geographic_points, bounds_clip)
			for shape in shapes:
				if shape.size() < 3:
					continue
				var points := PackedVector2Array()
				for coordinate in shape:
					points.append(_map_point(coordinate.x, coordinate.y))
				draw_colored_polygon(points, c_country)
				draw_polyline(points, Color(0.02, 0.07, 0.11, 0.20), 4.0, true)
				draw_polyline(points, c_province_border, 1.5, true)
		if map_mode == 0:
			var label_pos := _map_point(float(props.get("label_lon", 0.0)), float(props.get("label_lat", 0.0)))
			var label_size := 10 if province_name in ["Gauteng", "Mpumalanga", "Free State"] else 12
			_draw_text(font, label_pos + Vector2(-35, 4), province_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 70, label_size, c_cyan)

	if map_mode == 0:
		_draw_neighbor_labels(font)
	if show_map_routes:
		_draw_corridors()
	if map_mode == 2 and show_map_routes:
		_draw_local_links()
	if map_mode == 0 and show_map_routes:
		_draw_active_trips()


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
		_draw_text(font, p, item["name"], HORIZONTAL_ALIGNMENT_CENTER, 90, 10, c_muted)
	_draw_text(font, _map_point(16.2, -33.2), "SOUTH ATLANTIC OCEAN", HORIZONTAL_ALIGNMENT_LEFT, 180, 11, c_cyan)
	_draw_text(font, _map_point(32.5, -33.5), "INDIAN OCEAN", HORIZONTAL_ALIGNMENT_LEFT, 130, 11, c_cyan)


func _draw_corridors() -> void:
	for corridor in corridors:
		var route_name := str(corridor.get("name", ""))
		var primary_route := route_colors.has(route_name)
		var route_color: Color = route_colors.get(route_name, c_secondary_road)
		var coords: Array = corridor.get("points", [])
		var city_label_drawn := false
		for i in range(coords.size() - 1):
			var a := _map_point(float(coords[i][0]), float(coords[i][1]))
			var b := _map_point(float(coords[i + 1][0]), float(coords[i + 1][1]))
			var clipped := _clip_line_to_rect(a, b, map_rect.grow(-2.0))
			if clipped.size() == 2:
				var route_width := (3.2 if primary_route else 2.2) if map_mode < 2 else (2.6 if primary_route else 1.8)
				draw_line(clipped[0], clipped[1], c_route_shadow, route_width + 3.0, true)
				draw_line(clipped[0], clipped[1], route_color, route_width, true)
				if map_mode == 2 and not city_label_drawn:
					var label_point: Vector2 = clipped[0].lerp(clipped[1], 0.5) + Vector2(5.0, -5.0)
					_draw_text(ThemeDB.fallback_font, label_point, route_name, HORIZONTAL_ALIGNMENT_LEFT, 28, 9, route_color)
					city_label_drawn = true
		if coords.size() > 2:
			var middle: Array = coords[coords.size() / 2]
			var mp := _map_point(float(middle[0]), float(middle[1]))
			if map_mode < 2 and map_rect.grow(-15).has_point(mp):
				_draw_text(ThemeDB.fallback_font, mp + Vector2(5, -5), route_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, route_color)


func _clip_line_to_rect(start: Vector2, finish: Vector2, rect: Rect2) -> Array[Vector2]:
	var delta := finish - start
	var lower := 0.0
	var upper := 1.0
	var p_values := [-delta.x, delta.x, -delta.y, delta.y]
	var q_values := [start.x - rect.position.x, rect.end.x - start.x, start.y - rect.position.y, rect.end.y - start.y]
	for i in range(4):
		var p := float(p_values[i])
		var q := float(q_values[i])
		if is_zero_approx(p):
			if q < 0.0:
				return []
			continue
		var ratio := q / p
		if p < 0.0:
			lower = maxf(lower, ratio)
		else:
			upper = minf(upper, ratio)
		if lower > upper:
			return []
	return [start + delta * lower, start + delta * upper]


func _draw_active_trips() -> void:
	for trip in CompanyOperations.trips:
		if str(trip.get("status", "")) != "in_transit":
			continue
		var route: Variant = trip.get("route_points", [])
		if not route is Array or route.size() < 2:
			continue
		var path := PackedVector2Array()
		for coordinate in route:
			path.append(_map_point(float(coordinate[0]), float(coordinate[1])))
		draw_polyline(path, c_route_shadow, 7.0, true)
		draw_polyline(path, c_cyan, 3.0, true)
		var trip_start := float(trip.get("start_time", SimulationClock.game_time_seconds))
		var trip_end := float(trip.get("arrival", trip_start))
		var total_time := maxf(1.0, trip_end - trip_start)
		var journey_progress := clampf((SimulationClock.game_time_seconds - trip_start) / total_time, 0.0, 1.0)
		var route_progress := journey_progress * 2.0 if journey_progress <= 0.5 else (1.0 - journey_progress) * 2.0
		var location := _point_on_route(route, route_progress)
		var marker := _map_point(location.x, location.y)
		draw_circle(marker, 12.0, Color(c_orange, 0.20))
		_draw_truck_illustration(Rect2(marker - Vector2(14, 6), Vector2(28, 12)), c_orange)


func _point_on_route(route: Array, progress: float) -> Vector2:
	var segment_lengths: Array[float] = []
	var total_length := 0.0
	for i in range(route.size() - 1):
		var a: Array = route[i]
		var b: Array = route[i + 1]
		var length := _map_haversine_km(float(a[0]), float(a[1]), float(b[0]), float(b[1]))
		segment_lengths.append(length)
		total_length += length
	if total_length <= 0.0:
		return Vector2(float(route[0][0]), float(route[0][1]))
	var target := total_length * clampf(progress, 0.0, 1.0)
	var traversed := 0.0
	for i in range(segment_lengths.size()):
		var length: float = segment_lengths[i]
		if traversed + length >= target or i == segment_lengths.size() - 1:
			var ratio := clampf((target - traversed) / maxf(0.001, length), 0.0, 1.0)
			var start: Array = route[i]
			var finish: Array = route[i + 1]
			return Vector2(lerpf(float(start[0]), float(finish[0]), ratio), lerpf(float(start[1]), float(finish[1]), ratio))
		traversed += length
	return Vector2(float(route[route.size() - 1][0]), float(route[route.size() - 1][1]))


func _map_haversine_km(lon_a: float, lat_a: float, lon_b: float, lat_b: float) -> float:
	var lat_delta := deg_to_rad(lat_b - lat_a)
	var lon_delta := deg_to_rad(lon_b - lon_a)
	var a := pow(sin(lat_delta * 0.5), 2.0) + cos(deg_to_rad(lat_a)) * cos(deg_to_rad(lat_b)) * pow(sin(lon_delta * 0.5), 2.0)
	return 6371.0 * 2.0 * atan2(sqrt(a), sqrt(maxf(0.0, 1.0 - a)))


func _draw_local_links() -> void:
	var center := _map_point(city_focus_lon, city_focus_lat)
	var local_places := _marker_data()
	var drew_link := false
	for item in local_places:
		if item.get("type", "") != "suburb_district" or str(item.get("city", "")) != selected_city:
			continue
		var p := _map_point(float(item.get("lon", 0.0)), float(item.get("lat", 0.0)))
		if map_rect.grow(-4).has_point(p):
			draw_line(center, p, c_route_shadow, 5.0, true)
			draw_line(center, p, c_orange, 2.0, true)
			drew_link = true
	if drew_link:
		_draw_text(ThemeDB.fallback_font, Vector2(map_rect.position.x + 14, map_rect.position.y + 20), "SAMPLE LOCAL LINKS • NOT STREET ROUTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_gold)


func _marker_data() -> Array:
	var result: Array = []
	if map_mode == 2:
		for item in settlements:
			var item_type := str(item.get("type", ""))
			if item_type == "suburb_district" and str(item.get("city", "")) == selected_city:
				result.append(item)
			elif str(item.get("name", "")) == selected_city:
				result.append(item)
		for item in suburbs:
			if str(item.get("city", "")) == selected_city:
				result.append(item)
		for item in terminals:
			if str(item.get("city", item.get("name", ""))) == selected_city:
				result.append(item)
		return result
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
	var label_candidates: Array[Dictionary] = []
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
		if (is_terminal and not show_map_terminals) or (not is_terminal and not show_map_places):
			continue
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
		elif map_mode == 2:
			should_label = is_terminal or kind == "suburb_district" or (is_city and name == selected_city and not terminal_at_city)
		if should_label:
			var label := str(item.get("map_label", item.get("name", "")))
			label_candidates.append({"item":item,"position":p,"label":label,"font_size":10 if map_mode == 2 else 11})
		hit_places.append({"name": name, "position": p, "radius": 15.0 if is_terminal else 12.0, "item": item})
	label_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _map_label_priority(a["item"]) > _map_label_priority(b["item"]))
	var occupied_labels: Array[Rect2] = []
	for candidate in label_candidates:
		_draw_map_label(font, candidate["position"], str(candidate["label"]), int(candidate["font_size"]), occupied_labels)


func _map_label_priority(item: Dictionary) -> int:
	var kind := str(item.get("type", ""))
	if kind == "terminal":
		return 4
	if kind == "suburb_district":
		return 3
	if str(item.get("name", "")) == selected_city:
		return 2
	return 1


func _draw_map_label(font: Font, point: Vector2, label: String, font_size: int, occupied: Array[Rect2]) -> void:
	var width := maxf(18.0, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, maxi(1, roundi(float(font_size) * UI_TEXT_SCALE))).x + 4.0)
	var scaled_size := maxi(1, roundi(float(font_size) * UI_TEXT_SCALE))
	var offsets := [Vector2(8, -4), Vector2(-width - 8, -4), Vector2(-width * 0.5, -12), Vector2(-width * 0.5, scaled_size + 10), Vector2(8, scaled_size + 7), Vector2(-width - 8, scaled_size + 7)]
	for offset in offsets:
		var baseline: Vector2 = point + offset
		var bounds := Rect2(baseline.x, baseline.y - scaled_size, width, scaled_size + 3.0)
		if not map_rect.grow(-3.0).encloses(bounds):
			continue
		var overlaps := false
		for existing in occupied:
			if existing.grow(2.0).intersects(bounds):
				overlaps = true
				break
		if overlaps:
			continue
		_draw_text(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, c_text)
		occupied.append(bounds)
		return


func _draw_map_legend(font: Font) -> void:
	var box := Rect2(map_rect.position.x + 12, map_rect.end.y - 94, 250, 84)
	_draw_ui_card(box, c_info_bg, c_panel_stroke, 9)
	var legend_routes := ["N1", "N2", "N3", "N4"]
	for i in range(legend_routes.size()):
		var route_name: String = legend_routes[i]
		var y := box.position.y + 17 + float(i / 3) * 18
		var x := box.position.x + 10 + float(i % 3) * 74
		draw_line(Vector2(x, y), Vector2(x + 20, y), route_colors[route_name], 3.0, true)
		_draw_text(font, Vector2(x + 25, y + 4), route_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)
	var secondary_y := box.position.y + 53
	draw_line(Vector2(box.position.x + 10, secondary_y), Vector2(box.position.x + 30, secondary_y), c_secondary_road, 2.2, true)
	_draw_text(font, Vector2(box.position.x + 35, secondary_y + 4), "Other national roads", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)
	var y2 := box.position.y + 74
	draw_circle(Vector2(box.position.x + 18, y2 - 3), 3.5, c_city)
	_draw_text(font, Vector2(box.position.x + 27, y2), "City / town", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)
	draw_rect(Rect2(box.position.x + 110, y2 - 7, 7, 7), c_orange, true)
	_draw_text(font, Vector2(box.position.x + 123, y2), "Terminal", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)


func _draw_map_controls(font: Font) -> void:
	map_control_buttons.clear()
	var panel := Rect2(map_rect.position + Vector2(14, 14), Vector2(178, 153))
	_draw_ui_card(panel, c_info_bg, c_panel_stroke, 10)
	_draw_text(font, panel.position + Vector2(11, 18), "MAP LAYERS", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 22, 10, c_cyan)
	var layer_defs := [
		{"id":"layer_routes","label":"ROUTES","active":show_map_routes},
		{"id":"layer_places","label":"CITIES & TOWNS","active":show_map_places},
		{"id":"layer_terminals","label":"TERMINALS","active":show_map_terminals}
	]
	for i in range(layer_defs.size()):
		# Give each layer row a phone-friendly hit area. The old 23 px rows
		# were noticeably smaller than the neighbouring zoom controls.
		var rect := Rect2(panel.position.x + 8, panel.position.y + 25 + float(i) * 40.0, panel.size.x - 16, 36)
		var active := bool(layer_defs[i]["active"])
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = c_button if active else c_bg
		row_style.border_color = c_orange if active else c_panel_stroke
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(7)
		row_style.draw(get_canvas_item(), rect)
		draw_circle(rect.position + Vector2(17, 18), 4.5, c_orange if active else c_muted)
		_draw_text(font, rect.position + Vector2(29, 22), str(layer_defs[i]["label"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 38, 10, c_text if active else c_muted)
		map_control_buttons.append({"id":layer_defs[i]["id"],"rect":rect})

	var zoom_x := map_rect.end.x - 58.0
	var plus_rect := Rect2(zoom_x, map_rect.position.y + 20.0, 44, 44)
	var minus_rect := Rect2(zoom_x, plus_rect.end.y + 7.0, 44, 44)
	var reset_rect := Rect2(zoom_x, minus_rect.end.y + 7.0, 44, 36)
	_draw_map_control_button(font, "zoom_in", "+", plus_rect, map_zoom_factor < 10.0)
	_draw_map_control_button(font, "zoom_out", "−", minus_rect, map_zoom_factor > 1.0)
	_draw_map_control_button(font, "zoom_reset", "%.1fx" % map_zoom_factor, reset_rect, true)


func _draw_map_activity_panel(font: Font) -> void:
	var panel := Rect2(map_rect.end.x - 304.0, map_rect.position.y + 14.0, 232.0, 100.0)
	_draw_ui_card(panel, c_info_bg, c_panel_stroke, 10)
	_draw_text(font, panel.position + Vector2(13, 20), "FLEET CONTROL", HORIZONTAL_ALIGNMENT_LEFT, 130, 10, c_cyan)
	var active := active_count_on_road()
	draw_circle(Vector2(panel.end.x - 16.0, panel.position.y + 16.0), 4.0, c_positive if active > 0 else c_muted)
	if active > 0:
		_draw_truck_illustration(Rect2(panel.position.x + 10.0, panel.position.y + 29.0, 58.0, 26.0), c_orange)
		_draw_text(font, panel.position + Vector2(76, 43), "%d TRUCK%s ON ROUTE" % [active, "" if active == 1 else "S"], HORIZONTAL_ALIGNMENT_LEFT, 145, 10, c_text)
		_draw_text(font, panel.position + Vector2(76, 59), CompanyOperations.trip_summary(), HORIZONTAL_ALIGNMENT_LEFT, 145, 8, c_muted)
	else:
		_draw_road_motif(Rect2(panel.position.x + 11.0, panel.position.y + 30.0, 59.0, 24.0))
		_draw_text(font, panel.position + Vector2(78, 45), "NO TRUCKS DISPATCHED", HORIZONTAL_ALIGNMENT_LEFT, 140, 9, c_text)
		_draw_text(font, panel.position + Vector2(78, 60), "%d trucks in your fleet" % CompanyOperations.fleet.size(), HORIZONTAL_ALIGNMENT_LEFT, 140, 8, c_muted)
	var action_rect := Rect2(panel.position.x + 10.0, panel.end.y - 38.0, panel.size.x - 20.0, 30.0)
	var action_style := StyleBoxFlat.new()
	action_style.bg_color = c_button
	action_style.border_color = c_panel_stroke
	action_style.set_border_width_all(1)
	action_style.set_corner_radius_all(6)
	action_style.draw(get_canvas_item(), action_rect)
	_draw_text(font, action_rect.position + Vector2(0, 20), "OPEN OPERATIONS  >", HORIZONTAL_ALIGNMENT_CENTER, action_rect.size.x, 8, c_button_text)
	map_control_buttons.append({"id":"open_operations","rect":action_rect})


func _draw_map_control_button(font: Font, button_id: String, label: String, rect: Rect2, enabled: bool) -> void:
	var fill := c_button if enabled else c_bg
	var text_color := c_text if enabled else c_muted
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = c_panel_stroke
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.draw(get_canvas_item(), rect)
	_draw_text(font, rect.position + Vector2(0, rect.size.y * 0.66), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 17 if label in ["+", "−"] else 10, text_color)
	map_control_buttons.append({"id":button_id,"rect":rect})


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
	_draw_text(font, Vector2(x, y - 7.0), str(int(distance_km)) + " km", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_text)


func _draw_info(font: Font) -> void:
	var title := "South Africa"
	var context := "NATIONAL MAP  •  9 PROVINCES"
	var detail := "Select a province, city, or town to explore."
	var item_type := str(selected_item.get("type", "Map view"))
	var province := str(selected_item.get("province", selected_province))
	if map_mode == 1:
		title = selected_province
		context = "PROVINCE VIEW  •  SOUTH AFRICA"
		detail = "Select a city or town to open its local map."
	elif map_mode == 2:
		title = str(selected_item.get("name", selected_city))
		if item_type == "suburb_district":
			context = "METRO DISTRICT  •  %s  •  %s" % [selected_city.to_upper(), province.to_upper()]
			detail = str(selected_item.get("info", "Metro district map anchor"))
		elif item_type == "terminal":
			context = "FREIGHT TERMINAL  •  %s" % province.to_upper()
			detail = str(selected_item.get("info", "Terminal map location"))
			var terminal_city := str(selected_item.get("city", selected_place))
			if CompanyOperations.owned_terminals.has(terminal_city):
				detail += "  •  OWNED BY YOUR COMPANY"
			elif terminal_city in ["Gqeberha", "Bloemfontein", "Johannesburg", "Durban"]:
				detail += "  •  PURCHASE IN OPERATIONS TO UNLOCK LINE-HAUL"
			else:
				detail += "  •  NOT YET AVAILABLE"
		elif item_type.to_lower() in ["town", "city"]:
			context = "%s  •  %s" % [item_type.to_upper(), province.to_upper()]
			detail = "Tap a metro district to zoom in." if item_type.to_lower() == "city" else "Town map view"
		else:
			context = "LOCAL MAP  •  %s" % province.to_upper()
			detail = str(selected_item.get("info", "Explore nearby places and routes."))
	if startup_status != "":
		title = "Offline company ready" if not GameSave.recovered_backup else "Save recovered"
		context = "LOCAL GAME  •  SAVED ON THIS DEVICE"
		detail = startup_status

	var center := Vector2(34.0, info_rect.position.y + info_rect.size.y * 0.5)
	draw_circle(center, 19.0, Color(c_orange, 0.16))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-6.0, 2.0), center + Vector2(6.0, 2.0), center + Vector2(0.0, 15.0)]), c_orange)
	draw_circle(center + Vector2(0.0, -3.0), 7.5, c_orange)
	draw_circle(center + Vector2(0.0, -3.0), 2.5, Color.WHITE)
	var details_x := clampf(size.x * 0.48, 390.0, size.x - 220.0)
	_draw_text(font, Vector2(69, info_rect.position.y + 33), title, HORIZONTAL_ALIGNMENT_LEFT, details_x - 84.0, 18, c_text)
	_draw_text(font, Vector2(70, info_rect.position.y + 58), context, HORIZONTAL_ALIGNMENT_LEFT, details_x - 84.0, 9, c_cyan)
	draw_line(Vector2(details_x - 20.0, info_rect.position.y + 14.0), Vector2(details_x - 20.0, info_rect.end.y - 14.0), c_divider, 1.0, true)
	_draw_text(font, Vector2(details_x, info_rect.position.y + 46), detail.left(88), HORIZONTAL_ALIGNMENT_LEFT, size.x - details_x - 20.0, 10, c_info_detail)


func _draw_operations_info(font: Font) -> void:
	var banner := Rect2(10.0, info_rect.position.y + 6.0, info_rect.size.x - 20.0, info_rect.size.y - 12.0)
	_draw_ui_card(banner, c_surface_raised, c_panel_stroke, 9)
	_draw_rect(Rect2(banner.position.x, banner.position.y + 8.0, 4.0, banner.size.y - 16.0), c_orange, true)
	draw_circle(Vector2(banner.position.x + 22.0, banner.position.y + banner.size.y * 0.5), 13.0, Color(c_orange, 0.16))
	draw_circle(Vector2(banner.position.x + 22.0, banner.position.y + banner.size.y * 0.5), 5.0, c_orange)
	_draw_text(font, Vector2(banner.position.x + 44.0, banner.position.y + 19.0), "LATEST COMPANY UPDATE", HORIZONTAL_ALIGNMENT_LEFT, banner.size.x - 58.0, 9, c_cyan)
	_draw_text(font, Vector2(banner.position.x + 44.0, banner.position.y + 42.0), CompanyOperations.message, HORIZONTAL_ALIGNMENT_LEFT, banner.size.x - 58.0, 12, c_info_detail)


func _draw_operations_screen(font: Font) -> void:
	operation_buttons.clear()
	draw_rect(map_rect, c_bg, true)
	var fleet_count := CompanyOperations.fleet.size()
	var driver_count := CompanyOperations.drivers.size()
	var active_count := 0
	var available_count := 0
	for vehicle in CompanyOperations.fleet:
		if str(vehicle.get("status", "")) == "available":
			available_count += 1
	for trip in CompanyOperations.trips:
		if str(trip.get("status", "")) == "in_transit":
			active_count += 1
	var stat_gap := 10.0
	var stat_width := (map_rect.size.x - 32.0 - stat_gap * 3.0) / 4.0
	var stats := [
		["COMPANY BALANCE", "R%s" % CompanyOperations.commas(CompanyOperations.cash), "OFFLINE COMPANY"],
		["FLEET", "%d TRUCKS" % fleet_count, "%d AVAILABLE" % available_count],
		["DRIVERS", "%d HIRED" % driver_count, "LOCAL CREW"],
		["ACTIVE RUNS", "%d ON ROAD" % active_count, "LIVE DISPATCH"]
	]
	for i in range(stats.size()):
		var stat_rect := Rect2(16.0 + float(i) * (stat_width + stat_gap), map_rect.position.y + 9.0, stat_width, 55.0)
		_draw_stat_card(stat_rect, str(stats[i][0]), str(stats[i][1]), str(stats[i][2]), font, i == 0)
	var section_names := ["OVERVIEW", "FLEET", "DRIVERS", "DISPATCH", "DEPOTS", "WORKSHOP"]
	var section_gap := 6.0
	var section_width := (map_rect.size.x - 32.0 - section_gap * float(section_names.size() - 1)) / float(section_names.size())
	for i in range(section_names.size()):
		var section_rect := Rect2(16.0 + float(i) * (section_width + section_gap), map_rect.position.y + 66.0, section_width, 42.0)
		_draw_operation_button("ops_section_%d" % i, section_names[i], section_rect, font)
	var panel_y := map_rect.position.y + 116.0
	var panel := Rect2(16.0, panel_y, map_rect.size.x - 32.0, maxf(180.0, map_rect.end.y - panel_y - 10.0))
	_draw_ui_card(panel, c_info_bg, c_panel_stroke, 12)
	_draw_rect(Rect2(panel.position.x + 1.0, panel.position.y + 1.0, panel.size.x - 2.0, 3.0), c_orange if operations_section == 3 else c_cyan, true)
	_draw_operations_section(panel, font)


func _draw_operations_section(panel: Rect2, font: Font) -> void:
	match operations_section:
		0:
			_draw_overview_section(panel, font)
		1:
			_draw_fleet_section(panel, font)
		2:
			_draw_drivers_section(panel, font)
		3:
			_draw_dispatch_panel(panel, font)
		4:
			_draw_depots_section(panel, font)
		5:
			_draw_workshop_section(panel, font)


func _draw_overview_section(panel: Rect2, font: Font) -> void:
	_draw_text(font, panel.position + Vector2(18, 27), "COMPANY OVERVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c_text)
	_draw_text(font, panel.position + Vector2(18, 45), "Your fleet, crew, and freight at a glance", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 10, c_muted)
	var gap := 12.0
	var y := panel.position.y + 58.0
	var height := panel.size.y - 72.0
	var width := (panel.size.x - 28.0 - gap * 2.0) / 3.0
	var fleet_card := Rect2(panel.position.x + 14.0, y, width, height)
	var driver_card := Rect2(fleet_card.end.x + gap, y, width, height)
	var dispatch_card := Rect2(driver_card.end.x + gap, y, width, height)
	for card in [fleet_card, driver_card, dispatch_card]:
		_draw_ui_card(card, c_surface_raised, c_panel_stroke, 10)
	_draw_text(font, fleet_card.position + Vector2(14, 23), "YOUR FLEET", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	var truck_class := CompanyOperations.next_vehicle_class()
	var fleet_name := CompanyOperations.next_vehicle_label()
	var fleet_status := "Your company is ready for its first van."
	if not CompanyOperations.fleet.is_empty():
		var selected_vehicle: Dictionary = CompanyOperations.fleet[posmod(CompanyOperations.selected_vehicle, CompanyOperations.fleet.size())]
		truck_class = str(selected_vehicle.get("class", "rigid"))
		fleet_name = str(selected_vehicle.get("name", "Company truck"))
		fleet_status = "%d vehicles • %s" % [CompanyOperations.fleet.size(), str(selected_vehicle.get("status", "available")).capitalize()]
	_draw_truck_illustration(Rect2(fleet_card.position.x + 16.0, fleet_card.position.y + 43.0, 150.0, 58.0), c_orange, truck_class)
	_draw_text(font, fleet_card.position + Vector2(16, 126), fleet_name, HORIZONTAL_ALIGNMENT_LEFT, fleet_card.size.x - 32.0, 12, c_text)
	_draw_text(font, fleet_card.position + Vector2(16, 145), fleet_status, HORIZONTAL_ALIGNMENT_LEFT, fleet_card.size.x - 32.0, 9, c_muted)
	_draw_operation_button("ops_section_1", "OPEN GARAGE", Rect2(fleet_card.position.x + 12.0, fleet_card.end.y - 50.0, fleet_card.size.x - 24.0, 42.0), font)
	_draw_text(font, driver_card.position + Vector2(14, 23), "DRIVER CREW", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	var driver_copy := "Hire your first driver to put a truck to work."
	if not CompanyOperations.drivers.is_empty():
		driver_copy = CompanyOperations.driver_label()
	draw_circle(driver_card.position + Vector2(44, 76), 26.0, Color(c_cyan, 0.18))
	_draw_text(font, driver_card.position + Vector2(29, 83), "DR", HORIZONTAL_ALIGNMENT_LEFT, 33, 14, c_cyan)
	_draw_text(font, driver_card.position + Vector2(84, 70), "%d HIRED" % CompanyOperations.drivers.size(), HORIZONTAL_ALIGNMENT_LEFT, driver_card.size.x - 100.0, 13, c_text)
	_draw_text(font, driver_card.position + Vector2(84, 90), "General and specialist", HORIZONTAL_ALIGNMENT_LEFT, driver_card.size.x - 100.0, 9, c_muted)
	_draw_text(font, driver_card.position + Vector2(16, 132), driver_copy, HORIZONTAL_ALIGNMENT_LEFT, driver_card.size.x - 32.0, 9, c_muted)
	_draw_operation_button("ops_section_2", "MANAGE DRIVERS", Rect2(driver_card.position.x + 12.0, driver_card.end.y - 50.0, driver_card.size.x - 24.0, 42.0), font)
	_draw_text(font, dispatch_card.position + Vector2(14, 23), "DISPATCH BOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	_draw_text(font, dispatch_card.position + Vector2(16, 59), "LOCAL FREIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_muted)
	_draw_text(font, dispatch_card.position + Vector2(16, 82), CompanyOperations.job_label(), HORIZONTAL_ALIGNMENT_LEFT, dispatch_card.size.x - 32.0, 11, c_text)
	_draw_text(font, dispatch_card.position + Vector2(16, 119), CompanyOperations.job_cost_label(), HORIZONTAL_ALIGNMENT_LEFT, dispatch_card.size.x - 32.0, 9, c_muted)
	_draw_text(font, dispatch_card.position + Vector2(16, 156), CompanyOperations.trip_summary(), HORIZONTAL_ALIGNMENT_LEFT, dispatch_card.size.x - 32.0, 9, c_muted)
	var goal := _company_goal()
	var goal_y := dispatch_card.position.y + 188.0
	var goal_height := minf(90.0, dispatch_card.end.y - 62.0 - goal_y)
	if goal_height >= 48.0:
		var goal_rect := Rect2(dispatch_card.position.x + 12.0, goal_y, dispatch_card.size.x - 24.0, goal_height)
		_draw_ui_card(goal_rect, c_bg, c_panel_stroke, 8)
		_draw_rect(Rect2(goal_rect.position.x, goal_rect.position.y + 8.0, 3.0, goal_rect.size.y - 16.0), c_orange, true)
		_draw_text(font, goal_rect.position + Vector2(12.0, 18.0), "OPTIONAL COMPANY GOAL", HORIZONTAL_ALIGNMENT_LEFT, goal_rect.size.x - 24.0, 8, c_orange)
		_draw_text(font, goal_rect.position + Vector2(12.0, 41.0), str(goal["title"]), HORIZONTAL_ALIGNMENT_LEFT, goal_rect.size.x - 24.0, 12, c_text)
		_draw_text(font, goal_rect.position + Vector2(12.0, 61.0), str(goal["detail"]), HORIZONTAL_ALIGNMENT_LEFT, goal_rect.size.x - 24.0, 9, c_muted)
	_draw_operation_button("ops_section_%d" % int(goal["section"]), "NEXT STEP  •  %s" % str(goal["button"]), Rect2(dispatch_card.position.x + 12.0, dispatch_card.end.y - 50.0, dispatch_card.size.x - 24.0, 42.0), font)


func _company_goal() -> Dictionary:
	if CompanyOperations.fleet.is_empty():
		return {"title":"Build your first fleet","detail":"Start with a van for local freight.","button":"OPEN FLEET","section":1}
	if CompanyOperations.drivers.is_empty():
		return {"title":"Hire your first driver","detail":"A driver is needed before dispatch.","button":"OPEN DRIVERS","section":2}
	if CompanyOperations.trips.is_empty():
		return {"title":"Make your first delivery","detail":"Choose a local job and send a crew.","button":"OPEN DISPATCH","section":3}
	var returned_trips := 0
	for trip in CompanyOperations.trips:
		if str(trip.get("status", "")) == "returned":
			returned_trips += 1
	if returned_trips == 0:
		var active_runs := active_count_on_road()
		var detail := "%d truck%s currently on the road." % [active_runs, " is" if active_runs == 1 else "s are"] if active_runs > 0 else "Dispatch a local freight job to get started."
		return {"title":"Bring your first delivery home","detail":detail,"button":"OPEN DISPATCH","section":3}
	if CompanyOperations.owned_terminals.size() <= 1:
		return {"title":"Open a remote depot","detail":"Unlock line-haul jobs and widen your network.","button":"OPEN DEPOTS","section":4}
	return {"title":"Grow your transport company","detail":"Add trucks and take on new freight.","button":"OPEN FLEET","section":1}


func _draw_fleet_section(panel: Rect2, font: Font) -> void:
	_draw_text(font, panel.position + Vector2(18, 27), "FLEET GARAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c_text)
	_draw_text(font, panel.position + Vector2(18, 45), "Grow from city vans to a national heavy-haul fleet", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 10, c_muted)
	var inner := Rect2(panel.position.x + 14.0, panel.position.y + 58.0, panel.size.x - 28.0, panel.size.y - 72.0)
	var hero_width := inner.size.x * 0.56
	var hero := Rect2(inner.position, Vector2(hero_width, inner.size.y))
	var specs := Rect2(hero.end.x + 12.0, inner.position.y, inner.size.x - hero_width - 12.0, inner.size.y)
	_draw_ui_card(hero, c_surface_raised, c_panel_stroke, 10)
	_draw_ui_card(specs, c_surface_raised, c_panel_stroke, 10)
	var vehicle_class := CompanyOperations.next_vehicle_class()
	var title := CompanyOperations.next_vehicle_label()
	var tier := CompanyOperations.next_vehicle_tier()
	var status := "NEXT IN THE FLEET LINE-UP"
	var capacity := 0
	var cargo_text := ""
	var energy := ""
	var running_cost := 0.0
	var condition := -1.0
	if not CompanyOperations.fleet.is_empty():
		var vehicle: Dictionary = CompanyOperations.fleet[posmod(CompanyOperations.selected_vehicle, CompanyOperations.fleet.size())]
		vehicle_class = str(vehicle.get("class", "rigid"))
		title = str(vehicle.get("name", "Company truck"))
		tier = _vehicle_tier_label(vehicle_class)
		status = str(vehicle.get("status", "available")).to_upper()
		capacity = int(vehicle.get("capacity", 0))
		cargo_text = ", ".join(vehicle.get("cargo", []))
		energy = "%s • %.0f per 100 km" % [str(vehicle.get("energy_type", "diesel")).capitalize(), float(vehicle.get("energy_use_per_100km", 0.0))]
		running_cost = float(vehicle.get("km_cost", 0.0))
		condition = float(vehicle.get("condition", 100.0))
	else:
		var upcoming: Dictionary = CompanyOperations.next_vehicle_definition()
		capacity = int(upcoming.get("capacity", 0))
		cargo_text = ", ".join(upcoming.get("cargo", []))
		energy = "%s • %.0f per 100 km" % [str(upcoming.get("energy_type", "diesel")).capitalize(), float(upcoming.get("energy_use_per_100km", 0.0))]
		running_cost = float(upcoming.get("km_cost", 0.0))
	_draw_text(font, hero.position + Vector2(20, 26), tier.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, hero.size.x - 40.0, 10, c_cyan)
	_draw_text(font, Vector2(hero.position.x + 20, hero.position.y + 56), title, HORIZONTAL_ALIGNMENT_LEFT, hero.size.x - 40.0, 15, c_text)
	_draw_truck_illustration(Rect2(hero.position.x + 22.0, hero.position.y + 91.0, hero.size.x - 44.0, 116.0), c_orange, vehicle_class)
	_draw_text(font, hero.position + Vector2(20, hero.size.y - 58.0), status, HORIZONTAL_ALIGNMENT_LEFT, hero.size.x - 40.0, 9, c_muted)
	var buy_y := hero.end.y - 48.0
	if CompanyOperations.fleet.is_empty():
		_draw_operation_button("buy_vehicle", "BUY FIRST VAN  •  " + CompanyOperations.next_vehicle_label(), Rect2(hero.position.x + 14.0, buy_y, hero.size.x - 28.0, 44.0), font)
	else:
		_draw_operation_button("cycle_vehicle", "SELECT NEXT OWNED TRUCK", Rect2(hero.position.x + 14.0, buy_y, (hero.size.x - 34.0) * 0.48, 44.0), font)
		_draw_operation_button("buy_vehicle", "BUY NEXT  •  " + CompanyOperations.next_vehicle_label(), Rect2(hero.position.x + 20.0 + (hero.size.x - 34.0) * 0.48, buy_y, (hero.size.x - 34.0) * 0.52, 44.0), font)
	_draw_text(font, specs.position + Vector2(18, 27), "TRUCK PROFILE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	_draw_profile_value(font, specs, 58.0, "PAYLOAD", "%d units" % capacity)
	_draw_profile_value(font, specs, 101.0, "FREIGHT", cargo_text.capitalize())
	_draw_profile_value(font, specs, 152.0, "ENERGY", energy)
	_draw_profile_value(font, specs, 203.0, "RUNNING COST", "R%.0f / km" % running_cost)
	if condition >= 0.0:
		_draw_profile_value(font, specs, 254.0, "CONDITION", "%.0f%%" % condition)
		draw_rect(Rect2(specs.position.x + 18.0, specs.position.y + 280.0, specs.size.x - 36.0, 10.0), c_bg, true)
		draw_rect(Rect2(specs.position.x + 18.0, specs.position.y + 280.0, (specs.size.x - 36.0) * condition / 100.0, 10.0), c_positive if condition > 40.0 else c_orange, true)
	else:
		_draw_text(font, specs.position + Vector2(18, specs.size.y - 55.0), "TRAILER COMBINATIONS ARE A LATER FLEET STEP", HORIZONTAL_ALIGNMENT_LEFT, specs.size.x - 36.0, 9, c_muted)


func _draw_profile_value(font: Font, panel: Rect2, y: float, label: String, value: String) -> void:
	_draw_text(font, panel.position + Vector2(18, y), label, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 8, c_muted)
	_draw_text(font, panel.position + Vector2(18, y + 18.0), value, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 11, c_text)


func _draw_drivers_section(panel: Rect2, font: Font) -> void:
	_draw_text(font, panel.position + Vector2(18, 27), "DRIVER ROSTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c_text)
	_draw_text(font, panel.position + Vector2(18, 45), "Build a crew whose licences match the freight you carry", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 10, c_muted)
	var current := Rect2(panel.position.x + 14.0, panel.position.y + 60.0, panel.size.x * 0.48 - 18.0, panel.size.y - 74.0)
	var candidate := Rect2(current.end.x + 12.0, current.position.y, panel.end.x - 14.0 - (current.end.x + 12.0), current.size.y)
	_draw_ui_card(current, c_surface_raised, c_panel_stroke, 10)
	_draw_ui_card(candidate, c_surface_raised, c_panel_stroke, 10)
	_draw_text(font, current.position + Vector2(18, 28), "CURRENT CREW", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	if CompanyOperations.drivers.is_empty():
		draw_circle(current.position + Vector2(58, 105), 40, Color(c_cyan, 0.15))
		_draw_text(font, current.position + Vector2(31, 111), "DR", HORIZONTAL_ALIGNMENT_LEFT, 55, 22, c_cyan)
		_draw_text(font, current.position + Vector2(116, 92), "No drivers hired", HORIZONTAL_ALIGNMENT_LEFT, current.size.x - 136.0, 15, c_text)
		_draw_text(font, current.position + Vector2(116, 116), "Hire a general driver to start local work.", HORIZONTAL_ALIGNMENT_LEFT, current.size.x - 136.0, 10, c_muted)
	else:
		var driver: Dictionary = CompanyOperations.drivers[posmod(CompanyOperations.selected_driver, CompanyOperations.drivers.size())]
		draw_circle(current.position + Vector2(58, 105), 40, Color(c_cyan, 0.15))
		_draw_text(font, current.position + Vector2(25, 111), str(driver.get("name", "Driver")).left(2).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 66, 20, c_cyan)
		_draw_text(font, current.position + Vector2(116, 92), str(driver.get("name", "Driver")), HORIZONTAL_ALIGNMENT_LEFT, current.size.x - 136.0, 15, c_text)
		_draw_text(font, current.position + Vector2(116, 116), "R%s per game day" % CompanyOperations.commas(int(driver.get("wage", 0))), HORIZONTAL_ALIGNMENT_LEFT, current.size.x - 136.0, 10, c_muted)
		_draw_text(font, current.position + Vector2(18, 173), "ENDORSEMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c_cyan)
		_draw_text(font, current.position + Vector2(18, 194), ", ".join(driver.get("endorsements", ["general"])).replace("_", " ").capitalize(), HORIZONTAL_ALIGNMENT_LEFT, current.size.x - 36.0, 12, c_text)
		_draw_operation_button("cycle_driver", "SELECT NEXT DRIVER", Rect2(current.position.x + 14.0, current.end.y - 48.0, current.size.x - 28.0, 44.0), font)
	_draw_text(font, candidate.position + Vector2(18, 28), "NEXT AVAILABLE HIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	_draw_text(font, candidate.position + Vector2(18, 76), CompanyOperations.next_driver_label(), HORIZONTAL_ALIGNMENT_LEFT, candidate.size.x - 36.0, 14, c_text)
	_draw_text(font, candidate.position + Vector2(18, 106), "Candidates bring different wages and specialist credentials. Keep general drivers on standard freight; match endorsements to restricted loads.", HORIZONTAL_ALIGNMENT_LEFT, candidate.size.x - 36.0, 10, c_muted)
	_draw_text(font, candidate.position + Vector2(18, 177), "CREW SIZE  •  %d" % CompanyOperations.drivers.size(), HORIZONTAL_ALIGNMENT_LEFT, candidate.size.x - 36.0, 10, c_text)
	_draw_operation_button("hire_driver", "HIRE DRIVER", Rect2(candidate.position.x + 14.0, candidate.end.y - 48.0, candidate.size.x - 28.0, 44.0), font)


func _draw_depots_section(panel: Rect2, font: Font) -> void:
	_draw_text(font, panel.position + Vector2(18, 27), "DEPOT NETWORK", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c_text)
	_draw_text(font, panel.position + Vector2(18, 45), "Open depots to create new freight markets", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 10, c_muted)
	var left := Rect2(panel.position.x + 14.0, panel.position.y + 60.0, panel.size.x * 0.54 - 20.0, panel.size.y - 74.0)
	var right := Rect2(left.end.x + 12.0, left.position.y, panel.end.x - 14.0 - (left.end.x + 12.0), left.size.y)
	_draw_ui_card(left, c_surface_raised, c_panel_stroke, 10)
	_draw_ui_card(right, c_surface_raised, c_panel_stroke, 10)
	_draw_text(font, left.position + Vector2(18, 28), "OWNED TERMINALS  •  %d / 5" % CompanyOperations.owned_terminals.size(), HORIZONTAL_ALIGNMENT_LEFT, left.size.x - 36.0, 10, c_cyan)
	for i in range(CompanyOperations.owned_terminals.size()):
		var row_y := left.position.y + 55.0 + float(i) * 43.0
		draw_circle(Vector2(left.position.x + 29.0, row_y - 4.0), 7.0, c_positive)
		_draw_text(font, Vector2(left.position.x + 47.0, row_y), str(CompanyOperations.owned_terminals[i]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, left.size.x - 70.0, 11, c_text)
		_draw_text(font, Vector2(left.position.x + 47.0, row_y + 15.0), "FREIGHT DEPOT  •  ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, left.size.x - 70.0, 8, c_muted)
	_draw_text(font, right.position + Vector2(18, 28), "NEXT EXPANSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	var next_terminal := CompanyOperations.next_terminal_label()
	_draw_text(font, right.position + Vector2(18, 76), next_terminal, HORIZONTAL_ALIGNMENT_LEFT, right.size.x - 36.0, 15, c_text)
	_draw_text(font, right.position + Vector2(18, 105), "A new depot unlocks terminal-to-terminal line-haul demand from Cape Town.", HORIZONTAL_ALIGNMENT_LEFT, right.size.x - 36.0, 10, c_muted)
	_draw_operation_button("cycle_terminal", "SELECT NEXT DEPOT", Rect2(right.position.x + 14.0, right.position.y + 160.0, right.size.x - 28.0, 40.0), font)
	_draw_operation_button("buy_terminal", "OPEN SELECTED DEPOT", Rect2(right.position.x + 14.0, right.position.y + 204.0, right.size.x - 28.0, 44.0), font)


func _draw_workshop_section(panel: Rect2, font: Font) -> void:
	_draw_text(font, panel.position + Vector2(18, 27), "WORKSHOP & MAINTENANCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c_text)
	_draw_text(font, panel.position + Vector2(18, 45), "Service trucks between trips to keep them road-ready", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 10, c_muted)
	var left := Rect2(panel.position.x + 14.0, panel.position.y + 60.0, panel.size.x * 0.58 - 20.0, panel.size.y - 74.0)
	var right := Rect2(left.end.x + 12.0, left.position.y, panel.end.x - 14.0 - (left.end.x + 12.0), left.size.y)
	_draw_ui_card(left, c_surface_raised, c_panel_stroke, 10)
	_draw_ui_card(right, c_surface_raised, c_panel_stroke, 10)
	if CompanyOperations.fleet.is_empty():
		_draw_truck_illustration(Rect2(left.position.x + 34.0, left.position.y + 58.0, 174.0, 78.0), c_orange, CompanyOperations.next_vehicle_class())
		_draw_text(font, left.position + Vector2(24, 173), "Buy your first truck to start its service record.", HORIZONTAL_ALIGNMENT_LEFT, left.size.x - 48.0, 11, c_muted)
	else:
		var vehicle: Dictionary = CompanyOperations.fleet[posmod(CompanyOperations.selected_vehicle, CompanyOperations.fleet.size())]
		_draw_truck_illustration(Rect2(left.position.x + 34.0, left.position.y + 34.0, 190.0, 90.0), c_orange, str(vehicle.get("class", "rigid")))
		_draw_text(font, left.position + Vector2(24, 151), str(vehicle.get("name", "Truck")), HORIZONTAL_ALIGNMENT_LEFT, left.size.x - 48.0, 13, c_text)
		_draw_text(font, left.position + Vector2(24, 174), CompanyOperations.vehicle_condition_label(), HORIZONTAL_ALIGNMENT_LEFT, left.size.x - 48.0, 9, c_muted)
		var condition := clampf(float(vehicle.get("condition", 100.0)), 0.0, 100.0)
		draw_rect(Rect2(left.position.x + 24.0, left.position.y + 194.0, left.size.x - 48.0, 12.0), c_bg, true)
		draw_rect(Rect2(left.position.x + 24.0, left.position.y + 194.0, (left.size.x - 48.0) * condition / 100.0, 12.0), c_positive if condition > 40.0 else c_orange, true)
		_draw_operation_button("cycle_vehicle", "SELECT TRUCK", Rect2(left.position.x + 14.0, left.end.y - 48.0, (left.size.x - 34.0) * 0.45, 44.0), font)
		_draw_operation_button("repair_vehicle", CompanyOperations.repair_label(), Rect2(left.position.x + 20.0 + (left.size.x - 34.0) * 0.45, left.end.y - 48.0, (left.size.x - 34.0) * 0.55, 44.0), font)
	_draw_text(font, right.position + Vector2(18, 28), "WORKSHOP LEVEL  %d / 2" % CompanyOperations.workshop_level, HORIZONTAL_ALIGNMENT_LEFT, right.size.x - 36.0, 10, c_cyan)
	_draw_text(font, right.position + Vector2(18, 67), "Workshop Efficiency", HORIZONTAL_ALIGNMENT_LEFT, right.size.x - 36.0, 13, c_text)
	_draw_text(font, right.position + Vector2(18, 87), "20% lower condition repair costs", HORIZONTAL_ALIGNMENT_LEFT, right.size.x - 36.0, 9, c_muted)
	_draw_text(font, right.position + Vector2(18, 132), "Workshop Expansion", HORIZONTAL_ALIGNMENT_LEFT, right.size.x - 36.0, 13, c_text)
	_draw_text(font, right.position + Vector2(18, 152), "35% total repair savings at level 2", HORIZONTAL_ALIGNMENT_LEFT, right.size.x - 36.0, 9, c_muted)
	_draw_operation_button("workshop_upgrade", CompanyOperations.workshop_upgrade_label(), Rect2(right.position.x + 14.0, right.end.y - 48.0, right.size.x - 28.0, 44.0), font)


func _draw_dispatch_panel(panel: Rect2, font: Font) -> void:
	_draw_text(font, panel.position + Vector2(18, 26), "DISPATCH DESK", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c_text)
	_draw_text(font, panel.position + Vector2(18, 43), "Choose work for your Cape Town fleet", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 36.0, 10, c_muted)
	var inner_x := panel.position.x + 14.0
	var tab_y := panel.position.y + 56.0
	var tab_gap := 6.0
	var tab_width := (panel.size.x - 28.0 - tab_gap * 2.0) / 3.0
	_draw_operation_button("tab_local", "LOCAL FREIGHT", Rect2(inner_x, tab_y, tab_width, 42.0), font)
	_draw_operation_button("tab_contracts", "CONTRACTS", Rect2(inner_x + tab_width + tab_gap, tab_y, tab_width, 42.0), font)
	_draw_operation_button("tab_network", "LINE-HAUL", Rect2(inner_x + (tab_width + tab_gap) * 2.0, tab_y, tab_width, 42.0), font)
	var route_card := Rect2(inner_x, panel.position.y + 107.0, panel.size.x - 28.0, 145.0)
	_draw_ui_card(route_card, c_surface_raised, c_panel_stroke, 10)
	if operations_tab == 0:
		_draw_local_job_card(route_card, font)
		_draw_operation_button("next_job", "NEXT AVAILABLE LOAD", Rect2(inner_x, panel.position.y + 261.0, (panel.size.x - 34.0) * 0.36, 46.0), font)
		_draw_operation_button("dispatch", "DISPATCH FREIGHT", Rect2(inner_x + (panel.size.x - 34.0) * 0.36 + 6.0, panel.position.y + 261.0, (panel.size.x - 34.0) * 0.64, 46.0), font)
	elif operations_tab == 1:
		_draw_text(font, route_card.position + Vector2(16, 25), "LONG-HAUL CONTRACT", HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 10, c_cyan)
		_draw_text(font, route_card.position + Vector2(16, 53), CompanyOperations.contract_label(), HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 12, c_text)
		_draw_text(font, route_card.position + Vector2(16, 88), CompanyOperations.contract_deadline_label(), HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 10, c_muted)
		_draw_text(font, route_card.position + Vector2(16, 124), "Contract delivery • return time is simulated", HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 9, c_muted)
		_draw_operation_button("next_contract", "NEXT OFFER", Rect2(inner_x, panel.position.y + 261.0, (panel.size.x - 34.0) * 0.36, 46.0), font)
		_draw_operation_button("contract_action", CompanyOperations.contract_action_label(), Rect2(inner_x + (panel.size.x - 34.0) * 0.36 + 6.0, panel.position.y + 261.0, (panel.size.x - 34.0) * 0.64, 46.0), font)
	else:
		_draw_text(font, route_card.position + Vector2(16, 25), "TERMINAL-TO-TERMINAL FREIGHT", HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 10, c_cyan)
		_draw_text(font, route_card.position + Vector2(16, 57), CompanyOperations.network_job_label(), HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 12, c_text)
		_draw_text(font, route_card.position + Vector2(16, 98), CompanyOperations.network_cost_label(), HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 10, c_muted)
		_draw_text(font, route_card.position + Vector2(16, 125), "Owned terminals unlock this market", HORIZONTAL_ALIGNMENT_LEFT, route_card.size.x - 32.0, 9, c_muted)
		_draw_operation_button("next_network_job", "NEXT LOAD", Rect2(inner_x, panel.position.y + 261.0, (panel.size.x - 34.0) * 0.36, 46.0), font)
		_draw_operation_button("dispatch_network", "DISPATCH LINE-HAUL", Rect2(inner_x + (panel.size.x - 34.0) * 0.36 + 6.0, panel.position.y + 261.0, (panel.size.x - 34.0) * 0.64, 46.0), font)
	var activity_y := panel.position.y + 315.0
	var activity_h := maxf(64.0, panel.end.y - activity_y - 14.0)
	var activity_rect := Rect2(inner_x, activity_y, panel.size.x - 28.0, activity_h)
	_draw_ui_card(activity_rect, c_bg, c_panel_stroke, 10)
	_draw_text(font, activity_rect.position + Vector2(14, 21), "ON THE ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c_cyan)
	draw_circle(Vector2(activity_rect.end.x - 19.0, activity_rect.position.y + 17.0), 4.0, c_positive if active_count_on_road() > 0 else c_muted)
	if active_count_on_road() > 0:
		_draw_truck_illustration(Rect2(activity_rect.position.x + 13.0, activity_rect.position.y + 31.0, 78.0, 30.0), c_orange)
		_draw_text(font, activity_rect.position + Vector2(102, 48), CompanyOperations.trip_summary(), HORIZONTAL_ALIGNMENT_LEFT, activity_rect.size.x - 118.0, 11, c_text)
	else:
		_draw_road_motif(Rect2(activity_rect.position.x + 14.0, activity_rect.position.y + 32.0, 82.0, 27.0))
		_draw_text(font, activity_rect.position + Vector2(110, 49), "Your dispatched trucks will appear here", HORIZONTAL_ALIGNMENT_LEFT, activity_rect.size.x - 124.0, 11, c_muted)


func _draw_local_job_card(card: Rect2, font: Font) -> void:
	CompanyOperations.job_label()
	var has_job := not CompanyOperations.jobs.is_empty()
	var job: Dictionary = {}
	if has_job:
		CompanyOperations.selected_job = posmod(CompanyOperations.selected_job, CompanyOperations.jobs.size())
		job = CompanyOperations.jobs[CompanyOperations.selected_job]
	var destination := str(job.get("destination", "No destination"))
	var cargo_name := str(job.get("cargo_name", "No available freight"))
	var distance := int(job.get("km", 0))
	var units := int(job.get("demand", 0))
	var revenue := 0
	if has_job:
		if not CompanyOperations.fleet.is_empty():
			var vehicle: Dictionary = CompanyOperations.fleet[posmod(CompanyOperations.selected_vehicle, CompanyOperations.fleet.size())]
			units = mini(units, int(vehicle.get("capacity", units)))
		revenue = int(500 + distance * float(job.get("rate", 0.0)) * units)
	_draw_text(font, card.position + Vector2(16, 23), "AVAILABLE LOAD", HORIZONTAL_ALIGNMENT_LEFT, 120, 10, c_cyan)
	_draw_text(font, card.position + Vector2(card.size.x - 116.0, 23), "CAPE TOWN • LOCAL", HORIZONTAL_ALIGNMENT_RIGHT, 100, 9, c_muted)
	_draw_text(font, card.position + Vector2(16, 49), cargo_name, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 32.0, 15, c_text)
	var route_y := card.position.y + 78.0
	var start_x := card.position.x + 20.0
	var end_x := card.end.x - 20.0
	draw_circle(Vector2(start_x + 6.0, route_y), 6.0, c_cyan)
	draw_circle(Vector2(end_x - 6.0, route_y), 6.0, c_orange)
	draw_line(Vector2(start_x + 18.0, route_y), Vector2(end_x - 22.0, route_y), c_panel_stroke, 3.0, true)
	var route_truck_class := CompanyOperations.next_vehicle_class()
	if not CompanyOperations.fleet.is_empty():
		route_truck_class = str(CompanyOperations.fleet[posmod(CompanyOperations.selected_vehicle, CompanyOperations.fleet.size())].get("class", "rigid"))
	_draw_truck_illustration(Rect2((start_x + end_x) * 0.5 - 27.0, route_y - 18.0, 54.0, 28.0), c_orange, route_truck_class)
	_draw_text(font, Vector2(start_x, route_y + 24.0), "CAPE TOWN", HORIZONTAL_ALIGNMENT_LEFT, 110, 9, c_muted)
	_draw_text(font, Vector2(end_x - 115.0, route_y + 24.0), destination.to_upper(), HORIZONTAL_ALIGNMENT_RIGHT, 115, 9, c_muted)
	var metric_y := card.position.y + 120.0
	_draw_metric(font, Vector2(card.position.x + 16.0, metric_y), "ONE WAY", "%d km" % distance, c_text)
	_draw_metric(font, Vector2(card.position.x + card.size.x * 0.36, metric_y), "LOAD SIZE", "%d units" % units, c_text)
	_draw_metric(font, Vector2(card.position.x + card.size.x * 0.62, metric_y), "EST. REVENUE", "R%s" % CompanyOperations.commas(revenue), c_positive)


func _draw_stat_card(rect: Rect2, label: String, value: String, detail: String, font: Font, highlighted: bool) -> void:
	_draw_ui_card(rect, c_info_bg, c_panel_stroke, 9)
	draw_rect(Rect2(rect.position.x + 1.0, rect.position.y + 9.0, 3.0, rect.size.y - 18.0), c_orange if highlighted else c_cyan, true)
	_draw_text(font, rect.position + Vector2(13, 16), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 22.0, 8, c_muted)
	_draw_text(font, rect.position + Vector2(13, 34), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 22.0, 12, c_text)
	_draw_text(font, Vector2(rect.end.x - 96.0, rect.position.y + 34), detail, HORIZONTAL_ALIGNMENT_RIGHT, 86, 8, c_muted)


func _draw_hud_stat(font: Font, rect: Rect2, label: String, value: String, value_color: Color) -> void:
	_draw_ui_card(rect, c_surface_raised, c_panel_stroke, 8)
	draw_circle(rect.position + Vector2(10.0, 13.0), 3.0, value_color)
	_draw_text(font, rect.position + Vector2(19.0, 16.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 26.0, 7, c_muted)
	_draw_text(font, rect.position + Vector2(10.0, 42.0), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 18.0, 14, value_color)


func _operations_section_title() -> String:
	var names := ["Overview", "Fleet", "Drivers", "Dispatch", "Depots", "Workshop"]
	return names[clampi(operations_section, 0, names.size() - 1)]


func _draw_metric(font: Font, position: Vector2, label: String, value: String, value_color: Color) -> void:
	_draw_text(font, position, label, HORIZONTAL_ALIGNMENT_LEFT, 115, 8, c_muted)
	_draw_text(font, position + Vector2(0, 15), value, HORIZONTAL_ALIGNMENT_LEFT, 130, 11, value_color)


func active_count_on_road() -> int:
	var count := 0
	for trip in CompanyOperations.trips:
		if str(trip.get("status", "")) == "in_transit":
			count += 1
	return count


func _draw_text(font: Font, position: Vector2, text, alignment, width: float, base_size: int, modulate: Color) -> void:
	draw_string(font, position, text, alignment, width, maxi(1, roundi(float(base_size) * UI_TEXT_SCALE)), modulate)


func _draw_ui_card(rect: Rect2, fill: Color, stroke: Color, radius: int = 10) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stroke
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = c_shadow
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.draw(get_canvas_item(), rect)


func _draw_rect(rect: Rect2, color: Color, filled: bool) -> void:
	draw_rect(rect, color, filled)


func _vehicle_tier_label(vehicle_class: String) -> String:
	match vehicle_class:
		"van":
			return "Starter van"
		"electric_van":
			return "Electric van"
		"bakkie":
			return "Bakkie"
		"light_rigid":
			return "Small truck"
		"rigid":
			return "Rigid truck"
		"hazmat_rigid":
			return "Hazmat rigid"
		"reefer":
			return "Refrigerated truck"
		"tipper":
			return "Tipper truck"
		"tractor":
			return "Prime mover"
	return "Fleet vehicle"


func _draw_truck_illustration(rect: Rect2, cab_color: Color, vehicle_class: String = "rigid") -> void:
	var sx := rect.size.x / 140.0
	var sy := rect.size.y / 54.0
	var wheel_radius := 7.0 * minf(sx, sy)
	var wheel_y := rect.position.y + 40.0 * sy
	var cab_window := Color("#73D8EB")
	var body_color := Color("#E9EEF1")
	var outline := Color("#A8BAC5")
	draw_line(rect.position + Vector2(4.0 * sx, 44.0 * sy), rect.position + Vector2(134.0 * sx, 44.0 * sy), Color(c_text, 0.45), maxf(1.0, 4.0 * sy), true)
	if vehicle_class in ["van", "electric_van"]:
		var van_body := PackedVector2Array([
			rect.position + Vector2(8.0 * sx, 16.0 * sy), rect.position + Vector2(93.0 * sx, 16.0 * sy),
			rect.position + Vector2(119.0 * sx, 27.0 * sy), rect.position + Vector2(126.0 * sx, 38.0 * sy),
			rect.position + Vector2(8.0 * sx, 38.0 * sy)
		])
		draw_colored_polygon(van_body, body_color)
		draw_polyline(van_body, outline, maxf(1.0, sx), true)
		draw_rect(Rect2(rect.position + Vector2(19.0 * sx, 23.0 * sy), Vector2(46.0 * sx, 5.0 * sy)), cab_color, true)
		draw_line(rect.position + Vector2(79.0 * sx, 18.0 * sy), rect.position + Vector2(79.0 * sx, 37.0 * sy), outline, maxf(1.0, sx), true)
		var window := PackedVector2Array([rect.position + Vector2(96.0 * sx, 18.0 * sy), rect.position + Vector2(107.0 * sx, 19.0 * sy), rect.position + Vector2(119.0 * sx, 29.0 * sy), rect.position + Vector2(96.0 * sx, 29.0 * sy)])
		draw_colored_polygon(window, cab_window)
		for x in [31.0, 102.0]:
			_draw_wheel(rect.position.x + x * sx, wheel_y, wheel_radius)
	elif vehicle_class == "bakkie":
		draw_rect(Rect2(rect.position + Vector2(8.0 * sx, 25.0 * sy), Vector2(55.0 * sx, 11.0 * sy)), Color("#DCE5EA"), true)
		draw_rect(Rect2(rect.position + Vector2(8.0 * sx, 22.0 * sy), Vector2(5.0 * sx, 16.0 * sy)), cab_color, true)
		draw_rect(Rect2(rect.position + Vector2(59.0 * sx, 25.0 * sy), Vector2(8.0 * sx, 3.0 * sy)), cab_color, true)
		var cab := PackedVector2Array([rect.position + Vector2(68.0 * sx, 22.0 * sy), rect.position + Vector2(90.0 * sx, 14.0 * sy), rect.position + Vector2(111.0 * sx, 17.0 * sy), rect.position + Vector2(121.0 * sx, 29.0 * sy), rect.position + Vector2(121.0 * sx, 38.0 * sy), rect.position + Vector2(68.0 * sx, 38.0 * sy)])
		draw_colored_polygon(cab, cab_color)
		draw_polyline(cab, Color("#FFE0B6"), maxf(1.0, sx), true)
		draw_colored_polygon(PackedVector2Array([rect.position + Vector2(88.0 * sx, 17.0 * sy), rect.position + Vector2(106.0 * sx, 19.0 * sy), rect.position + Vector2(114.0 * sx, 28.0 * sy), rect.position + Vector2(85.0 * sx, 28.0 * sy)]), cab_window)
		for x in [31.0, 101.0]:
			_draw_wheel(rect.position.x + x * sx, wheel_y, wheel_radius)
	else:
		var body_start := 5.0
		var body_end := 80.0
		var cab_start := 85.0
		var wheel_positions: Array = [31.0, 105.0]
		if vehicle_class == "tractor":
			body_start = 4.0
			body_end = 91.0
			cab_start = 98.0
			wheel_positions = [34.0, 66.0, 109.0, 126.0]
		var body_top := 10.0 if vehicle_class in ["rigid", "reefer", "tractor"] else 15.0
		var body_bottom := 37.0 if vehicle_class != "tractor" else 29.0
		if vehicle_class == "tipper":
			var tipper := PackedVector2Array([rect.position + Vector2(body_start * sx, 22.0 * sy), rect.position + Vector2(body_end * sx, 10.0 * sy), rect.position + Vector2(body_end * sx, body_bottom * sy), rect.position + Vector2(body_start * sx, body_bottom * sy)])
			draw_colored_polygon(tipper, Color("#D9E1E5"))
			draw_polyline(tipper, outline, maxf(1.0, sx), true)
		elif vehicle_class == "light_rigid":
			draw_rect(Rect2(rect.position + Vector2(body_start * sx, 29.0 * sy), Vector2((body_end - body_start) * sx, 5.0 * sy)), Color("#AFC1CB"), true)
			for rail_x in [body_start, body_start + 24.0, body_start + 50.0, body_end]:
				draw_rect(Rect2(rect.position + Vector2(rail_x * sx, 19.0 * sy), Vector2(3.0 * sx, 11.0 * sy)), cab_color, true)
			draw_line(rect.position + Vector2(body_start * sx, 20.0 * sy), rect.position + Vector2(body_end * sx, 20.0 * sy), cab_color, maxf(1.0, 2.0 * sy), true)
		else:
			draw_rect(Rect2(rect.position + Vector2(body_start * sx, body_top * sy), Vector2((body_end - body_start) * sx, (body_bottom - body_top) * sy)), body_color, true)
			draw_rect(Rect2(rect.position + Vector2(body_start * sx, body_top * sy), Vector2((body_end - body_start) * sx, (body_bottom - body_top) * sy)), outline, false, maxf(1.0, sx))
			if vehicle_class == "tractor":
				draw_rect(Rect2(rect.position + Vector2(10.0 * sx, 22.0 * sy), Vector2(75.0 * sx, 4.0 * sy)), Color("#B4C3CC"), true)
			else:
				draw_rect(Rect2(rect.position + Vector2((body_start + 7.0) * sx, (body_top + 9.0) * sy), Vector2(5.0 * sx, 9.0 * sy)), cab_color, true)
			if vehicle_class == "reefer":
				draw_line(rect.position + Vector2(58.0 * sx, 13.0 * sy), rect.position + Vector2(58.0 * sx, 34.0 * sy), Color("#76B9CF"), maxf(1.0, sx), true)
			if vehicle_class == "hazmat_rigid":
				draw_rect(Rect2(rect.position + Vector2(24.0 * sx, 25.0 * sy), Vector2(35.0 * sx, 4.0 * sy)), Color("#E7B83F"), true)
		var cab := PackedVector2Array([rect.position + Vector2(cab_start * sx, 24.0 * sy), rect.position + Vector2((cab_start + 9.0) * sx, 17.0 * sy), rect.position + Vector2((cab_start + 28.0) * sx, 17.0 * sy), rect.position + Vector2(135.0 * sx, 30.0 * sy), rect.position + Vector2(135.0 * sx, 38.0 * sy), rect.position + Vector2(cab_start * sx, 38.0 * sy)])
		draw_colored_polygon(cab, cab_color)
		draw_polyline(cab, Color("#FFE0B6"), maxf(1.0, sx), true)
		draw_colored_polygon(PackedVector2Array([rect.position + Vector2((cab_start + 12.0) * sx, 19.0 * sy), rect.position + Vector2((cab_start + 25.0) * sx, 19.0 * sy), rect.position + Vector2(131.0 * sx, 29.0 * sy), rect.position + Vector2((cab_start + 11.0) * sx, 29.0 * sy)]), cab_window)
		for x in wheel_positions:
			_draw_wheel(rect.position.x + float(x) * sx, wheel_y, wheel_radius)


func _draw_wheel(x: float, y: float, radius: float) -> void:
	draw_circle(Vector2(x, y), radius, Color("#182638"))
	draw_circle(Vector2(x, y), radius * 0.44, Color("#AFC1CB"))


func _draw_road_motif(rect: Rect2) -> void:
	draw_line(rect.position + Vector2(0, rect.size.y * 0.65), rect.position + Vector2(rect.size.x, rect.size.y * 0.35), c_panel_stroke, 9.0, true)
	draw_line(rect.position + Vector2(0, rect.size.y * 0.65), rect.position + Vector2(rect.size.x, rect.size.y * 0.35), c_muted, 1.0, true)
	for i in range(4):
		var x := rect.position.x + 12.0 + float(i) * (rect.size.x - 24.0) / 3.0
		draw_circle(Vector2(x, rect.position.y + rect.size.y * (0.65 - 0.3 * float(i) / 3.0)), 2.0, c_orange)


func _draw_operation_button(button_id: String, label: String, rect: Rect2, font: Font) -> void:
	operation_buttons.append({"id": button_id, "rect": rect})
	var primary := button_id in ["buy_vehicle", "hire_driver", "buy_terminal", "repair_vehicle", "dispatch", "dispatch_network", "contract_action"]
	var selected := (button_id == "tab_local" and operations_tab == 0) or (button_id == "tab_contracts" and operations_tab == 1) or (button_id == "tab_network" and operations_tab == 2)
	if button_id.begins_with("ops_section_"):
		selected = int(button_id.trim_prefix("ops_section_")) == operations_section
	var fill := c_orange if primary else (c_button if selected else c_surface_raised)
	var text_color := Color("#FFFFFF") if primary else c_button_text
	var stroke := Color(c_orange.lightened(0.12)) if primary else (c_cyan if selected else c_panel_stroke)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stroke
	style.set_border_width_all(1 if primary or selected else 0)
	style.set_corner_radius_all(8)
	style.shadow_color = c_shadow
	style.shadow_size = 3 if primary else 1
	style.shadow_offset = Vector2(0, 2)
	style.draw(get_canvas_item(), rect)
	var display_label := label
	var font_size := 11 if button_id.begins_with("ops_section_") else 10
	if rect.size.y < 34.0:
		font_size = 9
	if rect.size.x < 150.0 and display_label.length() > 24:
		display_label = display_label.left(21) + "..."
	if button_id.begins_with("ops_section_"):
		var section_index := clampi(int(button_id.trim_prefix("ops_section_")), 0, 5)
		_draw_operations_section_icon(section_index, rect, text_color)
		_draw_text(font, rect.position + Vector2(37.0, rect.size.y * 0.64), display_label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 42.0, font_size, text_color)
	else:
		_draw_text(font, rect.position + Vector2(7, rect.size.y * 0.64), display_label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 14.0, font_size, text_color)


func _draw_operations_section_icon(index: int, rect: Rect2, color: Color) -> void:
	var center := rect.position + Vector2(20.0, rect.size.y * 0.5)
	match index:
		0:
			for point in [Vector2(-5.0, -5.0), Vector2(3.0, -5.0), Vector2(-5.0, 3.0), Vector2(3.0, 3.0)]:
				draw_rect(Rect2(center + point, Vector2(5.0, 5.0)), color, true)
		1:
			draw_rect(Rect2(center + Vector2(-10.0, -5.0), Vector2(12.0, 9.0)), color, false, 1.8)
			draw_colored_polygon(PackedVector2Array([center + Vector2(2.0, -3.0), center + Vector2(8.0, -3.0), center + Vector2(11.0, 1.0), center + Vector2(11.0, 4.0), center + Vector2(2.0, 4.0)]), color)
			draw_circle(center + Vector2(-5.0, 5.0), 2.5, color)
			draw_circle(center + Vector2(6.0, 5.0), 2.5, color)
		2:
			draw_circle(center + Vector2(0.0, -4.0), 4.0, color)
			draw_arc(center + Vector2(0.0, 7.0), 8.0, PI, TAU, 20, color, 2.0, true)
		3:
			draw_circle(center + Vector2(-7.0, 5.0), 3.0, color)
			draw_circle(center + Vector2(7.0, -5.0), 3.0, color)
			draw_line(center + Vector2(-4.0, 3.0), center + Vector2(4.0, -3.0), color, 2.0, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(2.0, -8.0), center + Vector2(9.0, -6.0), center + Vector2(5.0, 0.0)]), color)
		4:
			var warehouse := PackedVector2Array([center + Vector2(-10.0, -2.0), center + Vector2(0.0, -8.0), center + Vector2(10.0, -2.0), center + Vector2(10.0, 8.0), center + Vector2(-10.0, 8.0)])
			draw_polyline(warehouse, color, 2.0, true)
			draw_line(center + Vector2(-3.0, 8.0), center + Vector2(-3.0, 1.0), color, 1.5, true)
			draw_line(center + Vector2(3.0, 8.0), center + Vector2(3.0, 1.0), color, 1.5, true)
		5:
			draw_line(center + Vector2(-7.0, 7.0), center + Vector2(5.0, -5.0), color, 3.0, true)
			draw_circle(center + Vector2(-7.0, 7.0), 3.0, color, false, 1.8, true)
			draw_arc(center + Vector2(7.0, -7.0), 5.0, -0.8, 2.7, 16, color, 2.0, true)


func _draw_view_buttons(font: Font) -> void:
	view_buttons.clear()
	var labels := ["COUNTRY", "PROVINCE", "CITY / TOWN", "OPERATIONS"] if screen_mode == 0 else ["BACK TO MAP"]
	var gap := 10.0
	var button_w := minf(184.0, (controls_rect.size.x - 40.0 - gap * 3.0) / 4.0) if screen_mode == 0 else 224.0
	button_w = maxf(132.0, button_w)
	var total := button_w * float(labels.size()) + gap * float(maxi(0, labels.size() - 1))
	var start_x := maxf(8.0, (controls_rect.size.x - total) * 0.5)
	var button_h := 58.0 if screen_mode == 0 else 48.0
	draw_rect(Rect2(0, controls_rect.position.y, controls_rect.size.x, controls_rect.size.y), c_topbar, true)
	for i in range(labels.size()):
		var rect := Rect2(start_x + float(i) * (button_w + gap), controls_rect.position.y + 5.0, button_w, button_h)
		var active := (screen_mode == 0 and i == map_mode) or screen_mode == 1
		var style := StyleBoxFlat.new()
		style.bg_color = c_orange if active else c_button
		style.border_color = c_orange if active else c_panel_stroke
		style.set_border_width_all(2 if active else 1)
		style.set_corner_radius_all(12)
		style.shadow_color = c_shadow
		style.shadow_size = 4 if active else 2
		style.shadow_offset = Vector2(0, 3)
		style.draw(get_canvas_item(), rect)
		var icon_color := Color.WHITE if active else c_cyan
		_draw_view_navigation_icon(0 if screen_mode == 1 else i, rect, icon_color)
		var text_color := Color.WHITE if active else c_button_text
		_draw_text(font, rect.position + Vector2(34, 37), labels[i], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 42.0, 11, text_color)
		view_buttons.append(rect)


func _draw_view_navigation_icon(icon_index: int, rect: Rect2, color: Color) -> void:
	var center := rect.position + Vector2(21.0, rect.size.y * 0.5)
	match icon_index:
		0:
			draw_circle(center, 8.0, color, false, 2.0, true)
			draw_line(center + Vector2(-8.0, 0.0), center + Vector2(8.0, 0.0), color, 1.5, true)
			draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, 8.0), color, 1.5, true)
			draw_arc(center, 4.5, -PI * 0.5, PI * 0.5, 16, color, 1.2, true)
			draw_arc(center, 4.5, PI * 0.5, PI * 1.5, 16, color, 1.2, true)
		1:
			var province_shape := PackedVector2Array([center + Vector2(-9.0, -7.0), center + Vector2(-2.0, -9.0), center + Vector2(2.0, -5.0), center + Vector2(9.0, -8.0), center + Vector2(8.0, 7.0), center + Vector2(1.0, 9.0), center + Vector2(-3.0, 5.0), center + Vector2(-9.0, 7.0)])
			draw_polyline(province_shape, color, 2.0, true)
			draw_line(center + Vector2(-2.0, -8.0), center + Vector2(-3.0, 5.0), color, 1.2, true)
			draw_line(center + Vector2(2.0, -5.0), center + Vector2(1.0, 8.0), color, 1.2, true)
		2:
			draw_colored_polygon(PackedVector2Array([center + Vector2(-7.0, -4.0), center + Vector2(7.0, -4.0), center + Vector2(0.0, 10.0)]), color)
			draw_circle(center + Vector2(0.0, -5.0), 7.0, color)
			draw_circle(center + Vector2(0.0, -5.0), 2.5, c_topbar)
		3:
			draw_rect(Rect2(center + Vector2(-10.0, -5.0), Vector2(12.0, 9.0)), color, false, 1.8)
			draw_colored_polygon(PackedVector2Array([center + Vector2(2.0, -3.0), center + Vector2(8.0, -3.0), center + Vector2(11.0, 1.0), center + Vector2(11.0, 4.0), center + Vector2(2.0, 4.0)]), color)
			draw_circle(center + Vector2(-5.0, 5.0), 2.5, color)
			draw_circle(center + Vector2(6.0, 5.0), 2.5, color)


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
	_reset_map_view()


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
	if action.begins_with("ops_section_"):
		operations_section = clampi(int(action.trim_prefix("ops_section_")), 0, 5)
		return
	match action:
		"buy_vehicle":
			CompanyOperations.buy_vehicle()
		"hire_driver":
			CompanyOperations.hire_driver()
		"cycle_vehicle":
			CompanyOperations.cycle_vehicle()
		"repair_vehicle":
			CompanyOperations.repair_selected_vehicle()
		"workshop_upgrade":
			CompanyOperations.buy_workshop_upgrade()
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


func _handle_map_control(action: String) -> void:
	match action:
		"open_operations":
			screen_mode = 1
		"zoom_in":
			_zoom_map(1.35, map_rect.get_center())
		"zoom_out":
			_zoom_map(1.0 / 1.35, map_rect.get_center())
		"zoom_reset":
			_reset_map_view()
		"layer_routes":
			show_map_routes = not show_map_routes
		"layer_places":
			show_map_places = not show_map_places
		"layer_terminals":
			show_map_terminals = not show_map_terminals
	_save_progress()
	queue_redraw()
	accept_event()


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
	if screen_mode == 0:
		for button in map_control_buttons:
			if button["rect"].has_point(position):
				_handle_map_control(str(button["id"]))
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
				_reset_map_view()
			elif i == 1:
				map_mode = 1
				selected_place = selected_province
				selected_item = {"name": selected_province, "type": "Province", "province": selected_province}
				_reset_map_view()
			else:
				map_mode = 2
				selected_place = selected_city
				selected_item = {"name": selected_city, "type": "City", "province": selected_province}
				_reset_map_view()
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
			_reset_map_view()
			queue_redraw()
			accept_event()


func _gui_input(event: InputEvent) -> void:
	# Android can synthesize mouse clicks from touch. The map has its own touch
	# gesture path; the synthetic click can turn a drag into a map tap and drill
	# into the next view instead of panning.
	if OS.has_feature("mobile") and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if not map_rect.has_point(touch.position) or screen_mode == 1:
				_handle_tap(touch.position)
				return
			touch_positions[touch.index] = touch.position
			if touch_positions.size() == 1:
				touch_start_position = touch.position
				touch_last_center = touch.position
				touch_moved = false
				touch_multitouch = false
			elif touch_positions.size() == 2:
				touch_multitouch = true
				var points: Array = touch_positions.values()
				touch_last_center = (points[0] + points[1]) * 0.5
				touch_last_distance = points[0].distance_to(points[1])
			accept_event()
		else:
			if not touch_positions.has(touch.index):
				return
			touch_positions.erase(touch.index)
			if touch_positions.is_empty():
				if not touch_multitouch and not touch_moved:
					_handle_tap(touch_start_position)
				touch_moved = false
				touch_multitouch = false
				touch_last_distance = 0.0
			elif touch_positions.size() == 1:
				touch_last_center = touch_positions.values()[0]
			accept_event()
	elif event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		_zoom_map(magnify.factor, magnify.position)
		accept_event()
	elif event is InputEventPanGesture:
		var pan := event as InputEventPanGesture
		_pan_map(pan.delta)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not touch_positions.has(drag.index):
			return
		touch_positions[drag.index] = drag.position
		if touch_positions.size() >= 2:
			var points: Array = touch_positions.values()
			var center: Vector2 = (points[0] + points[1]) * 0.5
			var distance: float = points[0].distance_to(points[1])
			if touch_last_distance > 0.0 and distance > 0.0:
				_zoom_map(distance / touch_last_distance, center)
			_pan_map(center - touch_last_center)
			touch_last_distance = distance
			touch_last_center = center
			touch_moved = true
		else:
			var current: Vector2 = touch_positions.values()[0]
			var delta := current - touch_last_center
			if current.distance_to(touch_start_position) > 7.0:
				touch_moved = true
				_pan_map(delta)
			touch_last_center = current
		accept_event()
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed and map_rect.has_point(mouse_button.position):
			_zoom_map(1.25, mouse_button.position)
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed and map_rect.has_point(mouse_button.position):
			_zoom_map(0.8, mouse_button.position)
		elif mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed and map_rect.has_point(mouse_button.position) and screen_mode == 0:
				mouse_map_dragging = true
				mouse_drag_start = mouse_button.position
				mouse_last_position = mouse_button.position
				mouse_drag_moved = false
			elif not mouse_button.pressed and mouse_map_dragging:
				mouse_map_dragging = false
				if not mouse_drag_moved:
					_handle_tap(mouse_drag_start)
			elif mouse_button.pressed:
				_handle_tap(mouse_button.position)
			accept_event()
	elif event is InputEventMouseMotion and mouse_map_dragging:
		var mouse_motion := event as InputEventMouseMotion
		var delta := mouse_motion.position - mouse_last_position
		if mouse_motion.position.distance_to(mouse_drag_start) > 5.0:
			mouse_drag_moved = true
			_pan_map(delta)
		mouse_last_position = mouse_motion.position
		accept_event()
