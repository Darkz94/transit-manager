extends Node

signal state_changed
signal message_changed(message: String)

const DAY_SECONDS := 86400.0
const STARTING_CASH := 1250000
const HOME := "Cape Town"
const ENERGY_PRICES := {"diesel":24.0,"petrol":26.0,"electricity":3.2}
const INSPECTION_INTERVAL_KM := 5000
const INSPECTION_COST := 12000
const WORKSHOP_UPGRADE_COST := 200000
const WORKSHOP_EXPANSION_COST := 450000
const WORKSHOP_REPAIR_DISCOUNT := 0.20
const WORKSHOP_EXPANSION_DISCOUNT := 0.35
const INCIDENT_BASE_CHANCE := 0.025
const INCIDENT_MAX_DISTANCE_BONUS := 0.02
const INCIDENT_CONDITION_THRESHOLD := 70.0
const INCIDENT_MAX_CONDITION_BONUS := 0.02
# Keep this ordered as a first-company growth path: vans, bakkies, light
# rigid trucks, then the heavier and more specialized working vehicles.
const VEHICLES := [
	{"id":"van","name":"Coastal Courier Van","class":"van","tier":"Starter van","price":280000,"capacity":8,"km_cost":10.0,"energy_type":"petrol","energy_use_per_100km":10.0,"equipment":["standard"],"cargo":["parcels","dry"]},
	{"id":"electric_van","name":"E-Courier Urban Van","class":"electric_van","tier":"Electric van","price":640000,"capacity":7,"km_cost":6.0,"energy_type":"electricity","energy_use_per_100km":23.0,"equipment":["standard"],"cargo":["parcels","dry"]},
	{"id":"bakkie","name":"CapeRunner Bakkie","class":"bakkie","tier":"Bakkie","price":240000,"capacity":6,"km_cost":9.0,"energy_type":"petrol","energy_use_per_100km":12.0,"equipment":["standard","flatbed"],"cargo":["parcels","dry","building"]},
	{"id":"light_rigid","name":"TownLink 3T Dropside","class":"light_rigid","tier":"Small truck","price":490000,"capacity":14,"km_cost":16.0,"energy_type":"diesel","energy_use_per_100km":20.0,"equipment":["standard","flatbed"],"cargo":["dry","building"]},
	{"id":"rigid","name":"Regional Rigid 8T","class":"rigid","tier":"Medium rigid","price":760000,"capacity":28,"km_cost":22.0,"energy_type":"diesel","energy_use_per_100km":25.0,"equipment":["standard","flatbed"],"cargo":["dry","building"]},
	{"id":"reefer","name":"ColdLink Refrigerated","class":"reefer","tier":"Refrigerated rigid","price":920000,"capacity":20,"km_cost":25.0,"energy_type":"diesel","energy_use_per_100km":30.0,"equipment":["standard","refrigerated"],"cargo":["produce","dry"]},
	{"id":"capebulk_tipper","name":"CapeBulk Tipper 10T","class":"tipper","tier":"Heavy tipper","price":1050000,"capacity":32,"km_cost":26.0,"energy_type":"diesel","energy_use_per_100km":27.0,"equipment":["standard","tipper"],"cargo":["granular","building"]},
	{"id":"safechem_rigid","name":"SafeRoute DG Rigid","class":"hazmat_rigid","tier":"Hazmat rigid","price":1180000,"capacity":22,"km_cost":29.0,"energy_type":"diesel","energy_use_per_100km":28.0,"equipment":["standard","hazmat"],"cargo":["dry","hazmat"]},
	{"id":"prime_mover","name":"Longhaul Prime Mover","class":"tractor","tier":"Prime mover + trailer","price":1350000,"capacity":40,"km_cost":32.0,"energy_type":"diesel","energy_use_per_100km":38.0,"equipment":["standard","flatbed","machinery_platform"],"cargo":["dry","building","machinery"]}
]
# Saves created before the expanded starter roster stored an array index. Map
# those indices back to the same offer so an existing company keeps its place.
const LEGACY_VEHICLE_OFFER_IDS := ["van", "rigid", "reefer", "prime_mover", "safechem_rigid", "capebulk_tipper", "electric_van"]
const DRIVERS := [
	{"name":"Lebo Mokoena","wage":900,"endorsements":["general"]},
	{"name":"Siyabonga Dlamini","wage":1050,"endorsements":["general"]},
	{"name":"Nadia Jacobs","wage":1150,"endorsements":["general"]},
	{"name":"Thandi Ndlovu","wage":1480,"endorsements":["general","hazmat"]},
	{"name":"Zanele Pieters","wage":1360,"endorsements":["general","cold_chain"]},
	{"name":"Sipho Maseko","wage":1680,"endorsements":["general","heavy_haul"]}
]
const CARGO := [
	{"id":"parcels","name":"Parcel freight","rate":22.0,"equipment":"standard","wear_factor":0.8},
	{"id":"dry","name":"Packaged goods","rate":17.0,"equipment":"standard","wear_factor":1.0},
	{"id":"produce","name":"Fresh produce","rate":20.0,"equipment":"refrigerated","driver_endorsement":"cold_chain","wear_factor":1.0},
	{"id":"building","name":"Building supplies","rate":15.0,"equipment":"flatbed","wear_factor":1.2},
	{"id":"machinery","name":"Industrial machinery","rate":28.0,"equipment":"machinery_platform","driver_endorsement":"heavy_haul","wear_factor":1.45},
	{"id":"hazmat","name":"Controlled chemicals","rate":34.0,"equipment":"hazmat","driver_endorsement":"hazmat","wear_factor":1.35},
	{"id":"granular","name":"Bulk aggregates","rate":18.0,"equipment":"tipper","wear_factor":1.3}
]
const DESTINATIONS := [
	{"name":"Stellenbosch","km":52,"hours":1.0},
	{"name":"Paarl","km":62,"hours":1.0},
	{"name":"Worcester","km":112,"hours":2.0},
	{"name":"Hermanus","km":120,"hours":2.0}
]
const CONTRACT_ROUTES := [
	{"destination":"Gqeberha","km":750,"hours":30.0,"cargo_id":"dry","cargo_name":"Packaged goods","units":20,"rate":38.0,"deadline_days":4},
	{"destination":"Bloemfontein","km":1000,"hours":40.0,"cargo_id":"building","cargo_name":"Building supplies","units":22,"rate":36.0,"deadline_days":5},
	{"destination":"Johannesburg","km":1400,"hours":56.0,"cargo_id":"dry","cargo_name":"Packaged goods","units":26,"rate":40.0,"deadline_days":6},
	{"destination":"Durban","km":1650,"hours":66.0,"cargo_id":"produce","cargo_name":"Fresh produce","units":18,"rate":44.0,"deadline_days":7}
]
const CONTRACT_BOND := 25000
const REPAIR_COST_PER_CONDITION := 850
const WEAR_PER_100_KM := 0.72
const TERMINAL_MARKET := [
	{"name":"Gqeberha","province":"Eastern Cape","km":750,"price":200000},
	{"name":"Bloemfontein","province":"Free State","km":1000,"price":260000},
	{"name":"Johannesburg","province":"Gauteng","km":1400,"price":350000},
	{"name":"Durban","province":"KwaZulu-Natal","km":1650,"price":320000}
]

var cash := STARTING_CASH
var fleet: Array = []
var drivers: Array = []
var trips: Array = []
var demand: Dictionary = {}
var jobs: Array = []
var contracts: Array = []
var owned_terminals: Array = [HOME]
var network_jobs: Array = []
var last_time := 21600.0
var selected_vehicle := 0
var selected_driver := 0
var selected_job := 0
var selected_contract := 0
var selected_network_job := 0
var accepted_contract_id := ""
var vehicle_offer := 0
var vehicle_offer_id := "van"
var driver_offer := 0
var terminal_offer := 0
var workshop_level := 0
var message := "Company ready. Buy a vehicle and hire a driver to begin."
var road_nodes: Dictionary = {}
var terminal_coordinates: Dictionary = {}


func _ready() -> void:
	_load_terminal_coordinates()
	_build_road_graph()


func _load_terminal_coordinates() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage1_terminals.json"))
	if not parsed is Array:
		return
	for terminal in parsed:
		var city := str(terminal.get("city", ""))
		if city != "":
			terminal_coordinates[city] = Vector2(float(terminal.get("lon", 0.0)), float(terminal.get("lat", 0.0)))


func _build_road_graph() -> void:
	road_nodes.clear()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage1_corridors.json"))
	if not parsed is Array:
		return
	for corridor in parsed:
		# Keep game distances on the established prototype network. The added
		# national-route strokes are map-only until sourced road geometry exists.
		if not ["N1", "N2", "N3", "N4"].has(str(corridor.get("name", ""))):
			continue
		var points: Array = corridor.get("points", [])
		for i in range(points.size() - 1):
			var a: Array = points[i]
			var b: Array = points[i + 1]
			var key_a := _road_key(float(a[0]), float(a[1]))
			var key_b := _road_key(float(b[0]), float(b[1]))
			_ensure_road_node(key_a, float(a[0]), float(a[1]))
			_ensure_road_node(key_b, float(b[0]), float(b[1]))
			var distance := _haversine_km(float(a[0]), float(a[1]), float(b[0]), float(b[1])) * 1.12
			_add_road_edge(key_a, key_b, distance, str(corridor.get("name", "Road")))
			_add_road_edge(key_b, key_a, distance, str(corridor.get("name", "Road")))


func _ensure_road_node(key: String, lon: float, lat: float) -> void:
	if not road_nodes.has(key):
		road_nodes[key] = {"lon":lon,"lat":lat,"edges":[]}


func _add_road_edge(from_key: String, to_key: String, distance_km: float, road_name: String) -> void:
	var node: Dictionary = road_nodes[from_key]
	var edges: Array = node.get("edges", [])
	for edge in edges:
		if str(edge.get("to", "")) == to_key:
			return
	edges.append({"to":to_key,"km":distance_km,"road":road_name})
	node["edges"] = edges
	road_nodes[from_key] = node


func _find_road_route(origin: String, destination: String) -> Dictionary:
	if not terminal_coordinates.has(origin) or not terminal_coordinates.has(destination) or road_nodes.is_empty():
		return {}
	var origin_point: Vector2 = terminal_coordinates[origin]
	var destination_point: Vector2 = terminal_coordinates[destination]
	var start_key := _nearest_road_node(origin_point)
	var end_key := _nearest_road_node(destination_point)
	if start_key == "" or end_key == "":
		return {}
	var distances: Dictionary = {start_key:0.0}
	var previous: Dictionary = {}
	var frontier: Array = [start_key]
	while not frontier.is_empty():
		var best_index := 0
		for i in range(1, frontier.size()):
			if float(distances.get(frontier[i], INF)) < float(distances.get(frontier[best_index], INF)):
				best_index = i
		var current := str(frontier.pop_at(best_index))
		if current == end_key:
			break
		var node: Dictionary = road_nodes[current]
		for edge in node.get("edges", []):
			var neighbor := str(edge["to"])
			var candidate := float(distances[current]) + float(edge["km"])
			if candidate >= float(distances.get(neighbor, INF)):
				continue
			distances[neighbor] = candidate
			previous[neighbor] = current
			if not frontier.has(neighbor):
				frontier.append(neighbor)
	if not distances.has(end_key):
		return {}
	var reversed_points: Array = []
	var cursor := end_key
	while cursor != "":
		var node: Dictionary = road_nodes[cursor]
		reversed_points.append([float(node["lon"]), float(node["lat"])])
		if cursor == start_key:
			break
		cursor = str(previous.get(cursor, ""))
	reversed_points.reverse()
	var connector_km := _haversine_km(origin_point.x, origin_point.y, float(road_nodes[start_key]["lon"]), float(road_nodes[start_key]["lat"]))
	connector_km += _haversine_km(destination_point.x, destination_point.y, float(road_nodes[end_key]["lon"]), float(road_nodes[end_key]["lat"]))
	if _haversine_km(origin_point.x, origin_point.y, float(reversed_points[0][0]), float(reversed_points[0][1])) > 0.1:
		reversed_points.push_front([origin_point.x, origin_point.y])
	if _haversine_km(destination_point.x, destination_point.y, float(reversed_points[reversed_points.size() - 1][0]), float(reversed_points[reversed_points.size() - 1][1])) > 0.1:
		reversed_points.append([destination_point.x, destination_point.y])
	return {"km":float(distances[end_key]) + connector_km * 1.12,"points":reversed_points}


func _nearest_road_node(point: Vector2) -> String:
	var nearest := ""
	var best_distance := INF
	for key in road_nodes:
		var node: Dictionary = road_nodes[key]
		var distance := _haversine_km(point.x, point.y, float(node["lon"]), float(node["lat"]))
		if distance < best_distance:
			best_distance = distance
			nearest = str(key)
	return nearest


func _road_key(lon: float, lat: float) -> String:
	return "%.4f,%.4f" % [lon, lat]


func _haversine_km(lon_a: float, lat_a: float, lon_b: float, lat_b: float) -> float:
	var lat_delta := deg_to_rad(lat_b - lat_a)
	var lon_delta := deg_to_rad(lon_b - lon_a)
	var a := pow(sin(lat_delta * 0.5), 2.0) + cos(deg_to_rad(lat_a)) * cos(deg_to_rad(lat_b)) * pow(sin(lon_delta * 0.5), 2.0)
	return 6371.0 * 2.0 * atan2(sqrt(a), sqrt(maxf(0.0, 1.0 - a)))


func start_new_game(game_time: float) -> void:
	cash = STARTING_CASH
	fleet.clear()
	drivers.clear()
	trips.clear()
	demand.clear()
	contracts.clear()
	owned_terminals = [HOME]
	network_jobs.clear()
	selected_vehicle = 0
	selected_driver = 0
	selected_job = 0
	selected_contract = 0
	selected_network_job = 0
	accepted_contract_id = ""
	vehicle_offer = 0
	vehicle_offer_id = "van"
	driver_offer = 0
	terminal_offer = 0
	workshop_level = 0
	last_time = game_time
	_reset_demand(int(floor(game_time / DAY_SECONDS)))
	_set_message("New Cape Town company opened with R1,250,000 in starting funds.")


func load_state(state: Dictionary, game_time: float) -> void:
	cash = int(state.get("cash", STARTING_CASH))
	fleet = state.get("fleet", [])
	for vehicle in fleet:
		vehicle["condition"] = clampf(float(vehicle.get("condition", 100.0)), 0.0, 100.0)
		if not vehicle.has("equipment"):
			vehicle["equipment"] = _infer_legacy_equipment(vehicle)
		if not vehicle.has("class"):
			vehicle["class"] = "reefer" if vehicle.get("equipment", []).has("refrigerated") else ("van" if int(vehicle.get("capacity", 0)) <= 8 else "rigid")
		if not vehicle.has("energy_type"):
			vehicle["energy_type"] = "petrol" if str(vehicle.get("class", "")) == "van" else "diesel"
		if not vehicle.has("energy_use_per_100km"):
			vehicle["energy_use_per_100km"] = 10.0 if str(vehicle.get("energy_type", "diesel")) == "petrol" else 27.0
		vehicle["odometer_km"] = maxi(0, int(vehicle.get("odometer_km", 0)))
		vehicle["inspection_due_km"] = maxi(INSPECTION_INTERVAL_KM, int(vehicle.get("inspection_due_km", INSPECTION_INTERVAL_KM)))
		vehicle["inspection_due"] = int(vehicle["odometer_km"]) >= int(vehicle["inspection_due_km"])
	drivers = state.get("drivers", [])
	for driver in drivers:
		if not driver.has("endorsements"):
			driver["endorsements"] = ["general"]
	trips = state.get("trips", [])
	demand = state.get("demand", {})
	contracts = state.get("contracts", [])
	owned_terminals = state.get("owned_terminals", [HOME])
	if not owned_terminals.has(HOME):
		owned_terminals.push_front(HOME)
	network_jobs = []
	selected_vehicle = int(state.get("selected_vehicle", 0))
	selected_driver = int(state.get("selected_driver", 0))
	selected_job = int(state.get("selected_job", 0))
	selected_contract = int(state.get("selected_contract", 0))
	selected_network_job = int(state.get("selected_network_job", 0))
	accepted_contract_id = str(state.get("accepted_contract_id", ""))
	vehicle_offer = int(state.get("vehicle_offer", 0))
	vehicle_offer_id = str(state.get("vehicle_offer_id", ""))
	if vehicle_offer_id == "":
		var old_offer_index := posmod(vehicle_offer, LEGACY_VEHICLE_OFFER_IDS.size())
		vehicle_offer_id = str(LEGACY_VEHICLE_OFFER_IDS[old_offer_index])
	vehicle_offer = _vehicle_index_for_id(vehicle_offer_id)
	vehicle_offer_id = str(VEHICLES[vehicle_offer].get("id", "van"))
	driver_offer = int(state.get("driver_offer", 0))
	terminal_offer = int(state.get("terminal_offer", 0))
	workshop_level = clampi(int(state.get("workshop_level", 1 if bool(state.get("workshop_upgrade", false)) else 0)), 0, 2)
	last_time = float(state.get("last_time", game_time))
	_build_jobs(int(floor(game_time / DAY_SECONDS)))
	_build_contract_offers(int(floor(game_time / DAY_SECONDS)))
	_build_network_jobs(int(floor(game_time / DAY_SECONDS)))
	for trip in trips:
		if str(trip.get("status", "")) != "in_transit" or (trip.get("route_points", []) as Array).size() >= 2:
			continue
		var route_info := _find_road_route(HOME, str(trip.get("destination", "")))
		if route_info.is_empty():
			continue
		trip["route_points"] = route_info["points"]
		trip["route_km"] = int(round(float(route_info["km"])))
		var arrival := float(trip.get("arrival", game_time))
		trip["start_time"] = arrival - float(trip["route_km"]) / 45.0 * 2.0 * 3600.0
	for contract in contracts:
		if str(contract.get("status", "")) == "offer":
			continue
		if (contract.get("route_points", []) as Array).size() >= 2:
			continue
		var route_info := _find_road_route(HOME, str(contract.get("destination", "")))
		if not route_info.is_empty():
			contract["route_points"] = route_info["points"]
	advance_to(game_time)
	_set_message("Company progress loaded from this device.")


func snapshot() -> Dictionary:
	return {"cash":cash,"fleet":fleet.duplicate(true),"drivers":drivers.duplicate(true),"trips":trips.duplicate(true),"demand":demand.duplicate(true),"contracts":contracts.duplicate(true),"owned_terminals":owned_terminals.duplicate(true),"selected_vehicle":selected_vehicle,"selected_driver":selected_driver,"selected_job":selected_job,"selected_contract":selected_contract,"selected_network_job":selected_network_job,"accepted_contract_id":accepted_contract_id,"vehicle_offer":vehicle_offer,"vehicle_offer_id":vehicle_offer_id,"driver_offer":driver_offer,"terminal_offer":terminal_offer,"workshop_level":workshop_level,"last_time":last_time}


func advance_to(game_time: float) -> void:
	if game_time <= last_time:
		return
	var boundary: float = (floor(last_time / DAY_SECONDS) + 1.0) * DAY_SECONDS
	while boundary <= game_time:
		_complete_until(boundary)
		_expire_unstarted_contract(boundary)
		var wages := 0
		for driver in drivers:
			wages += int(driver.get("wage", 0))
		cash -= wages
		if wages > 0:
			_set_message("Daily driver wages paid: R%s." % commas(wages))
		_reset_demand(int(floor(boundary / DAY_SECONDS)))
		_build_contract_offers(int(floor(boundary / DAY_SECONDS)))
		_build_network_jobs(int(floor(boundary / DAY_SECONDS)))
		boundary += DAY_SECONDS
	_complete_until(game_time)
	_expire_unstarted_contract(game_time)
	last_time = game_time


func _complete_until(game_time: float) -> void:
	for trip in trips:
		if str(trip.get("status", "")) != "in_transit" or float(trip.get("arrival", 0.0)) > game_time:
			continue
		var paid := int(trip.get("revenue", 0))
		if str(trip.get("contract_id", "")) != "":
			var completion_time := float(trip.get("arrival", game_time))
			var on_time := completion_time <= float(trip.get("deadline", game_time))
			if on_time:
				cash += int(trip.get("bond", 0))
			else:
				paid = int(float(paid) * 0.75)
			cash += paid
			for contract in contracts:
				if str(contract.get("id", "")) == str(trip.get("contract_id", "")):
					contract["status"] = "completed"
					contract["result"] = "on time" if on_time else "late"
			trip["result"] = "on time" if on_time else "late"
			accepted_contract_id = ""
		else:
			cash += paid
		trip["status"] = "returned"
		for vehicle in fleet:
			if str(vehicle.get("id", "")) == str(trip.get("vehicle_id", "")):
				vehicle["condition"] = clampf(float(vehicle.get("condition", 100.0)) - float(trip.get("wear", 0.0)), 0.0, 100.0)
				vehicle["odometer_km"] = int(vehicle.get("odometer_km", 0)) + int(round(float(trip.get("route_km", 0)) * 2.0))
				vehicle["inspection_due"] = int(vehicle["odometer_km"]) >= int(vehicle.get("inspection_due_km", INSPECTION_INTERVAL_KM))
				vehicle["status"] = "available"
				vehicle["driver_id"] = ""
				vehicle["location"] = HOME
		for driver in drivers:
			if str(driver.get("id", "")) == str(trip.get("driver_id", "")):
				driver["status"] = "available"
		if str(trip.get("contract_id", "")) != "":
			var result_text := "on time; bond returned" if str(trip.get("result", "")) == "on time" else "late; bond forfeited"
			_set_message("Contract returned from %s %s. R%s received.%s" % [trip.get("destination", "long haul"), result_text, commas(paid), _trip_incident_result(trip)])
		else:
			_set_message("Delivery returned from %s. R%s received.%s" % [trip.get("destination", "local market"), commas(paid), _trip_incident_result(trip)])


func _expire_unstarted_contract(game_time: float) -> void:
	if accepted_contract_id == "":
		return
	var contract := _contract_by_id(accepted_contract_id)
	if contract.is_empty() or str(contract.get("status", "")) != "accepted":
		return
	if game_time <= float(contract.get("deadline", game_time)):
		return
	contract["status"] = "failed"
	contract["result"] = "not dispatched before deadline"
	accepted_contract_id = ""
	_set_message("The %s contract expired before dispatch. Its held performance bond was forfeited." % contract.get("destination", "long-haul"))


func _reset_demand(day_index: int) -> void:
	demand.clear()
	for destination in DESTINATIONS:
		for cargo in CARGO:
			var key := _key(str(destination["name"]), str(cargo["id"]))
			demand[key] = 3 + int(abs(hash(key + str(day_index))) % 7)
	_build_jobs(day_index)
	_build_contract_offers(day_index)
	_build_network_jobs(day_index)


func _build_contract_offers(day_index: int) -> void:
	contracts = contracts.filter(func(contract: Dictionary) -> bool: return str(contract.get("status", "offer")) != "offer")
	for route in CONTRACT_ROUTES:
		var contract_id := "contract_%d_%s" % [day_index, str(route["destination"]).to_lower()]
		var exists := false
		for contract in contracts:
			if str(contract.get("id", "")) == contract_id:
				exists = true
				break
		if exists:
			continue
		var units := int(route["units"])
		var route_info := _find_road_route(HOME, str(route["destination"]))
		var route_km := int(round(float(route_info.get("km", route["km"]))))
		contracts.append({"id":contract_id,"day":day_index,"origin":HOME,"destination":route["destination"],"km":route_km,"hours":float(route_km) / 45.0,"route_points":route_info.get("points", []),"cargo_id":route["cargo_id"],"cargo_name":route["cargo_name"],"units":units,"revenue":int(route_km * float(route["rate"]) * units),"deadline":float(day_index * DAY_SECONDS + int(route["deadline_days"]) * DAY_SECONDS),"status":"offer"})
	if not contracts.is_empty():
		selected_contract = posmod(selected_contract, maxi(1, _offered_contracts().size()))


func _build_network_jobs(day_index: int) -> void:
	network_jobs.clear()
	for terminal in TERMINAL_MARKET:
		var destination := str(terminal["name"])
		if not owned_terminals.has(destination):
			continue
		for cargo in CARGO:
			var key := _network_key(destination, str(cargo["id"]))
			if not demand.has(key):
				demand[key] = 4 + int(abs(hash(key + str(day_index))) % 6)
			var available := int(demand.get(key, 0))
			if available <= 0:
				continue
			var route_info := _find_road_route(HOME, destination)
			var route_km := int(round(float(route_info.get("km", terminal["km"]))))
			network_jobs.append({"id":key,"destination":destination,"km":route_km,"hours":float(route_km) / 45.0,"route_points":route_info.get("points", []),"cargo_id":cargo["id"],"cargo_name":cargo["name"],"rate":float(cargo["rate"]) + 4.0,"demand":available})
	if not network_jobs.is_empty():
		selected_network_job = posmod(selected_network_job, network_jobs.size())


func _build_jobs(day_index: int) -> void:
	if demand.is_empty():
		_reset_demand(day_index)
		return
	jobs.clear()
	for destination in DESTINATIONS:
		for cargo in CARGO:
			var key := _key(str(destination["name"]), str(cargo["id"]))
			var available := int(demand.get(key, 0))
			if available <= 0:
				continue
			jobs.append({"id":key,"destination":destination["name"],"km":int(destination["km"]),"hours":float(destination["hours"]),"cargo_id":cargo["id"],"cargo_name":cargo["name"],"rate":float(cargo["rate"]),"demand":available})
	if not jobs.is_empty():
		selected_job = posmod(selected_job, jobs.size())


func buy_vehicle() -> void:
	var definition: Dictionary = VEHICLES[vehicle_offer]
	var price := int(definition["price"])
	if cash < price:
		_set_message("Not enough cash. %s costs R%s." % [definition["name"], commas(price)])
		return
	cash -= price
	fleet.append({"id":"vehicle_%d" % (fleet.size()+1),"name":definition["name"],"class":definition.get("class", "rigid"),"price":price,"capacity":definition["capacity"],"km_cost":definition["km_cost"],"energy_type":definition.get("energy_type", "diesel"),"energy_use_per_100km":definition.get("energy_use_per_100km", 27.0),"equipment":definition.get("equipment", ["standard"]).duplicate(),"cargo":definition["cargo"].duplicate(),"condition":100.0,"odometer_km":0,"inspection_due_km":INSPECTION_INTERVAL_KM,"inspection_due":false,"status":"available","driver_id":"","location":HOME})
	selected_vehicle = fleet.size() - 1
	vehicle_offer = (vehicle_offer + 1) % VEHICLES.size()
	vehicle_offer_id = str(VEHICLES[vehicle_offer]["id"])
	_set_message("Purchased %s for R%s." % [definition["name"], commas(price)])


func _vehicle_index_for_id(vehicle_id: String) -> int:
	for index in range(VEHICLES.size()):
		if str(VEHICLES[index].get("id", "")) == vehicle_id:
			return index
	return 0


func buy_terminal() -> void:
	var terminal := _next_terminal()
	if terminal.is_empty():
		_set_message("Your company already owns all four remote terminals in this prototype.")
		return
	var price := int(terminal["price"])
	if cash < price:
		_set_message("Not enough cash. The %s terminal costs R%s." % [terminal["name"], commas(price)])
		return
	cash -= price
	owned_terminals.append(str(terminal["name"]))
	terminal_offer = (TERMINAL_MARKET.find(terminal) + 1) % TERMINAL_MARKET.size()
	_build_network_jobs(int(floor(last_time / DAY_SECONDS)))
	_set_message("Opened your %s terminal. Line-haul jobs are now available." % terminal["name"])


func cycle_terminal_offer() -> void:
	if owned_terminals.size() >= TERMINAL_MARKET.size() + 1:
		_set_message("All remote terminals are already owned.")
		return
	terminal_offer = (terminal_offer + 1) % TERMINAL_MARKET.size()
	_set_message("Terminal market selection: %s." % _next_terminal().get("name", "none"))


func _next_terminal() -> Dictionary:
	for offset in range(TERMINAL_MARKET.size()):
		var index := posmod(terminal_offer + offset, TERMINAL_MARKET.size())
		var candidate: Dictionary = TERMINAL_MARKET[index]
		if not owned_terminals.has(str(candidate["name"])):
			return candidate
	return {}


func next_terminal_label() -> String:
	var terminal := _next_terminal()
	if terminal.is_empty():
		return "All remote terminals owned"
	return "%s • R%s" % [terminal["name"], commas(int(terminal["price"]))]


func owned_terminal_summary() -> String:
	return "Owned terminals (%d): %s" % [owned_terminals.size(), ", ".join(owned_terminals)]


func hire_driver() -> void:
	var definition: Dictionary = DRIVERS[driver_offer]
	drivers.append({"id":"driver_%d" % (drivers.size()+1),"name":definition["name"],"wage":definition["wage"],"endorsements":definition.get("endorsements", ["general"]).duplicate(),"status":"available"})
	selected_driver = drivers.size() - 1
	driver_offer = (driver_offer + 1) % DRIVERS.size()
	_set_message("Hired %s at R%s per game day." % [definition["name"], commas(int(definition["wage"]))])


func cycle_vehicle() -> void:
	if fleet.is_empty():
		_set_message("Buy a vehicle before selecting one.")
		return
	selected_vehicle = (selected_vehicle + 1) % fleet.size()
	_set_message("Selected %s." % fleet[selected_vehicle]["name"])


func repair_selected_vehicle() -> void:
	if fleet.is_empty():
		_set_message("Buy a vehicle before scheduling maintenance.")
		return
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	var vehicle: Dictionary = fleet[selected_vehicle]
	if str(vehicle.get("status", "")) != "available":
		_set_message("A vehicle must return before it can be repaired.")
		return
	var condition := clampf(float(vehicle.get("condition", 100.0)), 0.0, 100.0)
	var missing := 100.0 - condition
	var needs_inspection := _inspection_due(vehicle)
	var repair_rate := _repair_rate()
	var repair_cost := int(ceil(missing * repair_rate))
	var inspection_cost := INSPECTION_COST if needs_inspection else 0
	var cost := repair_cost + inspection_cost
	if cost <= 0:
		_set_message("%s is in good condition and its inspection is up to date." % vehicle.get("name", "Vehicle"))
		return
	if cash < cost:
		_set_message("Service needs R%s, but your company has insufficient cash." % commas(cost))
		return
	cash -= cost
	vehicle["condition"] = 100.0
	if needs_inspection:
		var next_inspection := int(vehicle.get("inspection_due_km", INSPECTION_INTERVAL_KM))
		while next_inspection <= int(vehicle.get("odometer_km", 0)):
			next_inspection += INSPECTION_INTERVAL_KM
		vehicle["inspection_due_km"] = next_inspection
		vehicle["inspection_due"] = false
	_set_message("%s serviced to 100%% condition%s for R%s." % [vehicle.get("name", "Vehicle"), " and passed its inspection" if needs_inspection else "", commas(cost)])


func buy_workshop_upgrade() -> void:
	if workshop_level >= 2:
		_set_message("Workshop expansion is already active. Service repairs are 35%% cheaper.")
		return
	var price := WORKSHOP_UPGRADE_COST if workshop_level == 0 else WORKSHOP_EXPANSION_COST
	if cash < price:
		_set_message("Workshop upgrade costs R%s; your company needs more cash." % commas(price))
		return
	cash -= price
	workshop_level += 1
	var discount := int(round(_repair_discount() * 100.0))
	_set_message("Workshop upgraded for R%s. Vehicle repair costs are now %d%% lower." % [commas(price), discount])


func cycle_driver() -> void:
	if drivers.is_empty():
		_set_message("Hire a driver before selecting one.")
		return
	selected_driver = (selected_driver + 1) % drivers.size()
	_set_message("Selected driver: %s." % drivers[selected_driver]["name"])


func cycle_job() -> void:
	_build_jobs(int(floor(last_time / DAY_SECONDS)))
	if jobs.is_empty():
		_set_message("No local cargo demand remains today.")
		return
	selected_job = (selected_job + 1) % jobs.size()
	_set_message("Selected %s to %s." % [jobs[selected_job]["cargo_name"], jobs[selected_job]["destination"]])


func cycle_network_job() -> void:
	_build_network_jobs(int(floor(last_time / DAY_SECONDS)))
	if network_jobs.is_empty():
		_set_message("Buy a remote terminal to unlock line-haul jobs.")
		return
	selected_network_job = (selected_network_job + 1) % network_jobs.size()
	_set_message("Selected line haul to %s." % network_jobs[selected_network_job]["destination"])


func network_job_label() -> String:
	_build_network_jobs(int(floor(last_time / DAY_SECONDS)))
	if network_jobs.is_empty():
		return "Buy a remote terminal to unlock line-haul jobs."
	selected_network_job = posmod(selected_network_job, network_jobs.size())
	var job: Dictionary = network_jobs[selected_network_job]
	var units := mini(int(job["demand"]), int(fleet[selected_vehicle]["capacity"])) if not fleet.is_empty() else int(job["demand"])
	var revenue := int(300 + int(job["km"]) * float(job["rate"]) * units)
	return "Cape Town → %s • %d km\n%s • %d units • Est. R%s • Need: %s" % [job["destination"], int(job["km"]), job["cargo_name"], units, commas(revenue), _cargo_equipment_label(str(job["cargo_id"]))]


func network_cost_label() -> String:
	_build_network_jobs(int(floor(last_time / DAY_SECONDS)))
	if network_jobs.is_empty():
		return "Buy a remote terminal to see line-haul costs."
	if fleet.is_empty():
		return "Trip cost depends on the truck you assign."
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	selected_network_job = posmod(selected_network_job, network_jobs.size())
	var job: Dictionary = network_jobs[selected_network_job]
	var vehicle: Dictionary = fleet[selected_vehicle]
	return "Round-trip cost R%s • %s" % [commas(_trip_expense(vehicle, int(job["km"]) * 2, 100)), energy_label(vehicle)]


func dispatch_network(game_time: float) -> void:
	_build_network_jobs(int(floor(game_time / DAY_SECONDS)))
	if fleet.is_empty() or drivers.is_empty():
		_set_message("Buy a vehicle and hire a driver before dispatching.")
		return
	if network_jobs.is_empty():
		_set_message("Buy a remote terminal to unlock line-haul jobs.")
		return
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	selected_driver = posmod(selected_driver, drivers.size())
	selected_network_job = posmod(selected_network_job, network_jobs.size())
	var vehicle: Dictionary = fleet[selected_vehicle]
	var driver: Dictionary = drivers[selected_driver]
	var job: Dictionary = network_jobs[selected_network_job]
	if vehicle.get("status", "") != "available" or driver.get("status", "") != "available":
		_set_message("Choose an available vehicle and driver.")
		return
	if _inspection_due(vehicle):
		_set_message("%s needs an inspection before it can be dispatched." % vehicle.get("name", "This vehicle"))
		return
	if not _vehicle_can_carry(vehicle, str(job["cargo_id"])):
		_set_message(_cargo_incompatibility_message(vehicle, str(job["cargo_id"])))
		return
	if not _driver_can_carry(driver, str(job["cargo_id"])):
		_set_message(_driver_incompatibility_message(driver, str(job["cargo_id"])))
		return
	var units := mini(int(job["demand"]), int(vehicle["capacity"]))
	var revenue := int(300 + int(job["km"]) * float(job["rate"]) * units)
	var expense := _trip_expense(vehicle, int(job["km"]) * 2, 100)
	if cash < expense:
		_set_message("Insufficient cash for estimated R%s line-haul costs." % commas(expense))
		return
	var vehicle_id := str(vehicle["id"])
	var driver_id := str(driver["id"])
	var duration := maxf(2.0, float(job["hours"]) * 2.0)
	var planned_arrival := game_time + duration * 3600.0
	var incident := _roll_trip_incident(vehicle, int(job["km"]), planned_arrival)
	incident = _fit_incident_to_cash(incident, expense, cash, planned_arrival)
	var trip := {"id":"trip_%d" % (trips.size()+1),"vehicle_id":vehicle_id,"driver_id":driver_id,"destination":job["destination"],"cargo_id":job["cargo_id"],"cargo_name":job["cargo_name"],"revenue":revenue,"start_time":game_time,"arrival":planned_arrival + float(incident.get("delay_hours", 0.0)) * 3600.0,"route_km":job["km"],"wear":_trip_wear(int(job["km"]), units, int(vehicle["capacity"]), str(job["cargo_id"])) + float(incident.get("extra_wear", 0.0)),"route_points":job.get("route_points", []).duplicate(true),"operation_type":"linehaul","status":"in_transit"}
	_store_trip_incident(trip, incident)
	trips.append(trip)
	vehicle["status"] = "in_transit"
	vehicle["driver_id"] = driver_id
	vehicle["location"] = str(job["destination"])
	driver["status"] = "in_transit"
	cash -= expense + int(incident.get("cost", 0))
	var key := str(job["id"])
	demand[key] = maxi(0, int(demand.get(key, 0)) - units)
	_build_network_jobs(int(floor(game_time / DAY_SECONDS)))
	_set_message(_incident_dispatch_message(incident, "Line haul dispatched to %s: R%s expected return payment." % [job["destination"], commas(revenue)]))


func dispatch(game_time: float) -> void:
	_build_jobs(int(floor(game_time / DAY_SECONDS)))
	if fleet.is_empty() or drivers.is_empty():
		_set_message("Buy a vehicle and hire a driver before dispatching.")
		return
	if jobs.is_empty():
		_set_message("No local jobs are available today.")
		return
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	selected_driver = posmod(selected_driver, drivers.size())
	selected_job = posmod(selected_job, jobs.size())
	var vehicle: Dictionary = fleet[selected_vehicle]
	var driver: Dictionary = drivers[selected_driver]
	var job: Dictionary = jobs[selected_job]
	if vehicle["status"] != "available" or driver["status"] != "available":
		_set_message("Choose an available vehicle and driver.")
		return
	if _inspection_due(vehicle):
		_set_message("%s needs an inspection before it can be dispatched." % vehicle.get("name", "This vehicle"))
		return
	if not _vehicle_can_carry(vehicle, str(job["cargo_id"])):
		_set_message(_cargo_incompatibility_message(vehicle, str(job["cargo_id"])))
		return
	if not _driver_can_carry(driver, str(job["cargo_id"])):
		_set_message(_driver_incompatibility_message(driver, str(job["cargo_id"])))
		return
	var units := mini(int(job["demand"]), int(vehicle["capacity"]))
	var km := int(job["km"])
	var revenue := int(500 + km * float(job["rate"]) * units)
	var expense := _trip_expense(vehicle, km * 2, 100)
	if cash < expense:
		_set_message("Insufficient cash for estimated R%s trip costs." % commas(expense))
		return
	var duration := maxf(2.0, float(job["hours"]) * 2.0)
	var driver_id := str(driver["id"])
	var vehicle_id := str(vehicle["id"])
	var planned_arrival := game_time + duration * 3600.0
	var incident := _roll_trip_incident(vehicle, km, planned_arrival)
	incident = _fit_incident_to_cash(incident, expense, cash, planned_arrival)
	var trip := {"id":"trip_%d" % (trips.size()+1),"vehicle_id":vehicle_id,"driver_id":driver_id,"destination":job["destination"],"cargo_id":job["cargo_id"],"cargo_name":job["cargo_name"],"revenue":revenue,"arrival":planned_arrival + float(incident.get("delay_hours", 0.0)) * 3600.0,"route_km":km,"wear":_trip_wear(km, units, int(vehicle["capacity"]), str(job["cargo_id"])) + float(incident.get("extra_wear", 0.0)),"operation_type":"local","status":"in_transit"}
	_store_trip_incident(trip, incident)
	trips.append(trip)
	vehicle["status"] = "in_transit"
	vehicle["driver_id"] = driver_id
	vehicle["location"] = str(job["destination"])
	driver["status"] = "in_transit"
	cash -= expense + int(incident.get("cost", 0))
	var key := str(job["id"])
	demand[key] = maxi(0, int(demand.get(key, 0)) - units)
	_build_jobs(int(floor(game_time / DAY_SECONDS)))
	_set_message(_incident_dispatch_message(incident, "Dispatched to %s: R%s expected revenue, %s game hours round trip." % [job["destination"], commas(revenue), str(int(duration))]))


func cycle_contract() -> void:
	if accepted_contract_id != "":
		_set_message("Finish your accepted contract before selecting another offer.")
		return
	var offers := _offered_contracts()
	if offers.is_empty():
		_set_message("No long-haul offers are available today.")
		return
	selected_contract = (selected_contract + 1) % offers.size()
	_set_message("Selected long-haul contract to %s." % offers[selected_contract]["destination"])


func bid_contract() -> void:
	var contract := _selected_offer()
	if contract.is_empty():
		_set_message("Select an available contract offer first.")
		return
	if accepted_contract_id != "":
		_set_message("Complete your current contract before accepting another.")
		return
	if cash < CONTRACT_BOND:
		_set_message("A R%s performance bond is required." % commas(CONTRACT_BOND))
		return
	cash -= CONTRACT_BOND
	contract["status"] = "accepted"
	contract["bond"] = CONTRACT_BOND
	accepted_contract_id = str(contract["id"])
	_set_message("Contract accepted: %s to %s. R%s bond held until return." % [contract["cargo_name"], contract["destination"], commas(CONTRACT_BOND)])


func dispatch_contract(game_time: float) -> void:
	var contract := _contract_by_id(accepted_contract_id)
	if contract.is_empty():
		_set_message("Accept a contract before dispatching long haul.")
		return
	if game_time > float(contract.get("deadline", game_time)):
		contract["status"] = "failed"
		contract["result"] = "not dispatched before deadline"
		accepted_contract_id = ""
		_set_message("The %s contract expired before dispatch. Its held performance bond was forfeited." % contract.get("destination", "long-haul"))
		return
	if fleet.is_empty() or drivers.is_empty():
		_set_message("Buy a vehicle and hire a driver before dispatching.")
		return
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	selected_driver = posmod(selected_driver, drivers.size())
	var vehicle: Dictionary = fleet[selected_vehicle]
	var driver: Dictionary = drivers[selected_driver]
	if vehicle.get("status", "") != "available" or driver.get("status", "") != "available":
		_set_message("Choose an available vehicle and driver.")
		return
	if _inspection_due(vehicle):
		_set_message("%s needs an inspection before it can be dispatched." % vehicle.get("name", "This vehicle"))
		return
	if not _vehicle_can_carry(vehicle, str(contract.get("cargo_id", "dry"))) or int(vehicle.get("capacity", 0)) < int(contract.get("units", 0)):
		if not _vehicle_can_carry(vehicle, str(contract.get("cargo_id", "dry"))):
			_set_message(_cargo_incompatibility_message(vehicle, str(contract.get("cargo_id", "dry"))))
			return
		_set_message("This contract needs a compatible vehicle with at least %s units of capacity." % contract.get("units", 0))
		return
	if not _driver_can_carry(driver, str(contract.get("cargo_id", "dry"))):
		_set_message(_driver_incompatibility_message(driver, str(contract.get("cargo_id", "dry"))))
		return
	var expense := _trip_expense(vehicle, int(contract["km"]) * 2, 1000)
	if cash < expense:
		_set_message("Insufficient cash for estimated R%s long-haul costs." % commas(expense))
		return
	var vehicle_id := str(vehicle["id"])
	var driver_id := str(driver["id"])
	var planned_arrival := game_time + float(contract["hours"]) * 2.0 * 3600.0
	var contract_deadline := float(contract["deadline"])
	var incident := _roll_trip_incident(vehicle, int(contract["km"]), planned_arrival, contract_deadline)
	incident = _fit_incident_to_cash(incident, expense, cash, planned_arrival, contract_deadline)
	var total_expense := expense + int(incident.get("cost", 0))
	var trip := {"id":"trip_%d" % (trips.size()+1),"vehicle_id":vehicle_id,"driver_id":driver_id,"destination":contract["destination"],"cargo_id":contract.get("cargo_id", "dry"),"cargo_name":contract["cargo_name"],"revenue":int(contract["revenue"]),"arrival":planned_arrival + float(incident.get("delay_hours", 0.0)) * 3600.0,"start_time":game_time,"route_km":contract["km"],"wear":_trip_wear(int(contract["km"]), int(contract["units"]), int(vehicle["capacity"]), str(contract.get("cargo_id", "dry"))) + float(incident.get("extra_wear", 0.0)),"route_points":contract.get("route_points", []).duplicate(true),"deadline":contract_deadline,"contract_id":contract["id"],"bond":int(contract.get("bond", 0)),"cost":total_expense,"operation_type":"contract","status":"in_transit"}
	_store_trip_incident(trip, incident)
	trips.append(trip)
	contract["status"] = "in_transit"
	vehicle["status"] = "in_transit"
	vehicle["driver_id"] = driver_id
	vehicle["location"] = str(contract["destination"])
	driver["status"] = "in_transit"
	cash -= total_expense
	_set_message(_incident_dispatch_message(incident, "Long haul dispatched to %s: R%s contract value, %d km one way." % [contract["destination"], commas(int(contract["revenue"])), int(contract["km"])]))


func contract_label() -> String:
	var contract := _contract_by_id(accepted_contract_id) if accepted_contract_id != "" else _selected_offer()
	if contract.is_empty():
		return "No contract offers available."
	return "%s → %s • %d km\n%s • %d units • R%s • %s • Need: %s" % [contract.get("origin", HOME), contract["destination"], int(contract["km"]), contract["cargo_name"], int(contract["units"]), commas(int(contract["revenue"])), str(contract.get("status", "offer")).to_upper(), _cargo_equipment_label(str(contract.get("cargo_id", "dry")))]


func contract_deadline_label() -> String:
	var contract := _contract_by_id(accepted_contract_id) if accepted_contract_id != "" else _selected_offer()
	if contract.is_empty():
		return ""
	var days_left := (float(contract["deadline"]) - SimulationClock.game_time_seconds) / DAY_SECONDS
	var return_days := float(contract.get("hours", 0.0)) * 2.0 / 24.0
	var trip_cost := -1
	if accepted_contract_id != "":
		for trip in trips:
			if str(trip.get("contract_id", "")) == accepted_contract_id and str(trip.get("status", "")) == "in_transit":
				return_days = (float(trip.get("arrival", SimulationClock.game_time_seconds)) - SimulationClock.game_time_seconds) / DAY_SECONDS
				trip_cost = int(trip.get("cost", -1))
				break
	var buffer_days := days_left - return_days
	var buffer_label := "+%.1f" % buffer_days if buffer_days >= 0.0 else "%.1f" % buffer_days
	var cost := trip_cost
	if not fleet.is_empty():
		selected_vehicle = posmod(selected_vehicle, fleet.size())
		var vehicle: Dictionary = fleet[selected_vehicle]
		if cost < 0:
			cost = _trip_expense(vehicle, int(contract["km"]) * 2, 1000)
	var cost_label := "Trip cost needs an eligible truck"
	if cost >= 0:
		cost_label = "Trip cost R%s" % commas(cost)
	return "Return ETA %.1f days • Deadline %.1f days • Buffer %s days\nBond R%s • %s" % [maxf(0.0, return_days), maxf(0.0, days_left), buffer_label, commas(int(contract.get("bond", CONTRACT_BOND))), cost_label]


func contract_action_label() -> String:
	return "DISPATCH ACCEPTED CONTRACT" if accepted_contract_id != "" else "ACCEPT SELECTED CONTRACT"


func _offered_contracts() -> Array:
	var result: Array = []
	for contract in contracts:
		if str(contract.get("status", "")) == "offer":
			result.append(contract)
	return result


func _selected_offer() -> Dictionary:
	var offers := _offered_contracts()
	if offers.is_empty():
		return {}
	selected_contract = posmod(selected_contract, offers.size())
	return offers[selected_contract]


func _contract_by_id(contract_id: String) -> Dictionary:
	for contract in contracts:
		if str(contract.get("id", "")) == contract_id:
			return contract
	return {}


func vehicle_label() -> String:
	if fleet.is_empty():
		return "No vehicles yet"
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	var item: Dictionary = fleet[selected_vehicle]
	return "%s • %s • %d units" % [item["name"], str(item["status"]).capitalize(), int(item["capacity"])]


func vehicle_condition_label() -> String:
	if fleet.is_empty():
		return "Condition — • Odometer —"
	var item: Dictionary = fleet[posmod(selected_vehicle, fleet.size())]
	var odometer := int(item.get("odometer_km", 0))
	var inspection_at := int(item.get("inspection_due_km", INSPECTION_INTERVAL_KM))
	var status := " • INSPECTION DUE" if _inspection_due(item) else ""
	return "Condition %.0f%% • %s • Odo %s/%s km%s" % [float(item.get("condition", 100.0)), energy_label(item), commas(odometer), commas(inspection_at), status]


func _vehicle_can_carry(vehicle: Dictionary, cargo_id: String) -> bool:
	if not vehicle.get("cargo", []).has(cargo_id):
		return false
	var cargo := _cargo_definition(cargo_id)
	return cargo.is_empty() or vehicle.get("equipment", ["standard"]).has(str(cargo.get("equipment", "standard")))


func _cargo_definition(cargo_id: String) -> Dictionary:
	for cargo in CARGO:
		if str(cargo.get("id", "")) == cargo_id:
			return cargo
	return {}


func _cargo_equipment_label(cargo_id: String) -> String:
	var cargo := _cargo_definition(cargo_id)
	var requirements := str(cargo.get("equipment", "standard")).replace("_", " ")
	var endorsement := str(cargo.get("driver_endorsement", ""))
	if endorsement != "":
		requirements += " + %s driver" % _endorsement_label(endorsement)
	return requirements


func _driver_can_carry(driver: Dictionary, cargo_id: String) -> bool:
	var required := str(_cargo_definition(cargo_id).get("driver_endorsement", ""))
	return required == "" or driver.get("endorsements", ["general"]).has(required)


func _cargo_incompatibility_message(vehicle: Dictionary, cargo_id: String) -> String:
	var cargo := _cargo_definition(cargo_id)
	if cargo.is_empty():
		return "%s cannot carry this load." % vehicle.get("name", "This vehicle")
	var equipment := str(cargo.get("equipment", "standard"))
	if vehicle.get("cargo", []).has(cargo_id) and not vehicle.get("equipment", ["standard"]).has(equipment):
		return "%s needs %s equipment for %s." % [cargo.get("name", "This load"), equipment.replace("_", " "), vehicle.get("name", "this vehicle")]
	return "%s cannot carry %s." % [vehicle.get("name", "This vehicle"), cargo.get("name", "this load")]


func _driver_incompatibility_message(driver: Dictionary, cargo_id: String) -> String:
	var cargo := _cargo_definition(cargo_id)
	var required := str(cargo.get("driver_endorsement", "specialist"))
	return "%s needs a %s driver endorsement." % [cargo.get("name", "This load"), _endorsement_label(required)]


func _endorsement_label(endorsement: String) -> String:
	match endorsement:
		"hazmat":
			return "hazmat"
		"cold_chain":
			return "cold-chain"
		"heavy_haul":
			return "heavy-haul"
		_:
			return endorsement.replace("_", " ")


func _driver_credentials_label(driver: Dictionary) -> String:
	var credentials: Array[String] = []
	for endorsement in driver.get("endorsements", ["general"]):
		if str(endorsement) == "general":
			continue
		credentials.append(_endorsement_label(str(endorsement)).capitalize())
	return ", ".join(credentials) if not credentials.is_empty() else "General"


func _infer_legacy_equipment(vehicle: Dictionary) -> Array:
	var equipment: Array = ["standard"]
	var old_cargo: Array = vehicle.get("cargo", [])
	if old_cargo.has("produce"):
		equipment.append("refrigerated")
	if old_cargo.has("building"):
		equipment.append("flatbed")
	if old_cargo.has("machinery"):
		equipment.append("machinery_platform")
	if old_cargo.has("granular"):
		equipment.append("tipper")
	return equipment


func repair_label() -> String:
	if fleet.is_empty():
		return "SERVICE SELECTED VEHICLE"
	var item: Dictionary = fleet[posmod(selected_vehicle, fleet.size())]
	var repair_rate := _repair_rate()
	var repair_cost := int(ceil((100.0 - clampf(float(item.get("condition", 100.0)), 0.0, 100.0)) * repair_rate))
	var total_cost := repair_cost + (INSPECTION_COST if _inspection_due(item) else 0)
	return "SERVICE • R%s" % commas(total_cost)


func workshop_upgrade_label() -> String:
	if workshop_level >= 2:
		return "WORKSHOP EXPANSION • 35% SAVING"
	if workshop_level == 1:
		return "EXPAND WORKSHOP • R%s • 35%% SAVING" % commas(WORKSHOP_EXPANSION_COST)
	return "UPGRADE WORKSHOP • R%s • 20%% SAVING" % commas(WORKSHOP_UPGRADE_COST)


func _repair_discount() -> float:
	if workshop_level >= 2:
		return WORKSHOP_EXPANSION_DISCOUNT
	if workshop_level == 1:
		return WORKSHOP_REPAIR_DISCOUNT
	return 0.0


func _repair_rate() -> float:
	return float(REPAIR_COST_PER_CONDITION) * (1.0 - _repair_discount())


func _vehicle_cost_multiplier(vehicle: Dictionary) -> float:
	var condition := clampf(float(vehicle.get("condition", 100.0)), 0.0, 100.0)
	return 1.0 + (100.0 - condition) * 0.005


func _inspection_due(vehicle: Dictionary) -> bool:
	var due := int(vehicle.get("odometer_km", 0)) >= int(vehicle.get("inspection_due_km", INSPECTION_INTERVAL_KM))
	vehicle["inspection_due"] = due
	return due


func energy_label(vehicle: Dictionary) -> String:
	var energy := str(vehicle.get("energy_type", "diesel"))
	var unit := "kWh" if energy == "electricity" else "L"
	var label := "Battery" if energy == "electricity" else energy.capitalize()
	return "%s • %.0f %s per 100 km" % [label, float(vehicle.get("energy_use_per_100km", 0.0)), unit]


func _energy_cost(vehicle: Dictionary, round_trip_km: int) -> int:
	var energy := str(vehicle.get("energy_type", "diesel"))
	var price := float(ENERGY_PRICES.get(energy, ENERGY_PRICES["diesel"]))
	var usage := float(vehicle.get("energy_use_per_100km", 0.0)) * float(round_trip_km) / 100.0
	return int(ceil(usage * price))


func _trip_expense(vehicle: Dictionary, round_trip_km: int, fixed_fee: int) -> int:
	var running_cost := float(round_trip_km) * float(vehicle.get("km_cost", 0.0))
	var estimated := running_cost + float(_energy_cost(vehicle, round_trip_km)) + float(fixed_fee)
	return int(ceil(estimated * _vehicle_cost_multiplier(vehicle)))


func job_cost_label() -> String:
	_build_jobs(int(floor(last_time / DAY_SECONDS)))
	if jobs.is_empty():
		return "No local trip cost to estimate."
	if fleet.is_empty():
		return "Trip cost depends on the truck you assign."
	selected_job = posmod(selected_job, jobs.size())
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	var job: Dictionary = jobs[selected_job]
	var vehicle: Dictionary = fleet[selected_vehicle]
	var expense := _trip_expense(vehicle, int(job["km"]) * 2, 100)
	return "Estimated round-trip cost R%s • %s" % [commas(expense), energy_label(vehicle)]


func _trip_wear(one_way_km: int, units: int, capacity: int, cargo_id: String) -> float:
	var load_factor := 0.85 + 0.45 * clampf(float(units) / maxf(1.0, float(capacity)), 0.0, 1.0)
	var cargo_factor := 1.0
	for cargo in CARGO:
		if str(cargo["id"]) == cargo_id:
			cargo_factor = float(cargo.get("wear_factor", 1.0))
			break
	return minf(45.0, float(one_way_km) * 2.0 / 100.0 * WEAR_PER_100_KM * load_factor * cargo_factor)


func _roll_trip_incident(vehicle: Dictionary, one_way_km: int, planned_arrival: float, deadline: float = -1.0) -> Dictionary:
	var condition := clampf(float(vehicle.get("condition", 100.0)), 0.0, 100.0)
	var condition_span := maxf(1.0, INCIDENT_CONDITION_THRESHOLD)
	var condition_bonus := maxf(0.0, INCIDENT_CONDITION_THRESHOLD - condition) / condition_span * INCIDENT_MAX_CONDITION_BONUS
	var distance_bonus := minf(INCIDENT_MAX_DISTANCE_BONUS, float(one_way_km) / 82500.0)
	var chance := INCIDENT_BASE_CHANCE + distance_bonus + condition_bonus
	if randf() >= chance:
		return {}
	var incident := {
		"id": "slow_traffic",
		"name": "Slow traffic",
		"summary": "Traffic +0.5h",
		"delay_hours": 0.5,
		"cost": 0,
		"extra_wear": 0.0,
	}
	if randf() >= 0.7:
		incident = {
			"id": "minor_tyre_repair",
			"name": "Minor tyre repair",
			"summary": "Tyre +0.8h • R1.8k",
			"delay_hours": 0.75,
			"cost": 1800,
			"extra_wear": 1.0,
		}
	if deadline >= 0.0 and planned_arrival + float(incident["delay_hours"]) * 3600.0 > deadline:
		return {}
	return incident


func _fit_incident_to_cash(incident: Dictionary, base_cost: int, available_cash: int, planned_arrival: float, deadline: float = -1.0) -> Dictionary:
	if incident.is_empty() or int(incident.get("cost", 0)) <= available_cash - base_cost:
		return incident
	var traffic_only := {"id":"slow_traffic","name":"Slow traffic","summary":"Traffic +0.5h","delay_hours":0.5,"cost":0,"extra_wear":0.0}
	if deadline >= 0.0 and planned_arrival + float(traffic_only["delay_hours"]) * 3600.0 > deadline:
		return {}
	return traffic_only


func _store_trip_incident(trip: Dictionary, incident: Dictionary) -> void:
	if incident.is_empty():
		return
	trip["incident_id"] = str(incident["id"])
	trip["incident_name"] = str(incident["name"])
	trip["incident_summary"] = str(incident["summary"])
	trip["incident_delay_hours"] = float(incident["delay_hours"])
	trip["incident_cost"] = int(incident["cost"])
	trip["incident_extra_wear"] = float(incident["extra_wear"])


func _incident_dispatch_message(incident: Dictionary, normal_message: String) -> String:
	if incident.is_empty():
		return normal_message
	if int(incident.get("cost", 0)) > 0:
		return "Minor tyre issue en route: R%s roadside repair, +%.1f game hours. Truck continues." % [commas(int(incident["cost"])), float(incident["delay_hours"])]
	return "Slow traffic en route. Return ETA extended by %.1f game hours." % float(incident["delay_hours"])


func _trip_incident_result(trip: Dictionary) -> String:
	var incident_name := str(trip.get("incident_name", ""))
	if incident_name == "":
		return ""
	var delay := float(trip.get("incident_delay_hours", 0.0))
	var cost := int(trip.get("incident_cost", 0))
	if cost > 0:
		return " Minor tyre repair: R%s and +%.1f game hours." % [commas(cost), delay]
	return " Slow traffic added %.1f game hours." % delay


func next_vehicle_label() -> String:
	var item: Dictionary = VEHICLES[vehicle_offer]
	return "%s • R%s" % [item["name"], commas(int(item["price"]))]


func next_vehicle_class() -> String:
	return str(VEHICLES[vehicle_offer].get("class", "rigid"))


func next_vehicle_tier() -> String:
	return str(VEHICLES[vehicle_offer].get("tier", "Truck"))


func next_vehicle_definition() -> Dictionary:
	return VEHICLES[vehicle_offer].duplicate(true)


func driver_label() -> String:
	if drivers.is_empty():
		return "No drivers yet"
	selected_driver = posmod(selected_driver, drivers.size())
	var item: Dictionary = drivers[selected_driver]
	return "%s • %s • %s • R%s/day" % [item["name"], str(item["status"]).capitalize(), _driver_credentials_label(item), commas(int(item["wage"]))]


func next_driver_label() -> String:
	var item: Dictionary = DRIVERS[driver_offer]
	return "%s • %s • R%s/day" % [item["name"], _driver_credentials_label(item), commas(int(item["wage"]))]


func job_label() -> String:
	_build_jobs(int(floor(last_time / DAY_SECONDS)))
	if jobs.is_empty():
		return "No local cargo demand today."
	selected_job = posmod(selected_job, jobs.size())
	var job: Dictionary = jobs[selected_job]
	var units := mini(int(job["demand"]), int(fleet[selected_vehicle]["capacity"])) if not fleet.is_empty() else int(job["demand"])
	var revenue := int(500 + int(job["km"]) * float(job["rate"]) * units)
	var equipment := _cargo_equipment_label(str(job["cargo_id"]))
	return "%s → %s • %d km each way • %d units • %s • Est. R%s" % [job["cargo_name"], job["destination"], int(job["km"]), units, equipment, commas(revenue)]


func fleet_summary() -> String:
	var available := 0
	var active := 0
	for item in fleet:
		available += 1 if item["status"] == "available" else 0
	for trip in trips:
		active += 1 if trip["status"] == "in_transit" else 0
	return "%d vehicles • %d available • %d drivers • %d active trips" % [fleet.size(), available, drivers.size(), active]


func trip_summary() -> String:
	for trip in trips:
		if trip["status"] == "in_transit":
			var hours_left := maxf(0.0, (float(trip["arrival"]) - SimulationClock.game_time_seconds) / 3600.0)
			var label := "Line haul" if str(trip.get("operation_type", "")) == "linehaul" else ("Contract" if str(trip.get("contract_id", "")) != "" else "Local delivery")
			var summary := "%s returning from %s with %s • %.1f game hours left" % [label, trip["destination"], trip["cargo_name"], hours_left]
			var incident_summary := str(trip.get("incident_summary", ""))
			if incident_summary != "":
				return "%s to %s • %.1fh left • %s" % [label, trip["destination"], hours_left, incident_summary]
			return summary
	return "No active trips. Dispatch a job to start earning."


func _set_message(value: String) -> void:
	message = value
	message_changed.emit(message)
	state_changed.emit()


func _key(destination: String, cargo_id: String) -> String:
	return destination + "|" + cargo_id


func _network_key(destination: String, cargo_id: String) -> String:
	return "line|" + destination + "|" + cargo_id


func commas(amount: int) -> String:
	var digits := str(abs(amount))
	var result := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return "-" + result if amount < 0 else result
