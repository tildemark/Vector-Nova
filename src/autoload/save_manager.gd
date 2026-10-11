# res://src/autoload/save_manager.gd
extends Node

const SAVE_PATH: String = "user://vector_nova_save.json"

func save_game(data: Dictionary) -> bool:
	var json_str := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to write save file: %s" % FileAccess.get_open_error())
		return false
	file.store_string(json_str)
	file.close()
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to read save file: %s" % FileAccess.get_open_error())
		return {}
		
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(content)
	if parse_result != OK:
		push_error("SaveManager: JSON parse error: %s" % json.get_error_message())
		return {}
		
	if json.data is Dictionary:
		return json.data
	return {}
