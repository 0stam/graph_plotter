extends FileDialog
class_name FileHandler

signal file_opened(data: Dictionary)
signal file_saved

var save_data: Dictionary = {}
var current_file_path: String = ""


func update_position() -> void:  # Update the position and the size to fit in the screen
	var scr_size: Vector2i = get_tree().root.size
	size.x = clampf(scr_size.x / 1.5, 392, INF)
	size.y = clampf(scr_size.y / 1.5, 300, INF)
	position = scr_size / 2 - size / 2


func save_to_file(path: String) -> void:  # Just save "save_data" to file; shared by other functions
	var file: File = File.new()
	file.open(path, File.WRITE)
	file.store_var(save_data)
	save_data = {}
	
	current_file_path = path
	file_saved.emit()


func save(data: Dictionary) -> void:  # Triggered by externall script
	if current_file_path.is_empty():  # If there is no current file, run file dialog
		save_as(data)
	else:  # Otherwise just overwrite the current file
		save_data = data
		save_to_file(current_file_path)


func save_as(data: Dictionary) -> void:  # Run save file dialog, no matter the value of current_file
	save_data = data
	file_mode = FileDialog.FILE_MODE_SAVE_FILE
	update_position()
	show()


func open() -> void:  # Triggered by external script
	file_mode = FileDialog.FILE_MODE_OPEN_FILE
	update_position()
	current_dir = current_path
	show()


func _on_file_handler_file_selected(path: String) -> void:
	if file_mode == FILE_MODE_SAVE_FILE:
		save_to_file(path)
	elif file_mode == FILE_MODE_OPEN_FILE:
		var file = File.new()
		file.open(path, File.READ)
		file_opened.emit(file.get_var())
		current_file_path = path
		file.close()
