extends Node3D
class_name HeavyObject

## Objects that should be carried by multiple people

@export var grabbable_areas : Array[Interactable]
@export var tolerance_areas : Array[Area3D]
@export var offset = Vector3()
@export var no_grabbers_rotation := Vector3.ZERO
@export var full_grabbers_rotation := Vector3.ZERO

var original_interactable_positions : Array[Vector3]
var holding_players : Array[Player] # Midpoint calcs

func _ready() -> void:
	for grabbable in grabbable_areas:
		grabbable.interacted.connect(_on_grabbable_interacted)
		original_interactable_positions.push_back(grabbable.position)
	for tolerance_area in tolerance_areas:
		tolerance_area.body_exited.connect(_on_tolerance_area_exited)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

## Avoid issues with players disconnecting while holding the object
func _on_peer_disconnected(peer_id: int) -> void:
	var i = 0
	var found = false
	for holding_player in holding_players:
		if holding_player == null or holding_player.is_queued_for_deletion():
			found = true
			break
		i += 1
	
	if found:
		holding_players.remove_at(i)
	else:
		holding_players.erase(PlayerManager.get_player_by_id(peer_id))

func _on_grabbable_interacted(interactable: Interactable, interacter: Player) -> void:
	if interacter.get_held_node() != null:
		return
	
	# Object is too heavy/large for player to interact with anything else
	interactable.disable()
	interacter.interacter.disable()
	interacter.global_position = interactable.global_position
	
	# Hold the Interacted Area
	interacter.hold(interactable.get_path())
	
	# Toggle the Tolerance zones on
	var corresponding_tolerance_index = grabbable_areas.find(interactable)
	enable_tolerance_area(tolerance_areas[corresponding_tolerance_index])
	
	holding_players.push_back(interacter)
	
	# Player is carrying this HeavyObject
	await interacter.dropped_something
	disable_tolerance_area(tolerance_areas[corresponding_tolerance_index])
	
	holding_players.erase(interacter)
	# Need to wait for the network to handle its business
	await get_tree().physics_frame
	
	# Place the interactable back
	interactable.enable()
	interactable.position = original_interactable_positions[corresponding_tolerance_index]
	interactable.rotation = Vector3.ZERO

func enable_tolerance_area(area: Area3D) -> void:
	area.collision_mask = Constants.PLAYER_LAYER

func disable_tolerance_area(area: Area3D) -> void:
	area.collision_mask = 0

func _on_tolerance_area_exited(exiter):
	if exiter is Player and exiter in holding_players:
		exiter.drop()

func _physics_process(_delta):
	if holding_players.size() <= 1:
		return
	
	var mid_point = Vector3.ZERO
	for holding_player in holding_players:
		mid_point += holding_player.global_position
	mid_point = (mid_point / holding_players.size()) + offset
	global_position = mid_point
