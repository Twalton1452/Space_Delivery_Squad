extends Node

## Autoload
## A starting point for Disasters to Trigger
## Functions return booleans to signify if it was successful in what it set out to do

var disasters : Array[DisasterEvent] = [
	preload("res://resources/disasters/airlock.tres"),
	preload("res://resources/disasters/power_loss.tres")
]

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
	
	start_disaster(listener.disaster_event)

func _on_listener_conditions_unmet(listener: DisasterListener) -> void:
	if not listener.disaster_event.occurring:
		return
	
	end_disaster(listener.disaster_event)

func start_disaster(which: DisasterEvent) -> void:
	which.start()

func end_disaster(which: DisasterEvent) -> void:
	which.end()
