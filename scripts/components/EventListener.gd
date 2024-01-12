@icon("res://art/icons/ear-white.svg")
extends Node
class_name EventListener

## Class for Listeners to inherit from to setup some repeatable configuration

signal conditions_met(listener: EventListener)
signal conditions_unmet(listener: EventListener)

@export var event : Event

func _enter_tree() -> void:
	EventManager.register_listener(self)

func _exit_tree() -> void:
	EventManager.unregister_listener(self)

func notify_conditions_were_met() -> void:
	conditions_met.emit(self)

func notify_conditions_were_unmet() -> void:
	conditions_unmet.emit(self)
