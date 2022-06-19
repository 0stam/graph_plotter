extends ShapeCast2D

signal vertex_connection_requested(from: int, to: int)
signal arrow_creation_requested(from: int, to: int)
signal vertex_creation_requested(at_position: Vector2)
signal vertex_moved(id: int)
signal vertex_selected(vertex: GraphVertex)
signal vertex_double_clicked(vertex: GraphVertex)

var zoom: float = 1  # Required for scaling vertex movement
var dragged_node: GraphVertex  # Currently dragged node
var center_offset: Vector2  # Difference between mouse position and the node's center

# Determine if the action was started
var moving: bool = false
var connecting: bool = false
var creating_arrow: bool = false

var settings: Settings  # Custom Settings

# Node references
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


func snap_value(val: int, snap_size: int) -> int:  # Snap integer to the nearest multiple of snap_size
	var result: int = val / snap_size * snap_size  # Snap to the lower multiple
	if val % snap_size / float(snap_size) >= 0.5:  # Round up if necessary
		result += snap_size
	
	return result


func snap_to_grid(pos: Vector2i) -> Vector2i:
	var grid_size: int = settings.get_behavior("grid_size")
	return Vector2i(snap_value(pos.x, grid_size), snap_value(pos.y, grid_size))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("create_arrow"):
		dragged_node = get_vertex()
		creating_arrow = true
	
	elif event.is_action_pressed("connect") and not creating_arrow:  # Register selected node and start connecting
		dragged_node = get_vertex()
		connecting = true
	
	elif event.is_action_released("connect"):
		# Variable determines whether it is necessary to perform some action to complete another
		# one later, eg. creating a connection can be necessary to create an arrow
		var update_required: bool = false
		var target: GraphVertex = get_vertex()
		
		if not target:  # If empty space was pressed, create a new vertex
			vertex_creation_requested.emit(get_global_mouse_position())
			if dragged_node:  # If connecting, queue an update and continue
				update_required = true
			else:  # If not connecting, the job is done
				return
		elif dragged_node == target:
			return
		
		# If a new vertex creation was requested, wait for it to finish
		if update_required:
			for i in 10:
				await get_tree().process_frame
				target = get_vertex()
				if target:
					break
			if not target:  # If the creation wasn't successful, return instead of throwing an error
				print("ERROR: Vertex creation didn't finish on time")
				return
		
		# Make sure the original node wasn't deleted in the meanwhile
		if is_instance_valid(dragged_node):
			# If we are connecting OR a new node was created for the purpose of creating an arrow
			if connecting or update_required:
				vertex_connection_requested.emit(dragged_node.id, target.id)
			
			if creating_arrow:
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
		if moving:
			center_offset = get_global_mouse_position() - dragged_node.center
	
	# Stop moving a vertex
	elif event.is_action_released("select"):
		dragged_node = null
		moving = false
	
	# If the mouse position changed and user is holding a vertex, move it
	elif event is InputEventMouseMotion and moving:
#		dragged_node.position += event.relative / zoom
		dragged_node.center = get_global_mouse_position() - center_offset
		
		if settings.get_behavior("grid_snapping"):
			dragged_node.center = snap_to_grid(dragged_node.center)
		
		vertex_moved.emit(dragged_node.id)
	
	elif event.is_action_pressed("toggle_snapping"):
		settings.toggle_behavior("grid_snapping")


func _ready() -> void:
	await get_tree().process_frame
	settings = References.settings
