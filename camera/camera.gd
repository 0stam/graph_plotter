extends Camera2D

signal zoom_changed(val: float)


var zoom_step: float = 0.1
var panning: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pan"):
		panning = true
		
	elif event.is_action_released("pan"):
		panning = false
		
	elif event is InputEventMouseMotion and panning:
		position -= event.relative / zoom.x
	
	elif event.is_action_pressed("zoom_in"):
		zoom += Vector2(zoom_step, zoom_step)
		zoom_changed.emit(zoom.x)
	
	elif event.is_action_pressed("zoom_out"):
		if zoom.x - zoom_step <= 0:
			return
		zoom -= Vector2(zoom_step, zoom_step)
		zoom_changed.emit(zoom.x)
