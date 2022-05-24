@tool
extends ColorRect

signal color_selected(color: Color)
signal color_change_requested(node: ColorRect)

# Makes sure button won't press when mouse was initially pressed somewhere else
var pressing_started: bool = false

func _on_color_selection_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:  # Discard unwanted input
		return
	
	if event.pressed:  # If event is pressed, just register press regardless of the button
		pressing_started = true
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT and pressing_started:
		color_selected.emit(color)
	
	elif event.button_index == MOUSE_BUTTON_RIGHT and pressing_started:
		color_change_requested.emit(self)
	pressing_started = false


func _on_color_selection_mouse_exited() -> void:
	pressing_started = false
