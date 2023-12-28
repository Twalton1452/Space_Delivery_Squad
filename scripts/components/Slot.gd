extends Node3D
class_name Slot

## A Slot is something that Holds another Node in a specific position
## Players will typically place things into Slots for specific purposes
## Another script will listen for the Slot to be filled/emptied

signal received_node(node: Node)
signal released_node(node: Node)

@export var holding_node : Node3D

func is_holding_node() -> bool:
	return holding_node != null

func _ready():
	var interactable = get_node_or_null(Constants.INTERACTABLE)
	if interactable != null:
		interactable.interacted.connect(_on_interacted)
	else:
		## TODO: Figure out how to put Editor hints in the Scene Dock as a warning
		push_warning(name, " has no Interactable component attached")
	
	if holding_node != null:
		# Let users of this Slot setup and then emit the signal
		await get_tree().physics_frame
		receive_node(holding_node)

func _on_interacted(_interactable: Interactable, interacter: Player) -> void:
	# Take from Player
	if holding_node == null and interacter.is_holding_node():
		interacter.release_node_to(self)
	# Give to Player
	elif holding_node != null and !interacter.is_holding_node():
		interacter.attempt_to_hold(holding_node)

func receive_node(node: Node) -> void:
	holding_node = node
	node.global_position = global_position
	received_node.emit(holding_node)

func release_node() -> void:
	var to_be_released = holding_node
	holding_node = null
	released_node.emit(to_be_released)
