extends Control

# Graph
var verticies: Dictionary = {}
var verticies_connections: Dictionary = {}

# Current data
var next_vertex_index: int = 0
var selected: GraphVertex = null
var last_color: Color = Color.YELLOW

# Packed Scenes
var vertex_scene: PackedScene = preload("res://graph_vertex/graph_vertex.tscn")
var connection_scene: PackedScene = preload("res://connection/connection.tscn")

# Children references
@onready var background: Control = $Background/Background
@onready var verticies_node: Control = $Verticies
@onready var connections_node: Node2D = $Connections
@onready var arrows_node: Node2D = $Arrows
@onready var mouse: ShapeCast2D = $Mouse
@onready var simple_edit: Control = $UI/SimpleEdit
@onready var file_handler: FileHandler = $FileHandler
@onready var file_saved_message: Label = $UI/FileSavedMessage

# Save the default background color for the purpose of resetting
@onready var default_background_color: Color = background.color


# Create vertex with minimal configuration
func create_vertex(id: int) -> GraphVertex:
	var new_vertex: GraphVertex = vertex_scene.instantiate()
	verticies_node.add_child(new_vertex)
	
	new_vertex.id = id
	verticies[id] = new_vertex
	verticies_connections[id] = []
	_on_mouse_vertex_selected(new_vertex)
	
	return new_vertex


func update_connection_color(connection: Connection) -> void:
	for id in connection.verticies:
		# Connection verifies if it is connected to a given vertex
		connection.set_vertex_color(id, verticies[id].background_color)


func update_connection_position(connection: Connection) -> void:
	for id in connection.verticies:
		# Connection verifies if it is connected to a given vertex
		connection.set_vertex_position(id, verticies[id].center)


func update_vertex_connections(id: int) -> void:
	for connection in verticies_connections[id]:
		update_connection_color(connection)
		update_connection_position(connection)


func update_vertex_arrows(id: int) -> void:
	for connection in verticies_connections[id]:
		var ids: Array[int] = connection.verticies
		arrows_node.update_arrow(verticies[ids[0]], verticies[ids[1]])
		arrows_node.update_arrow(verticies[ids[1]], verticies[ids[0]])


func remove_connection(from: int, to: int) -> bool:  # Returns true if the connection existed
	# For each connection connected to "from"
	for i in len(verticies_connections[from]):
		if verticies_connections[from][i].is_connected_to_vertex(to):  # If is connected to "to"
			verticies_connections[from].pop_at(i)
			
			# Remove the identical connection stored under dict key "to"
			for j in len(verticies_connections[to]):
				if verticies_connections[to][j].is_connected_to_vertex(from):
					verticies_connections[to].pop_at(j).queue_free()
					
					arrows_node.remove_arrow(from, to)
					arrows_node.remove_arrow(to, from)
					return true
	return false


func get_connections_save_data() -> Dictionary:
	var data: Dictionary = {}  # Resulting dictionary with all connections stored only once
	
	# For all connections
	for node in verticies_connections.values():
		for connection in node:
			var current_verticies: Array = connection.verticies
			current_verticies.sort()
			
			# Check if the connection is already in the list
			if data.has(current_verticies[0]):
				if current_verticies[1] in data[current_verticies[0]]:
					continue
			else:  # If the connection has to be added, but the necessary key isn't there yet
				data[current_verticies[0]] = []
			
			data[current_verticies[0]].append(current_verticies[1])  # Add connection
			
	return data


func get_verticies_save_data() -> Dictionary:
	var data: Dictionary = {}
	
	for vertex in verticies.values():
		data[vertex.id] = vertex.get_save_data()
	
	return data


func get_save_data() -> Dictionary:
	return {
		"verticies": get_verticies_save_data(),
		"connections": get_connections_save_data(),
		"arrows": arrows_node.get_save_data(),
		"background_color": background.color,
		"custom_colors": simple_edit.custom_colors
	}


func reset() -> void:
	# Remove all verticies and connections
	for node in verticies_node.get_children() + connections_node.get_children():
		node.queue_free()
	arrows_node.reset()
	
	verticies = {}
	verticies_connections = {}
	background.color = default_background_color
	_on_mouse_vertex_selected(null)


# Create vertex and configure it based on the user-selected values and position
func _on_mouse_vertex_creation_requested(at_position: Vector2) -> void:
	var new_vertex: GraphVertex = create_vertex(next_vertex_index)
	new_vertex.center = at_position
	new_vertex.background_color = last_color
	new_vertex.update_colors()
	next_vertex_index += 1


func _on_mouse_vertex_connection_requested(from: int, to: int) -> void:
	if remove_connection(from, to):  # If the connection already exists, remove it
		return
	
	# Create connection with assigned verticies
	var new_connection: Line2D = connection_scene.instantiate()
	new_connection.set_verticies([from, to])
	
	# Update lists storing connections
	verticies_connections[from].append(new_connection)
	verticies_connections[to].append(new_connection)
	
	# Update connections based on the assigned verticies
	update_connection_color(new_connection)
	update_connection_position(new_connection)
	
	connections_node.add_child(new_connection)


func _on_mouse_arrow_creation_requested(from: int, to: int) -> void:
	var connection_creation_required: bool = true
	for connection in verticies_connections[from]:
		if connection.is_connected_to_vertex(to):
			connection_creation_required = false
			break
	
	if connection_creation_required:
		_on_mouse_vertex_connection_requested(from, to)
	
	arrows_node.toggle_arrow(verticies[from], verticies[to])


func _on_mouse_vertex_moved(id) -> void:
	update_vertex_connections(id)
	update_vertex_arrows(id)


func _on_mouse_vertex_selected(vertex: GraphVertex) -> void:
	selected = vertex
	simple_edit.set_enabled(vertex != null)  # Disable name edit
	
	if not vertex:  # If the background was selected, return
		return
	
	simple_edit.update_name(vertex.text)  # Display vertex's name in editor


func _on_mouse_vertex_double_clicked(_vertex: GraphVertex) -> void:
	simple_edit.focus_editor()


func _on_simple_edit_name_changed(new_name: String) -> void:
	selected.text = new_name
	selected.update_text()
	update_vertex_arrows(selected.id)


func _on_simple_edit_color_changed(new_color: Color) -> void:
	if selected:
		selected.background_color = new_color
		selected.update_colors()
		update_vertex_connections(selected.id)
		update_vertex_arrows(selected.id)
		
		last_color = new_color  # Save this color as default for new verticies
	else:
		background.color = new_color


func _on_camera_zoom_changed(val: float) -> void:
	mouse.zoom = val


func _on_file_handler_file_opened(data: Dictionary) -> void:
	reset()  # Reset everything
	
	# Load verticies
	for vertex_data in data["verticies"].values():
		var id: int = vertex_data["id"]
		var new_vertex: GraphVertex = create_vertex(id)
		new_vertex.load_save_data(vertex_data)
		
		# Update id for new verticies if necessary
		if id >= next_vertex_index:
			next_vertex_index = id + 1
	
	# Load connections
	for from in data["connections"].keys():
		for to in data["connections"][from]:
			_on_mouse_vertex_connection_requested(from, to)
	
	await get_tree().physics_frame  # Wait for collision to update, required for arrows creation
	
	# Load arrows
	for from in data["arrows"].keys():
		for to in data["arrows"][from]:
			_on_mouse_arrow_creation_requested(from, to)
	
	# Load custom colors from simple edit
	simple_edit.update_colors(data["custom_colors"])
	
	background.color = data["background_color"]


func _on_file_handler_file_saved() -> void:
	file_saved_message.pop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("delete"):
		if selected != null:  # If there is a node selected
			while len(verticies_connections[selected.id]) > 0:  # For all nodes connections
				# Get the connection verticies and remove the connection from both arrays
				var connection: Connection = verticies_connections[selected.id][0]
				remove_connection(connection.verticies[0], connection.verticies[1])
			
			# Remove dictionary keys
			verticies_connections.erase(selected.id)
			verticies.erase(selected.id)
			
			selected.queue_free()  # Remove node
			
			_on_mouse_vertex_selected(null)  # Reset selection
	
	elif event.is_action_pressed("save_as"):
		file_handler.save_as(get_save_data())
	
	elif event.is_action_pressed("save"):
		file_handler.save(get_save_data())
	
	elif event.is_action_pressed("open"):
		file_handler.open()
