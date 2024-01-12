extends Node2D
class_name ShipNavigation

## Visual Representation of where the players are at in the Universe

signal reached_destination

@onready var galaxies_parent = $ScreenFilter/Galaxies
@onready var planets_parent = $ScreenFilter/Planets
@onready var ship = $ScreenFilter/Ship

var target_destination : Node2D
var speed = 3.0
var moving_tween : Tween

func _ready():
	if OS.has_feature("editor"):
		speed = 10.0
	
	if not Universe.generated:
		await Universe.finished_generation
	update_visuals()

func travel_to(destination: Node2D) -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.kill()
	moving_tween = create_tween()
	target_destination = destination
	
	# With this design, the ship is always the Focal point of the screen
	var target_position = ship.global_position - target_destination.position
	var distance = galaxies_parent.position.distance_to(target_position)
	
	# Animate the ship rotating
	# TODO: Learn to calculate rotations
	var prev_rotation = ship.rotation
	ship.look_at(destination.global_position)
	ship.rotation += PI/2 # Angle Correction due to how the initial rotation is pointing up
	var target_rotation = ship.rotation
	ship.rotation = prev_rotation
	
	var time_to_destination_seconds = floor(distance / speed)
	moving_tween.tween_property(ship, "rotation", target_rotation, 1.0).set_ease(Tween.EASE_IN)
	moving_tween.tween_property(galaxies_parent, "position", target_position, time_to_destination_seconds)
	moving_tween.tween_callback(_on_reached_destination)
	print("Traveling to %s. ETA %s seconds" % [destination.name, time_to_destination_seconds])

func _on_reached_destination() -> void:
	reached_destination.emit()

func remap_position_to_screen(galaxy: Universe.Galaxy) -> Vector2:
	var x_pos = remap(galaxy.position.x, Universe.boundaries.x, Universe.boundaries.y, 0.0, 256.0)
	var y_pos = remap(galaxy.position.y, Universe.boundaries.z, Universe.boundaries.w, 0.0, 256.0)
	return Vector2(x_pos, y_pos)

func update_visuals() -> void:
	var galaxy_scene = load("res://scenes/objects/navigation/galaxy.tscn")
	for i in range(Universe.galaxies.size()):
		var visual_galaxy = galaxy_scene.instantiate()
		var physical_galaxy = Universe.galaxies[i]
		
		visual_galaxy.position = remap_position_to_screen(physical_galaxy)
		visual_galaxy.name = physical_galaxy.display_name
		visual_galaxy.get_node("Label").text = physical_galaxy.display_name
		galaxies_parent.add_child(visual_galaxy)
		
		#print("[RADAR]: Adding Galaxy ", visual_galaxy.name, " with Position ", visual_galaxy.position)
	
	var package_company_position = ship.global_position - galaxies_parent.get_children().front().position
	galaxies_parent.position = package_company_position

func select_next_right_path() -> void:
	pass

func select_next_left_path() -> void:
	pass

func lock_in_path() -> void:
	# TODO: Path based?
	travel_to(galaxies_parent.get_children().pick_random())
