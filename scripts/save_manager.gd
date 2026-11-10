extends Node

const SAVE_PATH := "user://transit_manager_save.json"
const BACKUP_PATH := "user://transit_manager_save.bak"
const TEMP_PATH := "user://transit_manager_save.tmp"
const CURRENT_SCHEMA := 5

var recovered_backup := false


func load_game() -> Dictionary:
	recovered_backup = false
	var primary := _read_save(SAVE_PATH)
	if not primary.is_empty():
		return primary
	var backup := _read_save(BACKUP_PATH)
	if not backup.is_empty():
		recovered_backup = true
		return backup
	return {}


func save_game(state: Dictionary) -> bool:
	var payload := state.duplicate(true)
	payload["schema_version"] = CURRENT_SCHEMA
	payload["last_saved_unix"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Transit Manager could not open the temporary save file.")
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var absolute_save := ProjectSettings.globalize_path(SAVE_PATH)
	var absolute_backup := ProjectSettings.globalize_path(BACKUP_PATH)
	var absolute_temp := ProjectSettings.globalize_path(TEMP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(absolute_backup)
		var rotation_result := DirAccess.rename_absolute(absolute_save, absolute_backup)
		if rotation_result != OK:
			push_error("Transit Manager could not rotate the previous save: %s" % error_string(rotation_result))
			return false
	var result := DirAccess.rename_absolute(absolute_temp, absolute_save)
	if result != OK:
		push_error("Transit Manager could not finalize the local save: %s" % error_string(result))
		if FileAccess.file_exists(BACKUP_PATH) and not FileAccess.file_exists(SAVE_PATH):
			DirAccess.rename_absolute(absolute_backup, absolute_save)
		return false
	return true


func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed
	var version := int(data.get("schema_version", 0))
	if version == 1:
		data["schema_version"] = 2
		data["operations"] = {}
		version = 2
	if version == 2:
		var operations: Dictionary = data.get("operations", {})
		operations["contracts"] = operations.get("contracts", [])
		operations["selected_contract"] = 0
		operations["accepted_contract_id"] = ""
		data["operations"] = operations
		data["schema_version"] = 3
		version = 3
	if version == 3:
		var operations: Dictionary = data.get("operations", {})
		operations["owned_terminals"] = operations.get("owned_terminals", ["Cape Town"])
		operations["selected_network_job"] = 0
		operations["terminal_offer"] = 0
		data["operations"] = operations
		data["schema_version"] = 4
		version = 4
	if version == 4:
		data["schema_version"] = 5
		return data
	if version != CURRENT_SCHEMA:
		return {}
	return data
