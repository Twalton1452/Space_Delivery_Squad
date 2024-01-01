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


func _ready():
	# Autoloads are running when the application starts
	# Disable Tick rates until level changes, preferably to something playable
	set_physics_process(false)

# Called from Main.gd when the Host button is pressed
# Listening for a "server_created" signal would be better
func enable() -> void:
	set_physics_process(true)

func _physics_process(_delta):
	if not is_multiplayer_authority():
		return
		
	if Engine.get_physics_frames() % Constants.TICK_INTERACT:
		InteractHandler.process_queue()
	
	if Engine.get_physics_frames() % Constants.TICK_PICKUP:
		PickupHandler.process_queue()
	
	if Engine.get_physics_frames() % Constants.TICK_DROP:
		DropHandler.process_queue()
	
	if Engine.get_physics_frames() % Constants.TICK_RELEASE:
		ReleaseHandler.process_queue()
