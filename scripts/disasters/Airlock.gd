extends DisasterListener

@export_category("Disaster Cause")
@export var door_to_airlock : Door
@export var airlock_door : Door

func _ready() -> void:
	door_to_airlock.opened.connect(_on_door_open)
	airlock_door.opened.connect(_on_door_open)
	
	door_to_airlock.closed.connect(_on_door_close)
	airlock_door.closed.connect(_on_door_close)

func begin_condition() -> bool:
	return door_to_airlock.is_open and airlock_door.is_open

func end_condition() -> bool:
	return not door_to_airlock.is_open or not airlock_door.is_open

func _on_door_open() -> void:
	if begin_condition():
		notify_conditions_were_met()

func _on_door_close() -> void:
	if end_condition():
		notify_conditions_were_unmet()
