@icon("res://art/icons/lightning-bolt.svg")
extends Node
class_name PowerSource

@export var max_power = 1000.0
@export var available_power = 1000.0
@export var mesh_for_power_visual : MeshInstance3D

func _ready():
	add_to_group(Constants.POWER_SOURCE_GROUP)
	available_power = clamp(available_power, 0.0, max_power)
	update_visual()

func has_power() -> bool:
	return available_power > 0.0

func update_visual() -> void:
	var t = create_tween()
	t.tween_property(mesh_for_power_visual, "scale:y", available_power / max_power, 0.5).set_ease(Tween.EASE_OUT)

func recharge(power: float) -> void:
	available_power = clampf(available_power + power, 0.0, max_power)
	update_visual()

func drain(power: float) -> void:
	available_power = clampf(available_power - power, 0.0, max_power)
	update_visual()
