@icon("res://art/icons/danger-circle.svg")
extends Area3D
class_name TriggerZone

## Wrapper for Area3D to emit more specialized signals

signal triggered(trigger_zone: TriggerZone, what_entered: CollisionObject3D)
signal empty(trigger_zone: TriggerZone, what_exited: CollisionObject3D)

var detecting_mask : int

func _ready() -> void:
	body_entered.connect(_on_trigger_zone_entered)
	body_exited.connect(_on_trigger_zone_exited)
	detecting_mask = collision_mask

func enable() -> void:
	collision_mask = detecting_mask
	
	if get_overlapping_bodies().size() == 0:
		empty.emit(self, null)

func disable() -> void:
	collision_mask = 0

func _on_trigger_zone_entered(body) -> void:
	if get_overlapping_bodies().size() == 1:
		triggered.emit(self, body)

func _on_trigger_zone_exited(body) -> void:
	if get_overlapping_bodies().size() == 0:
		empty.emit(self, body)
