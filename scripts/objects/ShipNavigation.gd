extends Node2D
class_name ShipNavigation

## Visual Representation of where the players are at in the Universe without going outside

signal reached_destination
signal locked_in_destination(destination: Node3D)

const NOT_SELECTED_PATH_WIDTH = 10
const SELECTED_PATH_WIDTH = 30

@onready var screen = $ScreenFilter
@onready var galaxies_parent = $ScreenFilter/Galaxies
@onready var planets_parent = $ScreenFilter/Planets
@onready var paths_parent = $ScreenFilter/Paths
@onready var ship = $Ship

var enter_galaxy_event : Event = load("res://resources/events/navigation/enter_galaxy.tres")
var path_scene = load("res://scenes/objects/navigation/connecter_line2d.tscn")
var distance_to_draw_path = 150.0
var target_location : Node2D
var current_location : Node2D
var speed = 5.0
var moving_tween : Tween
var selected_path = 0
var inside_galaxy : Node2D = null
## Since the Galaxies are always loaded, I've separated the parents for Galaxies/Planets out from the Screen
## Use the Planets parent if we're inside a Galaxy otherwise operate on the Galaxies parent
var contextual_parent : Node2D : 
	get:
		if inside_galaxy != null:
			return planets_parent
		else:
			return galaxies_parent

func _ready():
	enter_galaxy_event.started.connect(_on_enter_galaxy)
	enter_galaxy_event.ended.connect(_on_exit_galaxy)
	if OS.has_feature("editor"):
		speed = 50.0
	if not Universe.is_generated:
		await Universe.generated
	draw_galaxies()

func pause_travel() -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.pause()

func unpause_travel() -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.play()

#func _physics_process(delta):
	#if Input.is_action_just_pressed("ui_left"):
		#screen.position += Vector2(25.0, 0.0)
	#if Input.is_action_just_pressed("ui_right"):
		#screen.position += Vector2(-25.0, 0.0)
	#if Input.is_action_just_pressed("ui_up"):
		#screen.position += Vector2(0.0, 25.0)
	#if Input.is_action_just_pressed("ui_down"):
		#screen.position += Vector2(0.0, -25.0)

func begin_traveling(seconds_to_destination: float, seconds_to_rotate: float) -> void:
	var destination : Node2D
	var selected_path_name = paths_parent.get_children()[selected_path].name
	for child in contextual_parent.get_children():
		if child.name == selected_path_name:
			destination = child
	if destination == null:
		return
	
	travel_to(destination, seconds_to_destination, seconds_to_rotate)

func travel_to(location: Node2D, seconds_to_destination: float, seconds_to_rotate: float) -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.kill()
	target_location = location
	
	# The ship is the Focal point of the screen
	var target_position = ship.global_position - target_location.position
	
	# Animate the ship rotating
	# TODO: Learn to calculate rotations
	var prev_rotation = ship.rotation
	ship.look_at(target_location.global_position)
	ship.rotation += PI/2 # Angle Correction due to how the initial rotation is pointing up
	var target_rotation = ship.rotation
	ship.rotation = prev_rotation
	
	# Rotate the Ship first for a slower feel
	# Then move the screen to make it look like the Ship is traveling
	moving_tween = create_tween()
	moving_tween.tween_property(ship, "rotation", target_rotation, seconds_to_rotate).set_ease(Tween.EASE_IN)
	moving_tween.tween_property(screen, "position", target_position, seconds_to_destination)
	moving_tween.tween_callback(_on_reached_destination)
	print("Traveling to %s. ETA %s seconds" % [target_location.name, seconds_to_destination])

func _on_enter_galaxy() -> void:
	inside_galaxy = current_location
	# TODO: more deterministic, current_location could be desyncd from clients
	var entered_galaxy : Galaxy = Universe.get_galaxy_by_name(current_location.name)
	galaxies_parent.hide()
	print("Now Entering Galaxy ", entered_galaxy.display_name, " Planet count: ", entered_galaxy.planets.size())
	draw_planets_in(entered_galaxy)
	entered_galaxy.on_entered()
	planets_parent.show()

func _on_exit_galaxy() -> void:
	galaxies_parent.show()
	planets_parent.hide()
	screen.position = ship.global_position - inside_galaxy.position
	current_location = inside_galaxy
	inside_galaxy = null
	
	var nodes : Array[Node2D] = []
	for child in contextual_parent.get_children():
		nodes.push_back(child)
	draw_paths_clockwise(nodes)

func _on_reached_destination() -> void:
	current_location = target_location
	reached_destination.emit()
	var nodes : Array[Node2D] = []
	for child in contextual_parent.get_children():
		nodes.push_back(child)
	draw_paths_clockwise(nodes)

func draw_path_to(node: Node2D) -> void:
	# Make sure the path doesn't exist already
	if paths_parent.get_node_or_null(NodePath(node.name)) != null:
		return
	
	var path : Line2D = path_scene.instantiate()
	path.add_point(current_location.position)
	path.add_point(node.position)
	path.name = node.name
	paths_parent.add_child(path)

func select_path(index : int, reset_last_path = true) -> void:
	if paths_parent.get_child_count() == 0:
		return
	
	if reset_last_path:
		var previous_path : Line2D = paths_parent.get_children()[selected_path]
		previous_path.width = NOT_SELECTED_PATH_WIDTH
	
	selected_path = index % paths_parent.get_child_count()
	
	var next_path : Line2D = paths_parent.get_children()[selected_path]
	next_path.width = SELECTED_PATH_WIDTH

func select_next_right_path() -> void:
	select_path(selected_path + 1)

func select_next_left_path() -> void:
	# Lines were not getting reset correctly
	# I think because negative indexing is allowed similar to python
	# Just manually wrap it around for now
	var next_left = paths_parent.get_child_count() - 1 if selected_path - 1 < 0 else selected_path - 1
	select_path(next_left)

func lock_in_path() -> String:
	if paths_parent.get_child_count() == 0:
		reached_destination.emit()
		return ""
	
	var selected_path_name = paths_parent.get_children()[selected_path].name
	for child in contextual_parent.get_children():
		if child.name == selected_path_name:
			return selected_path_name
	
	return ""

func remap_position_to_screen(pos: Vector3, boundaries: Vector4) -> Vector2:
	var x_pos = remap(pos.x, boundaries.x, boundaries.y, 0.0, 256.0)
	var y_pos = remap(pos.z, boundaries.z, boundaries.w, 0.0, 256.0)
	return Vector2(x_pos, y_pos)

func draw_planets_in(galaxy: Galaxy) -> void:
	for child in planets_parent.get_children():
		planets_parent.remove_child(child)
		child.queue_free()
	
	var planet_scene = load("res://scenes/objects/navigation/planet.tscn")
	for physical_planet in galaxy.planets:
		var visual_planet = planet_scene.instantiate()
		
		visual_planet.position = remap_position_to_screen(physical_planet.position, galaxy.boundaries)
		visual_planet.name = physical_planet.display_name
		visual_planet.get_node("Label").text = physical_planet.display_name
		planets_parent.add_child(visual_planet)
	
	var nodes : Array[Node2D] = []
	for planet in planets_parent.get_children():
		nodes.push_back(planet)
	draw_paths_clockwise(nodes)

func draw_galaxies() -> void:
	# Manually draw the Package Company because it's special
	var visual_package_company : Node2D = load("res://scenes/objects/navigation/package_company.tscn").instantiate()
	var physical_package_company : Galaxy = Universe.get_package_company()
	visual_package_company.position = remap_position_to_screen(physical_package_company.position, Universe.boundaries)
	visual_package_company.name = physical_package_company.display_name
	visual_package_company.get_node("Label").text = physical_package_company.display_name
	galaxies_parent.add_child(visual_package_company)
	var visual_package_company_position = ship.global_position - visual_package_company.position
	screen.position = visual_package_company_position
	current_location = visual_package_company
	
	# Draw the rest of the Universe
	var galaxy_scene = load("res://scenes/objects/navigation/galaxy.tscn")
	for i in range(1, Universe.galaxies.size()):
		var visual_galaxy = galaxy_scene.instantiate()
		var physical_galaxy = Universe.galaxies[i]
		
		visual_galaxy.position = remap_position_to_screen(physical_galaxy.position, Universe.boundaries)
		visual_galaxy.name = physical_galaxy.display_name
		visual_galaxy.get_node("Label").text = physical_galaxy.display_name
		galaxies_parent.add_child(visual_galaxy)
	
	var nodes : Array[Node2D] = []
	for galaxy in galaxies_parent.get_children():
		nodes.push_back(galaxy)
	draw_paths_clockwise(nodes)

func get_in_range_nodes(nodes: Array[Node2D], max_distance: float) -> Array[Node2D]:
	return nodes.filter(func(node: Node2D): return node.position.distance_to(current_location.position) < max_distance and node != current_location)

## Gets all the nodes in range of the current location then sorts them in clockwise order
## Adding them in that order as children of the Paths Parent
func draw_paths_clockwise(nodes: Array[Node2D]) -> void:
	for existing_path in paths_parent.get_children():
		paths_parent.remove_child(existing_path)
		existing_path.queue_free()
	
	# First: March the Quadrants of the screen clockwise using the current_location as the center point
	# Second: Once inside the Quadrant, sort the nodes from closest to farthest
	# This will put the paths in clockwise order to make scrolling them as simple as +/- 1 index on the children
	var in_range_nodes : Array[Node2D] = get_in_range_nodes(nodes, 10000.0)
	#var in_range_nodes : Array[Node2D] = get_in_range_nodes(nodes, distance_to_draw_path)
	#if in_range_nodes.size() == 0:
		#in_range_nodes = get_in_range_nodes(nodes, distance_to_draw_path * 2)
	
	# Top Right Quadrant
	var top_right_nodes = in_range_nodes.filter(func(node: Node2D):
		return \
		node.position.x >= current_location.position.x and \
		node.position.y <= current_location.position.y
	)
	top_right_nodes.sort_custom(func(a, b): return a.position.x < b.position.x and a.position.y < b.position.y)
	for node in top_right_nodes:
		draw_path_to(node)
	
	# Bottom Right Quadrant
	var bottom_right_nodes = in_range_nodes.filter(func(node: Node2D):
		return \
		node.position.x >= current_location.position.x and \
		node.position.y >= current_location.position.y
	)
	bottom_right_nodes.sort_custom(func(a, b): return a.position.y < b.position.y and a.position.x > b.position.x)
	for node in bottom_right_nodes:
		draw_path_to(node)
	
	# Bottom Left Quadrant
	var bottom_left_nodes = in_range_nodes.filter(func(node: Node2D):
		return \
		node.position.x <= current_location.position.x and \
		node.position.y >= current_location.position.y
	)
	bottom_left_nodes.sort_custom(func(a, b): return a.position.x > b.position.x and a.position.y > b.position.y)
	for node in bottom_left_nodes:
		draw_path_to(node)
	
	# Top Left Quadrant
	var top_left_nodes = in_range_nodes.filter(func(node: Node2D):
		return \
		node.position.x <= current_location.position.x and \
		node.position.y <= current_location.position.y
	)
	top_left_nodes.sort_custom(func(a, b): return a.position.x < b.position.x)
	for node in top_left_nodes:
		draw_path_to(node)
	
	select_path(0, false)
