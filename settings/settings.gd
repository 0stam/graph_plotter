extends Node
class_name Settings

var file_path: String = "user://settings.cfg"

var settings: ConfigFile = ConfigFile.new()  # Settings object

func load_settings() -> void:
	var err: int = settings.load(file_path)
	
	if err != OK:  # If file doesn't exist or other error occured
		settings.set_value("behavior", "grid_snapping", true)
		settings.set_value("behavior", "grid_size", 20)
		settings.set_value("behavior", "undo_history_len", 15)


func save_settings() -> void:
	settings.save(file_path)


func set_behavior(key: String, value) -> void:
	settings.set_value("behavior", key, value)
	save_settings()


func toggle_behavior(key: String) -> void:
	settings.set_value("behavior", key, not settings.get_value("behavior", key))


func get_behavior(key: String) -> Variant:
	return settings.get_value("behavior", key)


func _ready() -> void:
	load_settings()
	References.settings = self
