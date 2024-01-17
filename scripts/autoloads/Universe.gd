extends Node

## Autoloaded

## TODO: Separate Generation into UniverseGeneration.gd?

signal generated

var boundaries = Vector4() # (x: min_x, y: max_x, z: min_y, w: max_y)
var galaxies : Array[Galaxy] = []
var game_seed : int
var is_generated = false

#region Person
class Resident:
	var id : int
	var display_name : String
	var address : String
	var planet : Planet
#endregion Person

@rpc("authority", "call_remote", "reliable")
func broadcast_seed_to_players(server_game_seed: int) -> void:
	game_seed = server_game_seed
	seed(game_seed)
	generate_universe()

func _on_peer_connected(p_id: int) -> void:
	if multiplayer.is_server():
		broadcast_seed_to_players.rpc_id(p_id, game_seed)

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	# TODO: Wait for game to signal it has started
	# This is a temporary workaround
	await LevelManager.changed_level
	if multiplayer.is_server():
		game_seed = Time.get_time_string_from_system().hash()
		broadcast_seed_to_players.rpc(game_seed)
		generate_universe()

func generate_universe() -> void:
	is_generated = false
	# Allow for regenerating the Universe, likely only a debugging thing
	for child in get_children():
		remove_child(child)
		child.queue_free()
	await get_tree().physics_frame
	
	var generater = UniverseGenerater.new(game_seed)
	
	# Start Generation
	# The Generater requires adding nodes to the tree
	# So starting the process is tied to adding the Generater to the tree
	add_child(generater)
	await generater.finished_generation
	
	# Take the Generated values we need
	boundaries = generater.boundaries
	galaxies = generater.galaxies
	for galaxy in galaxies:
		add_child(galaxy)
	
	# End Generation
	# Let a frame pass for setup/tear down reasons
	remove_child(generater)
	generater.queue_free()
	await get_tree().physics_frame
	
	print("[%s]: %s Finished Generation (seed: %s)" % [name, multiplayer.get_unique_id(), game_seed])
	is_generated = true
	generated.emit()

func get_package_company() -> Galaxy:
	return galaxies[0]

func get_galaxy_by_id(id: int) -> Galaxy:
	for galaxy in galaxies:
		if galaxy.id == id:
			return galaxy
	return null

func get_galaxy_by_name(galaxy_name: String) -> Galaxy:
	for galaxy in galaxies:
		if galaxy.display_name == galaxy_name:
			return galaxy
	return null

func get_random_resident() -> Resident:
	# Skip IPP at index 0
	var galaxy = Universe.galaxies[randi_range(1, Universe.galaxies.size() - 1)]
	var planet = galaxy.planets.pick_random()
	return planet.residents.pick_random()
