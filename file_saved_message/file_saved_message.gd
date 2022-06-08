extends Label

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func pop():
	animation_player.play(StringName("pop"))


func _ready() -> void:
	modulate.a = 0
