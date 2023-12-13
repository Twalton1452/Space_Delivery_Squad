extends Area3D
class_name Interactable

signal interacted

@export var toggler = false

@onready var animation_player : AnimationPlayer = $AnimationPlayer

var toggled = false

func can_interact() -> bool:
	return not animation_player.is_playing()

func interact() -> void:
	if not can_interact():
		return
	
	if toggler:
		if toggled:
			animation_player.play_backwards("activated")
		else:
			animation_player.play("activated")
		toggled = !toggled
	else:
		animation_player.play("activated")
	
	interacted.emit()
