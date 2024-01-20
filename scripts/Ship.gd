extends Node3D
class_name Ship

## Class for some generic Ship Management things that need to be propagated around

@export var navigation_console : ShipNavigationConsole
@export var outside_ship_location : Node3D

var speed = 100.0
var moving_tween : Tween
var current_galaxy : Galaxy
var current_planet : Planet

var power_loss_disaster : Event = load("res://resources/events/disasters/power_loss.tres")
var enter_galaxy_event : Event = load("res://resources/events/navigation/enter_galaxy.tres")

func _ready() -> void:
	power_loss_disaster.started.connect(_on_power_loss_disaster_started)
	power_loss_disaster.ended.connect(_on_power_loss_disaster_ended)
	enter_galaxy_event.started.connect(_on_entered_galaxy)
	enter_galaxy_event.ended.connect(_on_exited_galaxy)
	
	if multiplayer.is_server():
		navigation_console.locked_in.connect(_on_locked_in_destination)
		navigation_console.enter_galaxy_lever_pulled.connect(_on_galaxy_lever_pulled)

func _on_galaxy_lever_pulled() -> void:
	if current_galaxy != null:
		if enter_galaxy_event.occurring:
			EventManager.request_event_end(enter_galaxy_event)
		else:
			EventManager.request_event_start(enter_galaxy_event)

func _on_entered_galaxy() -> void:
	for galaxy in Universe.galaxies:
		if galaxy != current_galaxy:
			galaxy.hide()
	current_galaxy.on_entered()

func _on_exited_galaxy() -> void:
	current_galaxy.on_exited()
	for galaxy in Universe.galaxies:
		galaxy.show()
	var to_move = Universe.galaxies_parent
	var target_position = to_move.global_position + outside_ship_location.global_position - current_galaxy.global_position
	Universe.galaxies_parent.position = target_position
	current_galaxy = null

func _on_locked_in_destination(destination_name: String) -> void:
	var destination : Node3D = null
	if not enter_galaxy_event.occurring:
		destination = Universe.get_galaxy_by_name(destination_name)
	else:
		destination = current_galaxy.get_planet_by_name(destination_name)
	
	if destination == null:
		push_warning("[Ship]: attempted to lock in nonexistent destination %s " % destination_name)
		return
	
	travel_to(destination)
	
func travel_to(node: Node3D) -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.kill()
	
	moving_tween = create_tween()
	# Rotate the universe Y until aligned with outside of ship location
	# Move the galaxies X to outside the Ship
	var to_move = Universe.galaxies_parent
	
	var target_position = outside_ship_location.global_position - node.position
	var distance = target_position.length()
	var time_to_destination_seconds : float = clampf(floor(distance / speed), 1.0, 5.0)
	moving_tween.tween_property(to_move, "global_position", target_position, time_to_destination_seconds).set_ease(Tween.EASE_IN_OUT)
	moving_tween.tween_callback(func():
		if node is Galaxy:
			current_galaxy = node
		if node is Planet:
			current_planet = node
		# TODO: RPC that tells clients about the result
		#	    Also tells the navigation system to finish
	)
	navigation_console.ship_navigation.begin_traveling(time_to_destination_seconds, 0.2)

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
