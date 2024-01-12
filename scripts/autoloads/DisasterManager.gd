extends Node

## Autoload
## A starting point for Disasters to Trigger
## Functions return booleans to signify if it was successful in what it set out to do

var disasters : Array[Event] = [
	preload("res://resources/disasters/airlock.tres"),
	preload("res://resources/disasters/power_loss.tres")
]

#region Client/Server RPCs
@rpc("authority", "call_remote", "reliable")
func broadcast_disaster_event_start(disaster_index: int) -> void:
	var disaster_event = disasters[disaster_index]
	if disaster_event.occurring:
		return
	start_disaster(disaster_event)

@rpc("authority", "call_remote", "reliable")
func broadcast_disaster_event_end(disaster_index: int) -> void:
	var disaster_event = disasters[disaster_index]
	if not disaster_event.occurring:
		return
	end_disaster(disaster_event)
#endregion Client/Server RPCs

func register_listener(listener: DisasterListener) -> void:
	listener.conditions_met.connect(_on_listener_conditions_met)
	listener.conditions_unmet.connect(_on_listener_conditions_unmet)

func unregister_listener(listener: DisasterListener) -> void:
	if listener.conditions_met.is_connected(_on_listener_conditions_met):
		listener.conditions_met.disconnect(_on_listener_conditions_met)
	if listener.conditions_unmet.is_connected(_on_listener_conditions_unmet):
		listener.conditions_unmet.disconnect(_on_listener_conditions_unmet)

func _on_listener_conditions_met(listener: DisasterListener) -> void:
	if listener.disaster_event.occurring:
		return
	
	if multiplayer.is_server():
		start_disaster(listener.disaster_event)
		var disaster_index = disasters.find(listener.disaster_event)
		broadcast_disaster_event_start.rpc(disaster_index)

func _on_listener_conditions_unmet(listener: DisasterListener) -> void:
	if not listener.disaster_event.occurring:
		return
	
	if multiplayer.is_server():
		end_disaster(listener.disaster_event)
		var disaster_index = disasters.find(listener.disaster_event)
		broadcast_disaster_event_end.rpc(disaster_index)

func start_disaster(which: Event) -> void:
	which.start()

func end_disaster(which: Event) -> void:
	which.end()
