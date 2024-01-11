extends Node2D
class_name Radar

@onready var galaxies_parent = $Galaxies
@onready var planets_parent = $Planets

## Visual Representation of where the players are at in the Universe

func _ready():
	if not Universe.generated:
		await Universe.finished_generation
	spawn_visuals()

func spawn_visuals() -> void:
	var galaxy_scene : PackedScene = load("res://scenes/objects/radar/galaxy.tscn")
	for galaxy in Universe.galaxies:
		var visual_galaxy : Sprite2D = galaxy_scene.instantiate()
		visual_galaxy.position = remap_position_to_radar_screen(galaxy.position.x, galaxy.position.y)
		visual_galaxy.get_node("Label").text = galaxy.display_name
		galaxies_parent.add_child(visual_galaxy)
		
		# TODO: Only spawn planets for the galaxy we're in
		#for planet in galaxy.planets:
			#var visual_planet : Sprite2D = galaxy_scene.instantiate()
			#visual_planet.position = remap_position_to_radar_screen(visual_planet.position.x, visual_planet.position.y)
			#planets_parent.add_child(visual_planet)
	#planets_parent.hide()

func remap_position_to_radar_screen(x: float, y: float) -> Vector2:
	# This is a remapping to the viewport at the moment
	# TODO: Let it be raw positions with more reasonable numbers. 
	# Currently positions varying from 1 - 9,999,999
	# Reduce it down and then just lerp between galaxies based on a speed
	var remapped_x = remap(x, Universe.min_galaxy_id, Universe.max_galaxy_id, 0.0, 256.0)
	var remapped_y = remap(y, Universe.min_galaxy_id, Universe.max_galaxy_id, 0.0, 256.0)
	return Vector2(remapped_x, remapped_y)
