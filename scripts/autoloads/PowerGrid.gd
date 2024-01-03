extends Node

## Autoloaded

signal power_gained
signal power_lost

var current_power_source : PowerSource : 
	set(value):
		current_power_source = value
		
		if current_power_source == null:
			power_lost.emit()
		elif current_power_source.available_power > 0.0:
			power_gained.emit()

func notify_power_gained() -> void:
	power_gained.emit()

func notify_power_lost() -> void:
	power_lost.emit()

## Draw power from the Grid
## returns the attempted amount requested or the last available amount
func draw_power(kw: float) -> float:
	if current_power_source == null:
		return 0.0
	
	return current_power_source.draw_power(kw)
	
