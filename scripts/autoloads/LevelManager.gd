extends Node

## Autoloaded

signal changed_level

var level_store : LevelStore = load("res://resources/StandardLevels.tres")

@onready var level_parent : Node = $Level
@onready var level_spawner : MultiplayerSpawner = $LevelSpawner
@onready var level_change_audio_player : AudioStreamPlayer = $LevelChangeSFX

var current_level_index = 0
var current_level: Node = null
var is_changing_levels = false

@rpc("authority", "call_local", "reliable")
func notify_everyone_changing_level() -> void:
	disable_player_syncing()

func _ready():
	# when exporting, make sure it has the correct levels
	if OS.has_feature("standalone"):
		level_store = load("res://resources/StandardLevels.tres")
	
	# Avoid needing to set the MultiplayerSpawner scenes manually
	var level_spawn_paths = []
	for level in level_store.levels:
		level_spawn_paths.push_back(level.resource_path)
	level_spawner._spawnable_scenes = level_spawn_paths

func go_to_first_level() -> void:
	current_level_index = 0
	change_level.call_deferred(level_store.levels[current_level_index])

func go_to_next_level() -> void:
	if current_level_index < level_store.levels.size() - 1:
		current_level_index += 1
		change_level.call_deferred(level_store.levels[current_level_index])
	else:
		go_to_first_level()

func go_to_previous_level() -> void:
	if current_level_index == 0:
		current_level_index = level_store.levels.size() - 1
	else:
		current_level_index -= 1
	change_level.call_deferred(level_store.levels[current_level_index])

func reset_level() -> void:
	change_level.call_deferred(level_store.levels[current_level_index])

func _on_finished_level() -> void:
	go_to_next_level()

func prepare_first_level_async() -> void:
	prepare_level_async(level_store.levels[0])

func prepare_level_async(scene: PackedScene) -> void:
	# Already loaded this scene and it's cached
	if ResourceLoader.load_threaded_get_status(scene.resource_path) == ResourceLoader.THREAD_LOAD_LOADED:
		return
	
	#print("Preparing level: ", scene.resource_path)
	ResourceLoader.load_threaded_request(scene.resource_path, "PackedScene")

func fetch_level_async(scene: PackedScene) -> PackedScene:
	#print("Fetching level ", scene.resource_path)
	if ResourceLoader.has_cached(scene.resource_path):
		return ResourceLoader.load_threaded_get(scene.resource_path)
	
	var progress = []
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene.resource_path, progress)
		#print("Loading ", scene.resource_path, " ", progress[0] * 100.0, "%")
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			#print("Finished loading ", scene.resource_path)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load ", scene.resource_path)
			return null
		
		await get_tree().process_frame
		
	return ResourceLoader.load_threaded_get(scene.resource_path)

func clear_level() -> void:
	# Remove old level if any.
	if current_level == null:
		return
	
	current_level.process_mode = Node.PROCESS_MODE_DISABLED
	
	if current_level.has_signal("finished_level") and current_level.finished_level.is_connected(_on_finished_level):
		current_level.finished_level.disconnect(_on_finished_level)
	
	for c in level_parent.get_children():
		level_parent.remove_child(c)
		c.queue_free()

	current_level.queue_free()
	
	# Let the game world clean up
	await get_tree().physics_frame
	await get_tree().physics_frame

# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	if not is_multiplayer_authority():
		return
	
	if not scene.resource_path in level_spawner._spawnable_scenes:
		push_warning("You forgot to add ", scene.resource_path, " to the list of spawnable scenes on the LevelSpawner. \
		It probably won't spawn for peers")
	
	notify_everyone_changing_level.rpc()
	is_changing_levels = true
	level_change_audio_player.play()
	
	# Background loading
	prepare_level_async(scene)
	# Wait for screen to fade to hide the inner workings from players
	await Transition.fade_out()
	await clear_level()
	
	# Add new level.
	var next_level = await fetch_level_async(scene)
	if next_level == null:
		get_tree().quit(-1)
		return
	current_level = next_level.instantiate()
	level_parent.add_child(current_level)
	current_level.show()
	
	Transition.fade_in()
	
	# Wait for players to complete the level
	if current_level.has_signal("finished_level") and !current_level.finished_level.is_connected(_on_finished_level):
		current_level.finished_level.connect(_on_finished_level)
	is_changing_levels = false
	changed_level.emit()

# The server can restart the level by pressing Home. Mostly for debugging
func _unhandled_input(event):
	if not is_multiplayer_authority() or is_changing_levels:
		return
	
	if event.is_action_pressed("restart_level"):
		reset_level()
	elif event.is_action_pressed("next_level"):
		go_to_next_level()
	elif event.is_action_pressed("previous_level"):
		go_to_previous_level()

func _on_level_spawner_spawned(node):
	current_level = node
	current_level_index += 1 # unlikely to always work
	level_change_audio_player.play()
	
	# If the level is loaded in faster than we can fade out, hide it
	if Transition.in_progress:
		current_level.hide()
		await Transition.finished
	
	# Show the level since the screen should be faded out by this point
	current_level.show()
	Transition.fade_in()
	changed_level.emit()

func disable_player_syncing() -> void:
	pass
