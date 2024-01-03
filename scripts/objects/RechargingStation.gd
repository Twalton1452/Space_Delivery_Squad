extends Node3D
class_name RechargingStation

@export var power_recharge_rate := 1.0
@export var recharge_rate_seconds := 2.0
@export var finished_charging_sfx : AudioStream
@export var platform : Node3D

@onready var slot : Slot = $Slot

func _ready():
	slot.received_node.connect(_on_node_received)
	slot.released_node.connect(_on_node_released)

func begin_charging() -> void:
	var power_source = get_attached_power_source(slot.holding_node)
	if power_source == null:
		return
	
	charge(power_source)

func charge(power_source: PowerSource) -> void:
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(platform, "rotation:y", platform.rotation.y + PI * 2, recharge_rate_seconds)
	t.tween_property(slot.holding_node, "rotation:y", platform.rotation.y + PI * 2, recharge_rate_seconds)
	t.set_loops()
	
	while slot.is_holding_node() and power_source.available_power < power_source.max_power:
		power_source.recharge(power_recharge_rate)
		await get_tree().create_timer(recharge_rate_seconds, false, true).timeout
	
	t.kill()
	stop_charging()

func stop_charging() -> void:
	var power_source = get_attached_power_source(slot.holding_node)
	if power_source == null:
		return
	
	if power_source.available_power >= power_source.max_power:
		AudioManager.play_one_shot_3d(self, finished_charging_sfx)

#region Slot events
func _on_node_received(node: Node) -> void:
	var power_source = get_attached_power_source(node)
	if power_source == null:
		return
	
	begin_charging()

func _on_node_released(_node: Node) -> void:
	stop_charging()
#endregion Slot events

func get_attached_power_source(node: Node) -> PowerSource:
	if node == null:
		return null
	return node.get_node_or_null(Constants.POWER_SOURCE)
