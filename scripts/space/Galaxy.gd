extends Node3D
class_name Galaxy

@export var planets_parent : Node3D

var id : int
var display_name : String
var planets : Array[Planet]
var boundaries : Vector4 # (x: min_x, y: max_x, z: min_y, w: max_y)

func _ready() -> void:
	# Ship is always at 0,0,0
	look_at(Vector3.ZERO, Vector3.UP, true)
	for planet in planets:
		planets_parent.add_child(planet)
	planets_parent.hide()
