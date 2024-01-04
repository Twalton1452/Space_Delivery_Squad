extends Node3D
class_name PowerSourceStation

@export var drain_power_rate = 2.0
@export var drain_power_rate_seconds = 1.0
@export var door : Rotater

@onready var slot : Slot = $Slot
@onready var audio_player_3d : AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready():
	slot.received_node.connect(_on_node_received)
	slot.released_node.connect(_on_node_released)

func begin_draining() -> void:
	var power_source = get_attached_power_source(slot.holding_node)
	if power_source == null:
		return
	
	audio_player_3d.play()
	drain(power_source)

func drain(power_source: PowerSource) -> void:
	if door.is_rotated:
		door.rotate_parent()
		await door.rotated
	
	while slot.is_holding_node() and power_source.has_power():
		power_source.drain(drain_power_rate)
		await get_tree().create_timer(drain_power_rate_seconds, false, true).timeout
	
	stop_draining()

func stop_draining() -> void:
	audio_player_3d.stop()
	
	if not door.is_rotated:
		door.rotate_parent()
	
	var power_source = get_attached_power_source(slot.holding_node)
	if power_source == null:
		return
	
	if not power_source.has_power():
		PowerGrid.notify_power_lost()

#region Slot events
func _on_node_received(node: Node) -> void:
	var power_source = get_attached_power_source(node)
	if power_source == null:
		return
	
	if power_source.has_power():
		PowerGrid.notify_power_gained()
		begin_draining()

func _on_node_released(_node: Node) -> void:
	stop_draining()
	PowerGrid.notify_power_lost()
#endregion Slot events

func get_attached_power_source(node: Node) -> PowerSource:
	if node == null:
		return null
	return node.get_node_or_null(Constants.POWER_SOURCE)
