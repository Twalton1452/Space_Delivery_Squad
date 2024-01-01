extends Node

## Autoloaded

## Class to evaluate the Ship's power needs
## There is a single source of Power that provides the wattage
## The source of Power will be swapped out by players occasionally to refill the grid

## The grid can store power to allow Players to switch out the Power Source
var reserved_kw = 0.0
var available_power_kw : float : get = get_available_power

var current_power_source : PowerSource : 
	set(value):
		print("[PowerGrid]: New Power Source: ", value)
		current_power_source = value

func get_available_power() -> float:
	return current_power_source.available_power if current_power_source != null else 0.0

func reserve_power(kw: float) -> void:
	reserved_kw += draw_power(kw)

## Draw power from the Grid
## returns the attempted amount requested or the last available amount
func draw_power(kw: float) -> float:
	if current_power_source == null:
		return 0.0
	
	return current_power_source.draw_power(kw)
	
