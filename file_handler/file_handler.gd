extends FileDialog
class_name FileHandler

signal file_opened(data: Dictionary)

var save_data: Dictionary


func update_position() -> void:
	var scr_size: Vector2i = get_tree().root.size
	print(scr_size)
#	size = Vector2(392, 300)  # Engine min is (392, 160)
	size.x = clampf(scr_size.x / 1.5, 392, INF)
	size.y = clampf(scr_size.y / 1.5, 300, INF)
	position = scr_size / 2 - size / 2


func save(data: Dictionary) -> void:
	file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_data = data.duplicate(true)
	print(save_data)
	update_position()
	show()


func open() -> void:
	file_mode = FileDialog.FILE_MODE_OPEN_FILE
	update_position()
	show()


func _on_file_handler_file_selected(path: String) -> void:
	var file = File.new()
	if file_mode == FILE_MODE_SAVE_FILE:
		file.open(path, File.WRITE)
		file.store_var(save_data)
		save_data = {}
	elif file_mode == FILE_MODE_OPEN_FILE:
		file.open(path, File.READ)
		file_opened.emit(file.get_var())
	file.close()


func _ready() -> void:
	access = FileDialog.ACCESS_FILESYSTEM
