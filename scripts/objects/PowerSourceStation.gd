extends Node3D
class_name PowerSourceStation

@onready var slot : Slot = $Slot

func _ready():
	slot.received_node.connect(_on_node_received)
	slot.released_node.connect(_on_node_released)

func _on_node_received(node: Node) -> void:
	var power_source = get_attached_power_source(node)
	if power_source == null:
		return
	
	PowerGrid.current_power_source = power_source

func _on_node_released(_node: Node) -> void:
	PowerGrid.current_power_source = null

func get_attached_power_source(node: Node) -> PowerSource:
	if node == null:
		return null
	return node.get_node_or_null(Constants.POWER_SOURCE)
