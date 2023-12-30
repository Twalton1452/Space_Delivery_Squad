extends Node

## Autoloaded

## This class will run every network frame (currently operating on the Physics Process)
## Which will decide if it needs to Tick Handlers to evaluate their queue's

## TODO: In the future this could capture a WorldState
##		 Which would have state they were performing on a network frame:
##		 	- Player's Positions
##		 	- Player's Rotations
##		 	- Player's Actions they were performing
##		 If we detected a desync between client/server we could send them the WorldState since the desync

var ready_to_turn_on = false

func _ready():
	if not ready_to_turn_on:
		return
	
	# Autoloads are running when the application starts
	# Disable Tick rates until level changes, preferably to something playable
	set_physics_process(false)
	await LevelManager.changed_level
	set_physics_process(true)

func _physics_process(_delta):
	if not is_multiplayer_authority():
		return
	
	if Engine.get_physics_frames() % Constants.TICK_DROP:
		DropHandler.process_queue()
