extends Node3D

@export var collision_body : CollisionObject3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

@export_flags_2d_physics var open_layer
@export_flags_2d_physics var close_layer

var is_open = false

func activate() -> void:
	if animation_player.is_playing():
		return
	
	if not is_open:
		animation_player.play("open")
		collision_body.collision_layer = 0
		is_open = true
	else:
		animation_player.play_backwards("open")
		collision_body.collision_layer = 1 << 0
		is_open = false
