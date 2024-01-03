@icon("res://art/icons/lightning-bolt.svg")
extends Node
class_name PowerSource

@export var max_power = 1000.0
@export var available_power = 1000.0
@export var mesh_to_effect : MeshInstance3D

func _ready():
	add_to_group(Constants.POWER_SOURCE_GROUP)
	available_power = clamp(available_power, 0.0, max_power)
	update_visual()

func has_power() -> bool:
	return available_power > 0.0

func update_visual() -> void:
	# TODO: replace with mesh that gets tween'd down instead of bothering with shaders
	mesh_to_effect.set_instance_shader_parameter("fill", remap(available_power / max_power, 0.0, 1.0, 0.0, 0.5))

func recharge(power: float) -> void:
	available_power = clampf(available_power + power, 0.0, max_power)
	update_visual()

func drain(power: float) -> void:
	available_power = clampf(available_power - power, 0.0, max_power)
	update_visual()
