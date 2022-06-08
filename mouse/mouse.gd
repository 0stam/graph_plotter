extends ShapeCast2D

signal vertex_connection_requested(from: int, to: int)
signal arrow_creation_requested(from: int, to: int)
signal vertex_creation_requested(at_position: Vector2)
signal vertex_moved(id: int)
signal vertex_selected(vertex: GraphVertex)
signal vertex_double_clicked(vertex: GraphVertex)

var zoom: float = 1  # Required for scaling vertex movement
var dragged_node: GraphVertex  # Currently dragged node

# Determine if the action was started
var moving: bool = false
var connecting: bool = false
var creating_arrow: bool = false

# Children references
@onready var double_click: Timer = $DoubleClick


func get_vertex() -> GraphVertex:
	position = get_global_mouse_position()
	force_shapecast_update()
	if get_collision_count() and get_collider(0).get_parent() is GraphVertex:
		return get_collider(0).get_parent()
	return null


# Shared code for validating the target and requesting the connection
func request_connection(success_signal: Signal) -> void:
	var target: GraphVertex = get_vertex()
	
	if target and dragged_node != target:  # If a valid node was targetted
		success_signal.emit(dragged_node.id, target.id)  # Request connection
		vertex_selected.emit(target)  # Move focus to the target node
	
	connecting = false  # End action regardless of it being correct or not


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("create_arrow"):
		print("1")
		dragged_node = get_vertex()
		creating_arrow = true
	
	elif event.is_action_pressed("connect") and not creating_arrow:  # Register selected node and start connecting
		print("0")
		dragged_node = get_vertex()
		connecting = true
	
	elif event.is_action_released("connect"):
		var update_required: bool = false
		var target: GraphVertex = get_vertex()
		
		if not target:
			vertex_creation_requested.emit(get_global_mouse_position())
			if dragged_node:
				update_required = true
			else:
				return
		
		if update_required:
			for i in 10:
				await get_tree().process_frame
				target = get_vertex()
				if target:
					break
			if not target:
				return
		
		if (connecting or update_required) and is_instance_valid(dragged_node):
			vertex_connection_requested.emit(dragged_node.id, target.id)
		
		if creating_arrow and is_instance_valid(dragged_node):
			arrow_creation_requested.emit(dragged_node.id, target.id)
		
		vertex_selected.emit(target)
		connecting = false
		creating_arrow = false
	
	# Select a vertex and start moving it
	elif event.is_action_pressed("select"):
		if double_click.is_stopped():
			double_click.start()
		else:
			vertex_double_clicked.emit(dragged_node)
		
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
