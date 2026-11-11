extends Node

const OPERATIONS_SCRIPT = preload("res://scripts/operations.gd")
const MAIN_UI_SCRIPT = preload("res://scripts/main.gd")

var failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var operations = OPERATIONS_SCRIPT.new()
	add_child(operations)
	await get_tree().process_frame

	_test_incident_rates(operations)
	_test_deadline_and_cash_safety(operations)
	_test_trip_storage(operations)
	_test_vehicle_progression_and_legacy_saves(operations)
	_test_operations_sections()
	await _test_operations_sections_render()
	await _test_dispatch_integration(operations)

	if failures == 0:
		print("PASS: trip incident regression checks")
		get_tree().quit(0)
	else:
		push_error("%d trip incident regression check(s) failed" % failures)
		get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: " + message)


func _test_incident_rates(operations: Node) -> void:
	var vehicle := {"condition": 100.0}
	var hits := 0
	var traffic := 0
	var tyre := 0
	seed(220041)
	for _i in range(20000):
		var incident: Dictionary = operations._roll_trip_incident(vehicle, 52, 100000000.0)
		if incident.is_empty():
			continue
		hits += 1
		if incident["id"] == "slow_traffic":
			traffic += 1
		elif incident["id"] == "minor_tyre_repair":
			tyre += 1
	_check(hits > 350 and hits < 650, "healthy short routes should stay near the 2.5% incident rate")
	_check(traffic > 0 and tyre > 0, "both supported incident types should be reachable")

	vehicle["condition"] = 0.0
	hits = 0
	seed(220042)
	for _i in range(20000):
		if not operations._roll_trip_incident(vehicle, 1650, 100000000.0).is_empty():
			hits += 1
	_check(hits > 950 and hits < 1650, "long routes in poor condition should use the capped 6.5% incident rate")


func _test_deadline_and_cash_safety(operations: Node) -> void:
	var vehicle := {"condition": 0.0}
	seed(220043)
	var blocked_deadline_incident := false
	for _i in range(2000):
		var impossible: Dictionary = operations._roll_trip_incident(vehicle, 1650, 100000.0, 100000.0 + 1000.0)
		blocked_deadline_incident = blocked_deadline_incident or not impossible.is_empty()
	_check(not blocked_deadline_incident, "incident must not push a contract beyond a deadline with under 0.5 hours remaining")

	seed(220044)
	var deadline_overrun := false
	for _i in range(2000):
		var fitting: Dictionary = operations._roll_trip_incident(vehicle, 1650, 100000.0, 100000.0 + 1800.0)
		deadline_overrun = deadline_overrun or (not fitting.is_empty() and float(fitting["delay_hours"]) > 0.5)
	_check(not deadline_overrun, "contract incident delay must fit the remaining deadline")

	var tyre := {"id":"minor_tyre_repair","name":"Minor tyre repair","summary":"Tyre +0.8h • R1.8k","delay_hours":0.75,"cost":1800,"extra_wear":1.0}
	var traffic: Dictionary = operations._fit_incident_to_cash(tyre, 1000, 1000, 100000.0)
	_check(traffic.get("id", "") == "slow_traffic" and int(traffic.get("cost", -1)) == 0, "repair must degrade to no-cost traffic when trip cash is tight")
	var deadline_blocked: Dictionary = operations._fit_incident_to_cash(tyre, 1000, 1000, 100000.0, 100000.0 + 1000.0)
	_check(deadline_blocked.is_empty(), "cash fallback incident must be skipped when its delay misses the deadline")
	var affordable: Dictionary = operations._fit_incident_to_cash(tyre, 1000, 2800, 100000.0)
	_check(affordable.get("id", "") == "minor_tyre_repair", "repair should remain when base cost and repair fit available cash")


func _test_trip_storage(operations: Node) -> void:
	var trip := {"status":"in_transit"}
	var incident := {"id":"minor_tyre_repair","name":"Minor tyre repair","summary":"Tyre +0.8h • R1.8k","delay_hours":0.75,"cost":1800,"extra_wear":1.0}
	operations._store_trip_incident(trip, incident)
	_check(trip.get("incident_id", "") == "minor_tyre_repair", "trip should store its incident identifier")
	_check(int(trip.get("incident_cost", 0)) == 1800 and float(trip.get("incident_extra_wear", 0.0)) == 1.0, "trip should store incident cost and extra wear")
	operations.trips = [trip]
	var saved: Dictionary = operations.snapshot()
	_check(saved["trips"][0].get("incident_summary", "") == incident["summary"], "save snapshot should preserve incident details")
	operations.load_state({"last_time":21600.0,"trips":[{"status":"completed","destination":"Paarl"}]}, 21600.0)
	_check(operations.trips.size() == 1 and not operations.trips[0].has("incident_id"), "legacy trips without incident fields should load")


func _test_vehicle_progression_and_legacy_saves(operations: Node) -> void:
	operations.start_new_game(21600.0)
	_check(operations.next_vehicle_class() == "van", "new company should begin with the starter van")
	operations.cash = 10000000
	var expected_ids := ["electric_van", "bakkie", "light_rigid", "rigid"]
	for expected_id in expected_ids:
		operations.buy_vehicle()
		_check(str(operations.fleet.back().get("id", "")) != "", "vehicle purchase should create a fleet record")
		_check(str(operations.next_vehicle_definition().get("id", "")) == expected_id, "vehicle offers should progress from vans to bakkies and light trucks")

	operations.load_state({"last_time":21600.0,"vehicle_offer":1}, 21600.0)
	_check(operations.next_vehicle_definition().get("id", "") == "rigid", "legacy offer index 1 should still point to the regional rigid truck")
	operations.load_state({"last_time":21600.0,"vehicle_offer":6}, 21600.0)
	_check(operations.next_vehicle_definition().get("id", "") == "electric_van", "legacy offer index 6 should still point to the electric van")
	var saved_state: Dictionary = operations.snapshot()
	_check(saved_state.get("vehicle_offer_id", "") == "electric_van", "new snapshots should preserve vehicle offer identity")


func _test_operations_sections() -> void:
	var ui = MAIN_UI_SCRIPT.new()
	for section in range(6):
		ui._handle_operation_action("ops_section_%d" % section)
		_check(ui.operations_section == section, "each Operations section should be reachable by its tab action")
	ui.free()


func _test_operations_sections_render() -> void:
	var ui = MAIN_UI_SCRIPT.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	await get_tree().process_frame
	ui.screen_mode = 1
	for section in range(6):
		ui.operations_section = section
		ui.queue_redraw()
		await get_tree().process_frame
	ui.queue_free()
	await get_tree().process_frame
	_check(true, "all Operations sections should redraw without runtime errors")


func _test_dispatch_integration(operations: Node) -> void:
	var found_incident := false
	for attempt in range(80):
		seed(330000 + attempt)
		operations.start_new_game(21600.0)
		operations.buy_vehicle()
		operations.hire_driver()
		operations.dispatch(21600.0)
		if operations.trips.is_empty():
			continue
		var trip: Dictionary = operations.trips[0]
		if not trip.has("incident_id"):
			continue
		found_incident = true
		var incident_delay := float(trip.get("incident_delay_hours", 0.0))
		_check(float(trip["arrival"]) > 21600.0, "dispatched incident trip should include its route duration")
		_check(float(trip["arrival"]) >= 21600.0 + incident_delay * 3600.0, "dispatch arrival should include incident delay")
		_check(operations.message != "", "dispatch should provide player feedback")
		_check(operations.trip_summary().contains(str(trip["incident_summary"])), "active trip summary should show the incident")
		break
	_check(found_incident, "local dispatch should attach an incident on a reproducible seeded trial")
