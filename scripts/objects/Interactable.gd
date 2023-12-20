extends Area3D
class_name Interactable

signal interacted(interactable: Interactable, interacter: Player)

@export var toggler = false
@export var interact_display_text = "Interact"

@export_category("Internal Scene Stuff")
@export var mesh_to_highlight : MeshInstance3D

var animation_player : AnimationPlayer = null

var toggled = false

func _ready():
	animation_player = get_node_or_null("AnimationPlayer")

func add_highlight(highlight: StandardMaterial3D) -> void:
	mesh_to_highlight.set_surface_override_material(0, highlight)

func remove_highlight() -> void:
	mesh_to_highlight.set_surface_override_material(0, null)

func enable() -> void:
	collision_layer = Constants.INTERACTABLE_COLLISION_LAYER

func disable() -> void:
	collision_layer = Constants.NON_INTERACTABLE_COLLISION_LAYER

func can_interact() -> bool:
	return animation_player == null or not animation_player.is_playing()

func interact(interacter: Player) -> void:
	if not can_interact():
		return
	
	if animation_player:
		if toggler:
			if toggled:
				animation_player.play_backwards("activated")
			else:
				animation_player.play("activated")
			toggled = !toggled
		else:
			animation_player.play("activated")
	
	interacted.emit(self, interacter)
