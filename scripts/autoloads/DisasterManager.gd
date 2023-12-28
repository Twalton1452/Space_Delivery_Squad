extends Node

## Autoload
## A starting point for Disasters to Trigger
## Functions return booleans to signify if it was successful in what it set out to do

enum Disasters {
	AIRLOCK,
}

func start_disaster(which: Disasters) -> bool:
	match which:
		Disasters.AIRLOCK:
			return begin_airlock_disaster()
	return false

func end_disaster(which: Disasters) -> bool:
	match which:
		Disasters.AIRLOCK:
			return end_airlock_disaster()
	return false

func begin_airlock_disaster() -> bool:
	print("[DISASTER] AIRLOCK STARTED")
	# Instantiate Airlock Disaster Node that handles the Disaster?
	
	for player in PlayerManager.get_players():
		player.turn_flags_on(Player.Flags.OXYGEN_DEPLETING)
		# Apply force to every moveable object toward airlock door
		# Siren
	return true

func end_airlock_disaster() -> bool:
	print("[DISASTER] AIRLOCK ENDED")
	for player in PlayerManager.get_players():
		player.turn_flags_off(Player.Flags.OXYGEN_DEPLETING)
		# End Siren
	return true
