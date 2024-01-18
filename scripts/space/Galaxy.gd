extends Node3D
class_name Galaxy

@export var planets_parent : Node3D
@onready var galaxy_visual : MeshInstance3D = $MeshInstance3D

var id : int
var display_name : String
var planets : Array[Planet]
var boundaries : Vector4 # (x: min_x, y: max_x, z: min_y, w: max_y)

func _ready() -> void:
	for planet in planets:
		planets_parent.add_child(planet)
	planets_parent.hide()

func get_planet_by_name(planet_name: String) -> Planet:
	for planet in planets:
		if planet.name == planet_name:
			return planet
	
	return null

func on_entered() -> void:
	planets_parent.show()
	galaxy_visual.hide()

func on_exited() -> void:
	planets_parent.hide()
	galaxy_visual.show()
