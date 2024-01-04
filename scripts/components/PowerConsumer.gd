@icon("res://art/icons/battery-full-white.svg")
extends Node
class_name PowerConsumer

func _ready():
	add_to_group(Constants.POWER_CONSUMER_GROUP)

func turn_on_functionality() -> void:
	if get_parent().has_method("enable"):
		get_parent().call("enable")

func turn_off_functionality() -> void:
	if get_parent().has_method("disable"):
		get_parent().call("disable")
