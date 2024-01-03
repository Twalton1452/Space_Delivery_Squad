@icon("res://art/icons/rotate-red.svg")
extends Node3D
class_name Rotater

signal rotated

## Set in degrees, but converted to radians on _ready for the Tween
@export var target_rotation = Vector3(0.0, -90.0, 0.0)
@export var time_to_rotate_seconds = 0.3
@export var is_rotated = false
@export var rotate_sfx : AudioStream

@onready var interactable : Interactable = $Interactable

var og_rot : Vector3
var in_progress = false

func _ready():
	interactable.interacted.connect(_on_interacted)
	og_rot = get_parent().rotation
	target_rotation.x = deg_to_rad(target_rotation.x)
	target_rotation.y = deg_to_rad(target_rotation.y)
	target_rotation.z = deg_to_rad(target_rotation.z)
	
func _on_interacted(_interactable: Interactable, _interacter: Player) -> void:
	rotate_parent()

func rotate_parent():
	if in_progress:
		return
	in_progress = true
	AudioManager.play_one_shot_3d(get_parent(), rotate_sfx)

	var t = create_tween()
	if is_rotated:
		t.tween_property(get_parent(), "rotation", og_rot, time_to_rotate_seconds).set_ease(Tween.EASE_IN)
	else:
		t.tween_property(get_parent(), "rotation", target_rotation, time_to_rotate_seconds).set_ease(Tween.EASE_OUT)

	await t.finished
	in_progress = false
	is_rotated = !is_rotated
	rotated.emit()

## Setup method, if any scenes need the rotatable to be in a particular state without emitting signals
## Use this to get it there
func force_rotate_parent() -> void:
	if is_rotated:
		get_parent().rotation = og_rot
	else:
		get_parent().rotation = target_rotation
	is_rotated = !is_rotated
	in_progress = false

