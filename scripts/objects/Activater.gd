extends Area3D
class_name Activater

@export var to_activate : Array[Node3D]

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func interact() -> void:
	if animation_player.is_playing():
		return
	
	animation_player.play("activated")
	
	for activatable in to_activate:
		if activatable.has_method("activate"):
			activatable.activate()
			
