@icon("res://art/icons/ear-white.svg")
extends Node
class_name DisasterListener

## Class for Listeners to inherit from to setup some repeatable configuration

signal conditions_met(listener: DisasterListener)
signal conditions_unmet(listener: DisasterListener)

@export var disaster_event : Event

func _enter_tree() -> void:
	DisasterManager.register_listener(self)

func _exit_tree() -> void:
	DisasterManager.unregister_listener(self)

func notify_conditions_were_met() -> void:
	conditions_met.emit(self)

func notify_conditions_were_unmet() -> void:
	conditions_unmet.emit(self)
