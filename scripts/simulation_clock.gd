extends Node

signal time_changed(game_time_seconds: float)
signal speed_changed(speed_index: int)

const SECONDS_PER_GAME_DAY := 24.0 * 60.0 * 60.0
const GAME_SECONDS_PER_REAL_SECOND := 60.0
const OFFLINE_CATCHUP_CAP_GAME_SECONDS := 12.0 * 60.0 * 60.0
const SPEEDS := [0.0, 1.0, 3.0]

var game_time_seconds := 6.0 * 60.0 * 60.0
var speed_index := 1 # paused, normal, fast


func _process(delta: float) -> void:
	if speed_index == 0:
		return
	game_time_seconds += delta * GAME_SECONDS_PER_REAL_SECOND * SPEEDS[speed_index]
	time_changed.emit(game_time_seconds)


func set_speed(value: int) -> void:
	speed_index = clampi(value, 0, SPEEDS.size() - 1)
	speed_changed.emit(speed_index)
	time_changed.emit(game_time_seconds)


func cycle_speed() -> void:
	set_speed((speed_index + 1) % SPEEDS.size())


func restore(saved_time: float, saved_speed: int, elapsed_real_seconds: float) -> float:
	game_time_seconds = maxf(0.0, saved_time)
	speed_index = clampi(saved_speed, 0, SPEEDS.size() - 1)
	var caught_up := 0.0
	if speed_index > 0:
		caught_up = minf(elapsed_real_seconds * GAME_SECONDS_PER_REAL_SECOND * SPEEDS[speed_index], OFFLINE_CATCHUP_CAP_GAME_SECONDS)
		game_time_seconds += caught_up
	time_changed.emit(game_time_seconds)
	speed_changed.emit(speed_index)
	return caught_up


func clock_label() -> String:
	var total_days := int(floor(game_time_seconds / SECONDS_PER_GAME_DAY))
	var day_number := total_days + 1
	var seconds_today := int(floor(fmod(game_time_seconds, SECONDS_PER_GAME_DAY)))
	var hour := int(seconds_today / 3600)
	var minute := int((seconds_today % 3600) / 60)
	return "DAY %d  •  %02d:%02d" % [day_number, hour, minute]


func speed_label() -> String:
	match speed_index:
		0:
			return "PAUSED"
		1:
			return "1× NORMAL"
		_:
			return "3× FAST"
