extends Node

@export_category("Disaster Cause")
@export var door_to_airlock : Door
@export var airlock_door : Door

var disaster_occurring = false

func _ready() -> void:
	door_to_airlock.open.connect(_on_door_open)
	airlock_door.open.connect(_on_door_open)
	
	door_to_airlock.close.connect(_on_door_close)
	airlock_door.close.connect(_on_door_close)

#region Future DisasterListener class
func begin_condition() -> bool:
	return door_to_airlock.opened and airlock_door.opened

func end_condition() -> bool:
	return not door_to_airlock.opened or not airlock_door.opened

func begin_disaster() -> void:
	disaster_occurring = DisasterManager.start_disaster(DisasterManager.Disasters.AIRLOCK)

func end_disaster() -> void:
	disaster_occurring = !DisasterManager.end_disaster(DisasterManager.Disasters.AIRLOCK)
#endregion Future DisasterListener class

func _on_door_open() -> void:
	if begin_condition():
		if not disaster_occurring:
			begin_disaster()

func _on_door_close() -> void:
	if end_condition():
		if disaster_occurring:
			end_disaster()
