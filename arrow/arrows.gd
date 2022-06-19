extends Node2D


# {from1: {to1: NodeRef, to2: NodeRef}, from2: {to1: NodeRef, to2: NodeRef}}
var arrows: Dictionary = {}

var arrow_scene: PackedScene = preload("res://arrow/arrow.tscn")

@onready var raycast: RayCast2D = $RayCast2D


func is_arrow_created(from: int, to: int) -> bool:
	return arrows.has(from) and arrows[from].has(to)


func update_arrow(from_node: GraphVertex, to_node: GraphVertex) -> void:
	# Vertex id's
	var from: int = from_node.id
	var to: int = to_node.id
	
	# If there isn't an arrow to update, return
	if not is_arrow_created(from, to):
		return
	
	var target_collision: Area2D = to_node.mouse_collision  # The object we want to collide with
	
	var arrow: Node2D = arrows[from][to]  # Arrow node
	
	# Raycast setup
	# Remove target from exceptions. Leaving all other exceptions is fine, we want them anyway
	raycast.remove_exception(to_node.mouse_collision)
	raycast.add_exception(from_node.mouse_collision)
	raycast.position = from_node.center
	raycast.target_position = to_node.center - raycast.position
	
	# For every object hit, add it to exceptions until we hit the target
	var error_limit: int = 2
	while true:
		raycast.force_raycast_update()

		var collider = raycast.get_collider()
		if collider == null:  # If e.g node's position didn't update yet, wait for it happen
			# If it happens to many times, break from otherwise infinite loop
			error_limit -= 1
			if error_limit <= 0:
				break
			
			await get_tree().physics_frame
			
			raycast.position = from_node.center
			raycast.target_position = to_node.center - raycast.position
			continue
		
		if collider == target_collision:  # If the target node was hit, end the loop
			arrow.position = raycast.get_collision_point()
			break
		
		raycast.add_exception(collider)
	
	# Update remaining arrow parameters
	arrow.modulate = to_node.background_color
	arrow.rotation = (to_node.center - from_node.center).angle()


func remove_arrow(from: int, to: int) -> void:
	if not is_arrow_created(from, to):
		return
	
	arrows[from][to].queue_free()
	arrows[from].erase(to)


func reset() -> void:  # Remove all arrows
	arrows = {}
	for node in get_children():
		if node != raycast:
			node.queue_free()


func toggle_arrow(from_node: GraphVertex, to_node: GraphVertex) -> void:
	var from: int = from_node.id
	var to: int = to_node.id
	
	if arrows.has(from) and to in arrows[from]:  # If the arrow already exists, remove it
		arrows[from][to].queue_free()
		arrows[from].erase(to)
	else:  # If the arrow doesn't exist yet, create it
		var new_arrow: Node2D = arrow_scene.instantiate()
		if not arrows.has(from):
			arrows[from] = {}
		arrows[from][to] = new_arrow
		add_child(new_arrow)
		update_arrow(from_node, to_node)


func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	
	for from in arrows.keys():
		data[from] = arrows[from].keys()
	
	return data
