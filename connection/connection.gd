extends Line2D
class_name Connection

var verticies: Array = []


func add_vertex(id: int) -> void:
	verticies.append(id)


func set_verticies(ids: Array) -> void:
	verticies = ids


func is_connected_to_vertex(id: int) -> bool:
	return id in verticies


func set_vertex_position(id: int, to_position: Vector2):
	if id in verticies:  # Validate if this connection should update
		set_point_position(verticies.find(id), to_position)


func set_vertex_color(id: int, val: Color):
	if id in verticies:  # Validate if this connection should update
		gradient.colors[verticies.find(id)] = val


func _ready() -> void:
	gradient = gradient.duplicate(true)  # Make gradient resource unique
