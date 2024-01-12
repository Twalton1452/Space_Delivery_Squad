extends Node

## Autoload
## A starting point for Events to Trigger
## Functions return booleans to signify if it was successful in what it set out to do

var events : Array[Event] = [
	preload("res://resources/events/disasters/airlock.tres"),
	preload("res://resources/events/disasters/power_loss.tres"),
	preload("res://resources/events/navigation/enter_galaxy.tres"),
]

#region Client/Server RPCs
@rpc("authority", "call_remote", "reliable")
func broadcast_event_start(event_index: int) -> void:
	var event = events[event_index]
	if event.occurring:
		return
	_start_event(event)

@rpc("authority", "call_remote", "reliable")
func broadcast_event_end(event_index: int) -> void:
	var event = events[event_index]
	if not event.occurring:
		return
	_end_event(event)
#endregion Client/Server RPCs

func request_event_start(which: Event) -> void:
	if multiplayer.is_server():
		var event_index = events.find(which)
		broadcast_event_start.rpc(event_index)
		_start_event(which)

func request_event_end(which: Event) -> void:
	if multiplayer.is_server():
		var event_index = events.find(which)
		broadcast_event_end.rpc(event_index)
		_end_event(which)

func register_listener(listener: EventListener) -> void:
	listener.conditions_met.connect(_on_listener_conditions_met)
	listener.conditions_unmet.connect(_on_listener_conditions_unmet)

func unregister_listener(listener: EventListener) -> void:
	if listener.conditions_met.is_connected(_on_listener_conditions_met):
		listener.conditions_met.disconnect(_on_listener_conditions_met)
	if listener.conditions_unmet.is_connected(_on_listener_conditions_unmet):
		listener.conditions_unmet.disconnect(_on_listener_conditions_unmet)

func _on_listener_conditions_met(listener: EventListener) -> void:
	if listener.event.occurring:
		return
	
	request_event_start(listener.event)

func _on_listener_conditions_unmet(listener: EventListener) -> void:
	if not listener.event.occurring:
		return
	
	request_event_end(listener.event)

func _start_event(which: Event) -> void:
	which.start()

func _end_event(which: Event) -> void:
	which.end()
