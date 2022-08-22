extends Node
class_name History

signal ready_finished  # Allows parent to register empty graph state at the beginning
signal graph_state_change_requested(graph_state: Dictionary)

var save_history: Array[Dictionary] = []
var current_id: int = -1

var history_len:
	get:
		return settings.get_behavior("undo_history_len")

var settings: Settings  # Custom Settings


func register_action(graph_state: Dictionary) -> void:
	# Clear redo history
	if current_id >= 0:
		var i: int = current_id + 1
		print("Current candidate index: ", i)
		while i < len(save_history):
			print(i)
			save_history.remove_at(i)
	
	# If the history is full, remove the oldest element
	if len(save_history) >= history_len:
		save_history.pop_front()
	
	save_history.append(graph_state)
	
	current_id = clampi(current_id + 1, 0, history_len - 1)
	
	print("HISTORY STATE:\n", save_history, "\ncurrent_id: ", current_id, "\n")
	


func get_undo() -> Dictionary:
	current_id -= 1
	return save_history[current_id]


func get_redo() -> Dictionary:
	current_id += 1
	return save_history[current_id]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("redo"):
		if current_id < len(save_history) - 1:
			graph_state_change_requested.emit(get_redo())
			print("HISTORY STATE:\n", save_history, "\ncurrent_id: ", current_id, "\n")
	
	elif event.is_action_pressed("undo"):
		if current_id > 0:
			graph_state_change_requested.emit(get_undo())
			print("HISTORY STATE:\n", save_history, "\ncurrent_id: ", current_id, "\n")


func _ready() -> void:
	await get_tree().process_frame
	settings = References.settings
	ready_finished.emit()
