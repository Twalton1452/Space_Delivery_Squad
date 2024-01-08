@icon("res://art/icons/box.svg")
extends Node3D
class_name Slot

## A Slot is something that Holds another Node in a specific position
## Players will typically place things into Slots for specific purposes
## Another script will listen for the Slot to be filled/emptied

signal received_node(node: Node)
signal released_node(node: Node)

@export var holding_node : Item
@export var can_move = false

var remote_transform : RemoteTransform3D = null

func is_holding_node() -> bool:
	return holding_node != null

func _ready():
	if can_move:
		remote_transform = RemoteTransform3D.new()
		remote_transform.name = "RemoteTransform3D"
		add_child(remote_transform)
		
	var interactable = get_node_or_null(Constants.INTERACTABLE)
	if interactable != null:
		interactable.interacted.connect(_on_interacted)
	else:
		## TODO: Figure out how to put Editor hints in the Scene Dock as a warning
		push_warning(get_path(), " has no Interactable component attached")
	
	if holding_node != null:
		# Let users of this Slot setup and then emit the signal
		await get_tree().physics_frame
		receive_node(holding_node)

func _on_interacted(interactable: Interactable, interacter: Player) -> void:
	# Take from Player
	if holding_node == null and interacter.is_holding_node() and interacter.get_held_node() != get_parent():
		if multiplayer.is_server():
			ReleaseHandler.request_player_release(interacter, interacter.get_held_node(), self)
	# Pass on the Interaction to the Item
	elif holding_node != null and !interacter.is_holding_node():
		holding_node._on_interacted(interactable, interacter)

func receive_node(item: Item) -> void:
	holding_node = item
	if not holding_node.picked_up.is_connected(release_node):
		holding_node.picked_up.connect(release_node)
	
	holding_node.global_position = global_position
	holding_node.rotation = Vector3.ZERO
	holding_node.interactable.enable()
	
	if can_move:
		remote_transform.remote_path = holding_node.get_path()
	
	received_node.emit(holding_node)

func release_node() -> void:
	if holding_node.picked_up.is_connected(release_node):
		holding_node.picked_up.disconnect(release_node)
	
	var to_be_released = holding_node
	holding_node = null
	if can_move:
		remote_transform.remote_path = ""
	released_node.emit(to_be_released)
