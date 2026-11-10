extends Node

signal state_changed
signal message_changed(message: String)

const DAY_SECONDS := 86400.0
const STARTING_CASH := 1250000
const HOME := "Cape Town"
const VEHICLES := [
	{"id":"van","name":"Coastal Courier Van","price":280000,"capacity":8,"km_cost":10.0,"cargo":["parcels","dry"]},
	{"id":"rigid","name":"Regional Rigid 8T","price":760000,"capacity":28,"km_cost":22.0,"cargo":["dry","produce","building"]},
	{"id":"reefer","name":"ColdLink Refrigerated","price":920000,"capacity":20,"km_cost":25.0,"cargo":["produce","dry"]}
]
const DRIVERS := [
	{"name":"Lebo Mokoena","wage":900},
	{"name":"Siyabonga Dlamini","wage":1050},
	{"name":"Nadia Jacobs","wage":1150}
]
const CARGO := [
	{"id":"parcels","name":"Parcel freight","rate":22.0},
	{"id":"dry","name":"Packaged goods","rate":17.0},
	{"id":"produce","name":"Fresh produce","rate":20.0},
	{"id":"building","name":"Building supplies","rate":15.0}
]
const DESTINATIONS := [
	{"name":"Stellenbosch","km":52,"hours":1.0},
	{"name":"Paarl","km":62,"hours":1.0},
	{"name":"Worcester","km":112,"hours":2.0},
	{"name":"Hermanus","km":120,"hours":2.0}
]

var cash := STARTING_CASH
var fleet: Array = []
var drivers: Array = []
var trips: Array = []
var demand: Dictionary = {}
var jobs: Array = []
var last_time := 21600.0
var selected_vehicle := 0
var selected_driver := 0
var selected_job := 0
var vehicle_offer := 0
var driver_offer := 0
var message := "Company ready. Buy a vehicle and hire a driver to begin."


func start_new_game(game_time: float) -> void:
	cash = STARTING_CASH
	fleet.clear()
	drivers.clear()
	trips.clear()
	demand.clear()
	selected_vehicle = 0
	selected_driver = 0
	selected_job = 0
	vehicle_offer = 0
	driver_offer = 0
	last_time = game_time
	_reset_demand(int(floor(game_time / DAY_SECONDS)))
	_set_message("New Cape Town company opened with R1,250,000 in starting funds.")


func load_state(state: Dictionary, game_time: float) -> void:
	cash = int(state.get("cash", STARTING_CASH))
	fleet = state.get("fleet", [])
	drivers = state.get("drivers", [])
	trips = state.get("trips", [])
	demand = state.get("demand", {})
	selected_vehicle = int(state.get("selected_vehicle", 0))
	selected_driver = int(state.get("selected_driver", 0))
	selected_job = int(state.get("selected_job", 0))
	vehicle_offer = int(state.get("vehicle_offer", 0))
	driver_offer = int(state.get("driver_offer", 0))
	last_time = float(state.get("last_time", game_time))
	_build_jobs(int(floor(game_time / DAY_SECONDS)))
	advance_to(game_time)
	_set_message("Company progress loaded from this device.")


func snapshot() -> Dictionary:
	return {"cash":cash,"fleet":fleet.duplicate(true),"drivers":drivers.duplicate(true),"trips":trips.duplicate(true),"demand":demand.duplicate(true),"selected_vehicle":selected_vehicle,"selected_driver":selected_driver,"selected_job":selected_job,"vehicle_offer":vehicle_offer,"driver_offer":driver_offer,"last_time":last_time}


func advance_to(game_time: float) -> void:
	if game_time <= last_time:
		return
	var boundary: float = (floor(last_time / DAY_SECONDS) + 1.0) * DAY_SECONDS
	while boundary <= game_time:
		_complete_until(boundary)
		var wages := 0
		for driver in drivers:
			wages += int(driver.get("wage", 0))
		cash -= wages
		if wages > 0:
			_set_message("Daily driver wages paid: R%s." % commas(wages))
		_reset_demand(int(floor(boundary / DAY_SECONDS)))
		boundary += DAY_SECONDS
	_complete_until(game_time)
	last_time = game_time


func _complete_until(game_time: float) -> void:
	for trip in trips:
		if str(trip.get("status", "")) != "in_transit" or float(trip.get("arrival", 0.0)) > game_time:
			continue
		cash += int(trip.get("revenue", 0))
		trip["status"] = "returned"
		for vehicle in fleet:
			if str(vehicle.get("id", "")) == str(trip.get("vehicle_id", "")):
				vehicle["status"] = "available"
				vehicle["driver_id"] = ""
		for driver in drivers:
			if str(driver.get("id", "")) == str(trip.get("driver_id", "")):
				driver["status"] = "available"
		_set_message("Delivery returned from %s. R%s received." % [trip.get("destination", "local market"), commas(int(trip.get("revenue", 0)))])


func _reset_demand(day_index: int) -> void:
	demand.clear()
	for destination in DESTINATIONS:
		for cargo in CARGO:
			var key := _key(str(destination["name"]), str(cargo["id"]))
			demand[key] = 3 + int(abs(hash(key + str(day_index))) % 7)
	_build_jobs(day_index)


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
	fleet.append({"id":"vehicle_%d" % (fleet.size()+1),"name":definition["name"],"price":price,"capacity":definition["capacity"],"km_cost":definition["km_cost"],"cargo":definition["cargo"].duplicate(),"status":"available","driver_id":"","location":HOME})
	selected_vehicle = fleet.size() - 1
	vehicle_offer = (vehicle_offer + 1) % VEHICLES.size()
	_set_message("Purchased %s for R%s." % [definition["name"], commas(price)])


func hire_driver() -> void:
	var definition: Dictionary = DRIVERS[driver_offer]
	drivers.append({"id":"driver_%d" % (drivers.size()+1),"name":definition["name"],"wage":definition["wage"],"status":"available"})
	selected_driver = drivers.size() - 1
	driver_offer = (driver_offer + 1) % DRIVERS.size()
	_set_message("Hired %s at R%s per game day." % [definition["name"], commas(int(definition["wage"]))])


func cycle_vehicle() -> void:
	if fleet.is_empty():
		_set_message("Buy a vehicle before selecting one.")
		return
	selected_vehicle = (selected_vehicle + 1) % fleet.size()
	_set_message("Selected %s." % fleet[selected_vehicle]["name"])


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
	if not vehicle["cargo"].has(job["cargo_id"]):
		_set_message("%s cannot carry %s." % [vehicle["name"], job["cargo_name"]])
		return
	var units := mini(int(job["demand"]), int(vehicle["capacity"]))
	var km := int(job["km"])
	var revenue := int(500 + km * float(job["rate"]) * units)
	var expense := int(km * 2 * float(vehicle["km_cost"]) + 100)
	if cash < expense:
		_set_message("Insufficient cash for estimated R%s trip costs." % commas(expense))
		return
	var duration := maxf(2.0, float(job["hours"]) * 2.0)
	var driver_id := str(driver["id"])
	var vehicle_id := str(vehicle["id"])
	trips.append({"id":"trip_%d" % (trips.size()+1),"vehicle_id":vehicle_id,"driver_id":driver_id,"destination":job["destination"],"cargo_name":job["cargo_name"],"revenue":revenue,"arrival":game_time + duration * 3600.0,"status":"in_transit"})
	vehicle["status"] = "in_transit"
	vehicle["driver_id"] = driver_id
	driver["status"] = "in_transit"
	cash -= expense
	cash -= expense
	var key := str(job["id"])
	demand[key] = maxi(0, int(demand.get(key, 0)) - units)
	_build_jobs(int(floor(game_time / DAY_SECONDS)))
	_set_message("Dispatched to %s: R%s expected revenue, %s game hours round trip." % [job["destination"], commas(revenue), str(int(duration))])


func vehicle_label() -> String:
	if fleet.is_empty():
		return "No vehicles yet"
	selected_vehicle = posmod(selected_vehicle, fleet.size())
	var item: Dictionary = fleet[selected_vehicle]
	return "%s • %s • %d-unit capacity" % [item["name"], str(item["status"]).capitalize(), int(item["capacity"])]


func next_vehicle_label() -> String:
	var item: Dictionary = VEHICLES[vehicle_offer]
	return "%s • R%s" % [item["name"], commas(int(item["price"]))]


func driver_label() -> String:
	if drivers.is_empty():
		return "No drivers yet"
	selected_driver = posmod(selected_driver, drivers.size())
	var item: Dictionary = drivers[selected_driver]
	return "%s • %s • R%s/day" % [item["name"], str(item["status"]).capitalize(), commas(int(item["wage"]))]


func next_driver_label() -> String:
	var item: Dictionary = DRIVERS[driver_offer]
	return "%s • R%s/day" % [item["name"], commas(int(item["wage"]))]


func job_label() -> String:
	_build_jobs(int(floor(last_time / DAY_SECONDS)))
	if jobs.is_empty():
		return "No local cargo demand today."
	selected_job = posmod(selected_job, jobs.size())
	var job: Dictionary = jobs[selected_job]
	var units := mini(int(job["demand"]), int(fleet[selected_vehicle]["capacity"])) if not fleet.is_empty() else int(job["demand"])
	var revenue := int(500 + int(job["km"]) * float(job["rate"]) * units)
	return "%s → %s • %d km each way • %d units • Est. R%s" % [job["cargo_name"], job["destination"], int(job["km"]), units, commas(revenue)]


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
			return "En route to %s with %s • %.1f game hours left" % [trip["destination"], trip["cargo_name"], hours_left]
	return "No active trips. Dispatch a job to start earning."


func _set_message(value: String) -> void:
	message = value
	message_changed.emit(message)
	state_changed.emit()


func _key(destination: String, cargo_id: String) -> String:
	return destination + "|" + cargo_id


func commas(amount: int) -> String:
	var digits := str(abs(amount))
	var result := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return "-" + result if amount < 0 else result
