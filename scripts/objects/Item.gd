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
		interacter.attempt_to_hold(self)

# Called from the InteractionHandler when appropriate
func on_held() -> void:
	interactable.disable()
	picked_up.emit()

# Called from the DropHandler when appropriate
func on_dropped() -> void:
	interactable.enable()
	dropped.emit()
