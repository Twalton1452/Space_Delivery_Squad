extends Node

## Autoloaded

## TODO: Separate Generation into UniverseGeneration?

signal finished_generation

var min_galaxy_id = 1
var max_galaxy_id = 9999999
var galaxies : Array[Galaxy] = []
var generated = false

#region Space
class Galaxy:
	var id : int
	var display_name : String
	var position : Vector3
	var planets : Array[Planet]

class Planet:
	var id : int
	var display_name : String
	var position : Vector3
	var galaxy : Galaxy
	var residents : Array[Resident]
	var conditions : Array[PlanetCondition]

class PlanetCondition:
	pass
#endregion Space

#region Person
class Resident:
	var id : int
	var display_name : String
	var address : String
	var planet : Planet

class PackageInstruction:
	pass
#endregion Person

#region Component
class Package extends Node:
	var time_to_deliver : float
	var recipient : Resident
	var special_instructions : Array[PackageInstruction]
#endregion Component

func _ready():
	# TODO: Wait for game to signal it has started
	await LevelManager.changed_level
	
	# TODO: Recieve seed from server
	#seed(Time.get_date_string_from_system().hash())
	generate()
	#debug_print()

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
	var new_galaxy := Galaxy.new()
	
	new_galaxy.id = randi_range(min_galaxy_id, max_galaxy_id)
	# Make the galaxies names appear large and mystical
	# Players could still find Galaxy_0000001 which would be exciting
	new_galaxy.display_name = "Galaxy_" + str(new_galaxy.id).lpad(7, "0")
	
	# Get a position for the Galaxy based on the generated ID
	#var remapped_id = remap(new_galaxy.id, min_galaxy_id, max_galaxy_id, 0.0, 256.0)
	var x_pos = new_galaxy.id
	var y_pos = new_galaxy.id
	new_galaxy.position = Vector3(x_pos, y_pos, 0.0)
	
	var min_planets_per_galaxy = 2
	var max_planets_per_galaxy = 7
	var planet_count = randi_range(min_planets_per_galaxy, max_planets_per_galaxy)
	for _i in range(planet_count):
		var new_planet = generate_planet()
		new_planet.galaxy = new_galaxy
		new_galaxy.planets.push_back(new_planet)
	
	return new_galaxy

func generate_planet() -> Planet:
	var new_planet = Planet.new()
	var min_planet_id = 1
	var max_planet_id = 9999999
	
	new_planet.id = randi_range(min_planet_id, max_planet_id)
	# TODO: Planet names are more interesting
	new_planet.display_name = "Planet_" + str(new_planet.id).lpad(7, "0")
	
	# Get a position for the Galaxy based on the generated ID
	#var remapped_id = remap(new_planet.id, min_planet_id, max_planet_id, 0.0, 256.0)
	var x_pos = new_planet.id
	var y_pos = new_planet.id
	new_planet.position = Vector3(x_pos, y_pos, 0.0)
	
	var min_residents_per_planet = 1
	var max_residents_per_planet = 10
	var resident_count = randi_range(min_residents_per_planet, max_residents_per_planet)
	for _i in range(resident_count):
		var new_resident = generate_resident()
		new_resident.planet = new_planet
		new_planet.residents.push_back(new_resident)
	return new_planet

func generate_resident() -> Resident:
	var new_resident = Resident.new()
	var min_resident_id = 1
	var max_resident_id = 9999999
	
	new_resident.id = randi_range(min_resident_id, max_resident_id)
	# TODO: Resident names are more interesting
	new_resident.display_name = "Resident_" + str(new_resident.id).lpad(7, "0")
	return new_resident

func generate() -> void:
	if generated:
		return
	
	# TODO: Resource with UniverseParams for varying difficulties
	var min_galaxies := 5
	var max_galaxies := 10
	
	var galaxy_count = randi_range(min_galaxies, max_galaxies)
	for _galaxy_i in range(galaxy_count):
		var new_galaxy = generate_galaxy()
		galaxies.push_back(new_galaxy)
	
	generated = true
	finished_generation.emit()
