@icon("res://art/icons/battery-empty-white.svg")
extends Node
class_name PowerFallback

## Component that activates its parent when Power is Lost
## and deactivates its parent when Power is gained

func _ready():
	add_to_group(Constants.POWER_FALLBACK_GROUP)

func turn_on_functionality() -> void:
	if get_parent().has_method("enable"):
		get_parent().call("enable")

func turn_off_functionality() -> void:
	if get_parent().has_method("disable"):
		get_parent().call("disable")
