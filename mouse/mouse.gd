extends ShapeCast2D

signal vertex_connection_requested(from: int, to: int)
signal vertex_creation_requested(at_position: Vector2)
signal vertex_moved(id: int)
signal vertex_selected(vertex: GraphVertex)

var zoom: float = 1  # Required for scaling vertex movement
var dragged_node: GraphVertex  # Currently dragged node

# Determine if the action was started
var moving: bool = false
var connecting: bool = false


func get_vertex() -> GraphVertex:
	position = get_global_mouse_position()
	force_shapecast_update()
	if get_collision_count() and get_collider(0).get_parent() is GraphVertex:
		return get_collider(0).get_parent()
	return null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("connect"):  # Register selected node and start connecting
		dragged_node = get_vertex()
		connecting = dragged_node != null
	
	elif event.is_action_released("connect"):
		if connecting:  # If a valid node was selected at the beginning
			var target: GraphVertex = get_vertex()
			
			if target and dragged_node != target:  # If a valid node was targetted
				vertex_connection_requested.emit(dragged_node.id, target.id)  # Request connection
				vertex_selected.emit(target)  # Move focus to the target node
			
			connecting = false  # End action regardless of it being correct or not
		
		else:  # If background was pressed, create new vertex
			vertex_creation_requested.emit(get_global_mouse_position())
	
	# Select a vertex and start moving it
	elif event.is_action_pressed("select"):
		dragged_node = get_vertex()
		vertex_selected.emit(dragged_node)
		moving = dragged_node != null
	
	# Stop moving a vertex
	elif event.is_action_released("select"):
		dragged_node = null
		moving = false
	
	# If the mouse position changed and user is holding a vertex, move it
	elif event is InputEventMouseMotion and moving:
		dragged_node.position += event.relative / zoom
		vertex_moved.emit(dragged_node.id)
