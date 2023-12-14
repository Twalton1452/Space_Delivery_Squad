extends Area3D
class_name Interactable

signal interacted

@export var toggler = false

@export_category("Internal Scene Stuff")
@export var mesh_to_highlight : MeshInstance3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

var toggled = false

func add_highlight(highlight: StandardMaterial3D) -> void:
	mesh_to_highlight.set_surface_override_material(0, highlight)

func remove_highlight() -> void:
	mesh_to_highlight.set_surface_override_material(0, null)

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
