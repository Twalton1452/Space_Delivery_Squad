extends Node3D
class_name RadarConsole

## Physical object the Players interact with to affect the Path the Ship takes

@export var quad_for_viewport : MeshInstance3D
@export var radar_viewport : SubViewport

func _ready() -> void:
	enable()
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_texture = radar_viewport.get_texture()

func enable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.WHITE

func disable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.BLACK

func _on_left_button_pressed() -> void:
	# choose previous path
	pass

func _on_right_button_pressed() -> void:
	# choose next path
	pass

