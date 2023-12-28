extends Node
class_name PowerSource

@export var max_power = 1000.0
@export var available_power = 1000.0

func _ready():
	add_to_group(Constants.POWER_SOURCE_GROUP)

func has_power() -> bool:
	return available_power > 0.0

func recharge(kw: float) -> void:
	available_power = clampf(available_power + kw, 0.0, max_power)

func draw_power(kw: float) -> float:
	# Got what they needed
	var requested_kw = max_power - kw
	if requested_kw > 0.0:
		available_power -= kw
		return requested_kw
	
	# Got the left overs
	requested_kw = available_power
	available_power = 0.0
	return requested_kw
