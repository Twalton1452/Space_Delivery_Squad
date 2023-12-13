extends Area3D

signal activation_changed(value: bool)

@export var to_activate : Array[Node3D]

@export var activated = false
@export var activated_rotation = Vector3(45.0, 0.0, 0.0)
@export var not_activated_rotation = Vector3(-45.0, 0.0, 0.0)

@onready var to_rotate : Node3D = get_parent()

var transitioning = false

func _ready():
	activated_rotation.x = deg_to_rad(activated_rotation.x)
	activated_rotation.y = deg_to_rad(activated_rotation.y)
	activated_rotation.z = deg_to_rad(activated_rotation.z)
	
	not_activated_rotation.x = deg_to_rad(not_activated_rotation.x)
	not_activated_rotation.y = deg_to_rad(not_activated_rotation.y)
	not_activated_rotation.z = deg_to_rad(not_activated_rotation.z)
	
	to_rotate.rotation = activated_rotation if activated else not_activated_rotation

func interact() -> void:
	if transitioning:
		return
	
	transitioning = true
	
	var t = create_tween()
	var target_rotation = activated_rotation if not activated else not_activated_rotation
	t.tween_property(to_rotate, "rotation", target_rotation, 0.5).set_ease(Tween.EASE_IN)
	
	await t.finished
	
	activated = !activated
	if activated:
		for activatable in to_activate:
			if activatable.has_method("activate"):
				activatable.activate()
	else:
		for activatable in to_activate:
			if activatable.has_method("deactivate"):
				activatable.deactivate()
	
	transitioning = false
	activation_changed.emit(activated)
