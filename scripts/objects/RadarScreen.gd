extends Node3D
class_name RadarScreen

@export var quad_for_viewport : MeshInstance3D
@export var radar_viewport : SubViewport

func _ready() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_texture = radar_viewport.get_texture()
