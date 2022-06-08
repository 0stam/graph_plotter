extends Panel
class_name GraphVertex

# Utility variables
var id: int  # Should be assinged at creation
var center: Vector2:  # Alternative position positioned at the center of the vertex
	get:
		return position + size / 2
	set(val):
		position = val - size / 2

# Appearance
var auto_text_color: bool = true  # Tellf if the text color is set by user or chosen automatically
var background_color: Color = Color.YELLOW
var text_color: Color = Color.BLACK
var text: String = "Text"
var margin: Vector2 = Vector2(12, 12)

# Resources
var style_box: StyleBoxFlat = preload("res://graph_vertex/style_box_template.tres").duplicate(true)

# Children nodes
@onready var label: Label = $Label
@onready var mouse_collision: Area2D = $MouseCollision  # Required for arrows placement
@onready var collision: CollisionShape2D = $MouseCollision/CollisionShape2D


func update_colors() -> void:
	style_box.bg_color = background_color  # Update background color
	
	# If user didn't set the color, change to text to white/black based on the background color
	if auto_text_color:
		if background_color.get_luminance() > 0.5:
			text_color = Color.BLACK
		else:
			text_color = Color.WHITE
	label.set("theme_override_colors/font_color", text_color)


func update_text() -> void:
	var initial_center_pos: Vector2 = center  # Store center value for the vertex to keep original position
	
	label.text = text  # Update label text
	
	# Update label size
	var font: Font = label.get("theme_override_fonts/font")
	var font_size: int = label.get("theme_override_font_sizes/font_size")
	label.size = font.get_string_size(text, font_size)
	
	label.position = margin
	
	size = label.size + margin * 2  # Update panel size
	
	collision.position = size / 2
	collision.shape.size = size
	
	center = initial_center_pos  # Keep the same position after the text change


func get_save_data() -> Dictionary:
	return {
		"id": id,
		"center": center,
		"background_color": background_color,
		"text_color": text_color,
		"auto_text_color": auto_text_color,
		"text": text
	}


func load_save_data(data: Dictionary) -> void:
	id = data["id"]
	text = data["text"]
	center = data["center"]
	background_color = data["background_color"]
	text_color = data["text_color"]
	auto_text_color = data["auto_text_color"]
	
	update_colors()
	update_text()


func _ready() -> void:
	set("theme_override_styles/panel", style_box)  # Set custom stylebox
	collision.shape = collision.shape.duplicate(true)  # Make CollisionShape resource unique
	update_colors()
	update_text()
