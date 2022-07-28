extends Control

signal name_changed(new_name: String)
signal color_changed(new_color: Color)

# Settings
const DEFAULT_COLOR_COUNT: int = 35
const CUSTOM_COLOR_COUNT: int = 100

var custom_colors: Dictionary = {}

# Color selection currently modified by ColorPicker
var modified_color_selection: ColorRect = null

# Packed scenes
var color_selection_scene: PackedScene = preload("res://simple_edit/color_selection.tscn")

# Children references
@onready var name_edit: LineEdit = $VBoxContainer/NameEdit
@onready var color_selections: HBoxContainer = $VBoxContainer/ColorSelections
@onready var color_picker: ColorPicker = $ColorPicker


func update_name(val: String) -> void:  # Update the name in the name editor
	name_edit.text = val


func update_colors(colors: Dictionary = {}) -> void:
	# Remove old nodes
	for node in color_selections.get_children():
		color_selections.remove_child(node)
	
	# Create buttons with default colors
	for i in DEFAULT_COLOR_COUNT:
		add_color_selection(Color.from_hsv(float(i) / DEFAULT_COLOR_COUNT, 1, 1))
	
	add_color_selection(Color.WHITE)
	
	for i in CUSTOM_COLOR_COUNT:
		add_color_selection(Color.BLACK)
	
	# Set custom colors
	custom_colors = colors
	for node_id in custom_colors:
		color_selections.get_child(node_id).color = colors[node_id]


# Disable/enable name editing and display placeholder text when disabled
func set_enabled(enabled: bool) -> void:
	name_edit.editable = enabled
	if not enabled:
		name_edit.text = ""


# Add and configure color selection button
func add_color_selection(color: Color):
	var new_selection: ColorRect = color_selection_scene.instantiate()
	new_selection.color = color
	
	new_selection.color_selected.connect(_on_color_selection_color_selected)
	new_selection.color_change_requested.connect(_on_color_selection_color_change_requested)
	
	color_selections.add_child(new_selection)


func focus_editor() -> void:
	name_edit.grab_focus()


func _on_name_edit_text_changed(new_text: String) -> void:
	name_changed.emit(new_text)


func _on_color_selection_color_selected(color: Color) -> void:
	color_changed.emit(color)
	color_picker.hide()


func _on_color_selection_color_change_requested(node: ColorRect):
	color_picker.color = node.color  # Set ColorPicker's color to the edited button's one
	
	# Set ColorPicker position as close to the button as possible, but remaining inside the screen
	var max_position: float = DisplayServer.screen_get_size().x - color_picker.size.x - 32
	color_picker.position.x = clamp(node.global_position.x, 32, max_position)
	
	color_picker.show()
	modified_color_selection = node


func _on_color_picker_color_changed(color: Color) -> void:
	modified_color_selection.color = color
	custom_colors[modified_color_selection.get_index()] = color


func _on_name_edit_focus_entered() -> void:
	color_picker.hide()
	await get_tree().process_frame  # Prevent mouse press processing from cancelling the selection
	name_edit.select_all()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		color_picker.hide()  # Hide color picker when clicked elsewhere
		name_edit.release_focus()


func _ready() -> void:
	update_colors()  # Add color selection buttons
