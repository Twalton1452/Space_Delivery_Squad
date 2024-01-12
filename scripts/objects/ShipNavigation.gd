extends Node2D
class_name ShipNavigation

## Visual Representation of where the players are at in the Universe

signal reached_destination

@onready var screen = $ScreenFilter
@onready var galaxies_parent = $ScreenFilter/Galaxies
@onready var planets_parent = $ScreenFilter/Planets
@onready var paths_parent = $ScreenFilter/Paths
@onready var ship = $Ship

var target_location : Node2D
var current_location : Node2D
var speed = 5.0
var moving_tween : Tween

func _ready():
	if OS.has_feature("editor"):
		speed = 50.0
	if not Universe.generated:
		await Universe.finished_generation
	update_visuals()

#func _physics_process(delta):
	#if Input.is_action_just_pressed("ui_left"):
		#screen.position += Vector2(25.0, 0.0)
	#if Input.is_action_just_pressed("ui_right"):
		#screen.position += Vector2(-25.0, 0.0)
	#if Input.is_action_just_pressed("ui_up"):
		#screen.position += Vector2(0.0, 25.0)
	#if Input.is_action_just_pressed("ui_down"):
		#screen.position += Vector2(0.0, -25.0)

func travel_to(location: Node2D) -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.kill()
	target_location = location
	
	# With this design, the ship is always the Focal point of the screen
	var target_position = ship.global_position - target_location.position
	var distance = screen.position.distance_to(target_position)
	
	# Animate the ship rotating
	# TODO: Learn to calculate rotations
	var prev_rotation = ship.rotation
	ship.look_at(target_location.global_position)
	ship.rotation += PI/2 # Angle Correction due to how the initial rotation is pointing up
	var target_rotation = ship.rotation
	ship.rotation = prev_rotation
	
	# Rotate the Ship first for a slower feel
	# Then move the screen to make it look like the Ship is traveling
	var time_to_destination_seconds = floor(distance / speed)
	moving_tween = create_tween()
	moving_tween.tween_property(ship, "rotation", target_rotation, 1.0).set_ease(Tween.EASE_IN)
	moving_tween.tween_property(screen, "position", target_position, time_to_destination_seconds)
	moving_tween.tween_callback(_on_reached_destination)
	print("Traveling to %s. ETA %s seconds" % [target_location.name, time_to_destination_seconds])

func _on_reached_destination() -> void:
	current_location = target_location
	reached_destination.emit()
	var nodes : Array[Node2D] = []
	for galaxy in galaxies_parent.get_children():
		nodes.push_back(galaxy)
	draw_paths(nodes)

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
	
	var package_company : Node2D = galaxies_parent.get_children().front()
	var package_company_position = ship.global_position - package_company.position
	screen.position = package_company_position
	current_location = package_company
	
	var nodes : Array[Node2D] = []
	for galaxy in galaxies_parent.get_children():
		nodes.push_back(galaxy)
	draw_paths(nodes)

func draw_paths(nodes: Array[Node2D]) -> void:
	for existing_path in paths_parent.get_children():
		existing_path.queue_free()
	await get_tree().physics_frame
	
	# half the viewport's size + buffer, should draw lines to everything visible
	var distance_to_draw_path = 136.0
	var path_scene = load("res://scenes/objects/navigation/connecter_line2d.tscn")
	for node in nodes:
		if node == current_location:
			continue
		
		var dist = current_location.position.distance_to(node.position)
		#print(node.name, " distance to ship ", dist)
		if dist < distance_to_draw_path:
			var path : Line2D = path_scene.instantiate()
			path.add_point(current_location.position)
			path.add_point(node.position)
			path.name = node.name
			paths_parent.add_child(path)

func select_next_right_path() -> void:
	pass

func select_next_left_path() -> void:
	pass

func lock_in_path() -> void:
	var next = galaxies_parent.get_children().pick_random()
	while next == current_location:
		next = galaxies_parent.get_children().pick_random()
	# TODO: Path based?
	travel_to(next)
