@icon("res://art/icons/present.svg")
extends Node3D
class_name Item

signal picked_up
signal dropped

var interactable : Interactable

func _ready():
	interactable = get_node_or_null(Constants.INTERACTABLE)
	if interactable != null:
		interactable.interacted.connect(_on_interacted)

func _on_interacted(_interactable: Interactable, interacter: Player) -> void:
	if not interacter.is_holding_node():
		if multiplayer.is_server():
			PickupHandler.request_pickup(interacter, self)

# Called from the PickupHandler when appropriate
func on_held(picker_upper: Player) -> void:
	interactable.disable()
	picked_up.emit(picker_upper)

# Called from the DropHandler when appropriate
func on_dropped(dropper: Player) -> void:
	interactable.enable()
	dropped.emit(dropper)
