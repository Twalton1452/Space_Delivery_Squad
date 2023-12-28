extends Node
class_name PowerConsumer

@export var power_per_use = 1.0

func _ready():
	add_to_group(Constants.POWER_CONSUMER_GROUP)

func request_power(grid: PowerGrid) -> bool:
	var given_power = grid.draw_power(power_per_use)
	return true
