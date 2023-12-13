extends RayCast3D
class_name Interacter

signal spotted_interactable(node: Node3D)

const INTERACTABLE_LAYER = 1 << 2

@onready var interact_label = $"../UI/Label"

var current_interactable: Node3D = null :
	set(value):
		current_interactable = value
		spotted_interactable.emit(value)

func _ready():
	interact_label.hide()

func is_interactable(collided_object: Node3D) -> bool:
	return collided_object.collision_layer | INTERACTABLE_LAYER == INTERACTABLE_LAYER

func clear_current_interactable() -> void:
	current_interactable = null
	interact_label.hide()

# For updating UI that the player is pointing at something
func _physics_process(_delta):
	if not is_multiplayer_authority():
		return
	
	if is_colliding():
		if is_interactable(get_collider()):
			if current_interactable != get_collider():
				current_interactable = get_collider()
				
				if current_interactable.can_interact():
					interact_label.show()
				
			return
	
	clear_current_interactable()

