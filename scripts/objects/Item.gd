@icon("res://art/icons/present.svg")
extends Node3D
class_name Item

signal picked_up
signal dropped

## Euler angles, converted to Radians at run-time
@export var picked_up_rotation = Vector3(0.0, 0.0, 0.0)
@export var picked_up_offset = Vector3(0.0, 0.0, 0.0)

var interactable : Interactable

func _ready():
	picked_up_rotation = Helpers.deg_to_rad_vec3(picked_up_rotation)
	interactable = get_node_or_null(Constants.INTERACTABLE)
	if interactable != null:
		interactable.interacted.connect(_on_interacted)

func _on_interacted(_interactable: Interactable, interacter: Player) -> void:
	if not interacter.is_holding_node():
		if multiplayer.is_server():
			PickupHandler.request_pickup(interacter, self)

# Called from the PickupHandler when appropriate
func on_held() -> void:
	interactable.disable()
	picked_up.emit()

# Called from the DropHandler when appropriate
func on_dropped() -> void:
	rotation += picked_up_rotation
	interactable.enable()
	dropped.emit()
