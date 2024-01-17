extends Node
class_name UniverseGenerater

signal finished_generation

var min_galaxy_id = 1
var max_galaxy_id = 9999999
var galaxy_distance_multiplier = 10.0
var galaxies : Array[Galaxy] = []

var min_planet_id = 1
var max_planet_id = 9999999
var boundaries = Vector4() # (x: min_x, y: max_x, z: min_y, w: max_y)

var formations_parent = Node.new()
var galaxy_scene : PackedScene = preload("res://scenes/space/galaxy.tscn")
var planet_scene : PackedScene = preload("res://scenes/space/planet.tscn")
var formations : Array[Path2D] = [
	preload("res://scenes/formations/circular_formation.tscn").instantiate(),
	preload("res://scenes/formations/diamond_formation.tscn").instantiate(),
	preload("res://scenes/formations/far_out_formation.tscn").instantiate(),
	preload("res://scenes/formations/zig_zag_formation.tscn").instantiate(),
	preload("res://scenes/formations/spiral_formation.tscn").instantiate(),
]

func _init(game_seed: int) -> void:
	name = "UniverseGenerater"
	seed(game_seed)
	print("[%s]: set seed to %s" % [name, game_seed])

func _ready():
	await setup()
	generate()
	await tear_down()
	finished_generation.emit()

func setup() -> void:
	formations_parent.name = "Formations"
	
	
	# Have to add the Path nodes to the scene tree to sample the paths
	for formation in formations:
		formation.hide()
		formations_parent.add_child(formation)
	add_child(formations_parent)
	await get_tree().process_frame

func tear_down() -> void:
	for formation in formations_parent.get_children():
		formations_parent.remove_child(formation)
		formation.queue_free()
	await get_tree().physics_frame

func debug_print() -> void:
	print(multiplayer.get_unique_id())
	for galaxy in galaxies:
		print("[%s] %s" % [galaxy.display_name, galaxy.position])
		for planet in galaxy.planets:
			print("[%s-%s] %s" % [galaxy.display_name, planet.display_name, planet.position])
			for resident in planet.residents:
				print("[%s] %s" % [planet.display_name, resident.display_name])
	print("-----------------------------------------")

func generate_galaxy() -> Galaxy:
	var new_galaxy : Galaxy = galaxy_scene.instantiate()
	new_galaxy.id = randi_range(min_galaxy_id, max_galaxy_id)
	# Make the galaxies names appear large and mystical
	# Players could still find Galaxy_0000001 which would be exciting
	new_galaxy.name = "Galaxy_" + str(new_galaxy.id).lpad(7, "0")
	new_galaxy.display_name = "Galaxy_" + str(new_galaxy.id).lpad(7, "0")
	var planet_system_formation : Path2D = pick_random_formation()
	new_galaxy.planets = generate_planet_system(planet_system_formation)
	for planet in new_galaxy.planets:
		planet.galaxy = new_galaxy
	new_galaxy.boundaries = get_formation_boundaries(planet_system_formation)
	
	return new_galaxy

func generate_planet_system(formation: Path2D) -> Array[Planet]:
	var planets : Array[Planet] = []
	var min_planets_count = 3
	var max_planets_count = 8
	var planets_count = randi_range(min_planets_count, max_planets_count)
	var planet_formation_path : PathFollow2D = formation.get_node("PathFollow2D")
	
	for i in range(planets_count):
		var new_planet = generate_planet()
		planet_formation_path.progress_ratio = float(i) / float(planets_count)
		var spawn_position = planet_formation_path.position
		new_planet.position = Vector3(spawn_position.x, 1.0, spawn_position.y)
		planets.push_back(new_planet)
	
	return planets

func generate_planet() -> Planet:
	var new_planet : Planet = planet_scene.instantiate()
	
	new_planet.id = randi_range(min_planet_id, max_planet_id)
	# TODO: Planet names are more interesting
	new_planet.name = "Planet_" + str(new_planet.id).lpad(7, "0")
	new_planet.display_name = "Planet_" + str(new_planet.id).lpad(7, "0")
	
	var min_residents_per_planet = 1
	var max_residents_per_planet = 10
	var resident_count = randi_range(min_residents_per_planet, max_residents_per_planet)
	for _i in range(resident_count):
		var new_resident = generate_resident()
		new_resident.planet = new_planet
		new_planet.residents.push_back(new_resident)
	return new_planet

func generate_resident() -> Universe.Resident:
	var new_resident = Universe.Resident.new()
	var min_resident_id = 1
	var max_resident_id = 9999999
	
	new_resident.id = randi_range(min_resident_id, max_resident_id)
	# TODO: Resident names are more interesting
	new_resident.display_name = "Resident_" + str(new_resident.id).lpad(7, "0")
	return new_resident

func get_formation_boundaries(formation: Path2D) -> Vector4:
	var formation_boundaries = Vector4(0.0, 0.0, 0.0, 0.0)
	for point in formation.curve.get_baked_points():
		formation_boundaries.x = min(formation_boundaries.x, point.x)
		formation_boundaries.y = max(formation_boundaries.y, point.x)
		formation_boundaries.z = min(formation_boundaries.z, point.y)
		formation_boundaries.w = max(formation_boundaries.w, point.y)
	return formation_boundaries * galaxy_distance_multiplier

func pick_random_formation() -> Path2D:
	return formations_parent.get_children().pick_random()

func generate() -> void:
	var galaxy_formation : Path2D = pick_random_formation()
	var galaxy_formation_path : PathFollow2D = galaxy_formation.get_node("PathFollow2D")
	
	print("[Universe]: Using Galaxy Formation: ", galaxy_formation.name)
	boundaries = get_formation_boundaries(galaxy_formation)
	# TODO: Resource with UniverseParams for varying difficulties
	
	var galaxy_count = 5 # TODO: based on Formation? More difficult formations have more galaxies
	
	for i in range(galaxy_count):
		var new_galaxy = generate_galaxy()
		galaxy_formation_path.progress_ratio = float(i) / float(galaxy_count)
		var spawn_position = galaxy_formation_path.position * galaxy_distance_multiplier
		new_galaxy.position = Vector3(spawn_position.x, 1.0, spawn_position.y)
		galaxies.push_back(new_galaxy)
	
	# Always put the Package Company (IPP) at 0,0,0
	var package_company_galaxy : Galaxy = galaxy_scene.instantiate()
	package_company_galaxy.name = "IPP"
	package_company_galaxy.display_name = "IPP"
	package_company_galaxy.position = Vector3(-15.0, 1.0, 0.0)
	var company_planets : Array[Planet] = [] # [store, warehouse, jail, etc]
	package_company_galaxy.planets = company_planets
	galaxies.push_front(package_company_galaxy)
