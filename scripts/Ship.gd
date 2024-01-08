extends Node3D
class_name Ship

## Class for some generic Ship Management things that need to be propagated around

@export var power_loss_disaster : DisasterEvent

func _ready() -> void:
	power_loss_disaster.started.connect(_on_power_loss_disaster_started)
	power_loss_disaster.ended.connect(_on_power_loss_disaster_ended)

func _on_power_loss_disaster_started() -> void:
	for power_consumer in get_tree().get_nodes_in_group(Constants.POWER_CONSUMER_GROUP):
		(power_consumer as PowerConsumer).turn_off_functionality()
	
	for power_fallback in get_tree().get_nodes_in_group(Constants.POWER_FALLBACK_GROUP):
		(power_fallback as PowerFallback).turn_on_functionality()

func _on_power_loss_disaster_ended() -> void:
	for power_consumer in get_tree().get_nodes_in_group(Constants.POWER_CONSUMER_GROUP):
		(power_consumer as PowerConsumer).turn_on_functionality()
	
	for power_fallback in get_tree().get_nodes_in_group(Constants.POWER_FALLBACK_GROUP):
		(power_fallback as PowerFallback).turn_off_functionality()
