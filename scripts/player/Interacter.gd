extends RayCast3D
class_name Interacter

signal spotted_interactable(node: Node3D)

var current_interactable: Node3D = null :
	set(value):
		current_interactable = value
		spotted_interactable.emit(value)

func _physics_process(_delta):
	if not is_multiplayer_authority():
		return
	
	if is_colliding():
		if current_interactable != get_collider():
			current_interactable = get_collider()
	elif current_interactable != null:
		current_interactable = null
