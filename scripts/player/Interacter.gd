extends RayCast3D
class_name Interacter

signal spotted_interactable(node: Node3D)

@export var default_interact_text = "[E] Pickup"

@onready var interact_label = $"../HUD/Label"

var current_interactable: Node3D = null :
	set(value):
		current_interactable = value
		spotted_interactable.emit(value)

func _ready():
	interact_label.hide()

func enable() -> void:
	collision_mask = Constants.INTERACTABLE_LAYER

func disable() -> void:
	collision_mask = Constants.NON_INTERACTABLE_LAYER

func is_interactable(collided_object: Node3D) -> bool:
	return collided_object.collision_layer | Constants.INTERACTABLE_LAYER == Constants.INTERACTABLE_LAYER

func clear_current_interactable() -> void:
	current_interactable = null
	interact_label.hide()

# TODO: detect controller or keybind remap
func get_current_interact_input() -> String:
	return "[E] "

# For updating UI that the player is pointing at something
func _physics_process(_delta):
	if not is_multiplayer_authority():
		return
	
	if is_colliding():
		if is_interactable(get_collider()):
			if current_interactable != get_collider():
				current_interactable = get_collider()
				
				if current_interactable is Interactable:
					if current_interactable.can_interact():
						interact_label.text = get_current_interact_input() + current_interactable.interact_display_text
						interact_label.show()
					else:
						interact_label.hide()
				else:
					interact_label.text = default_interact_text
					interact_label.show()
				
			return
	
	clear_current_interactable()

