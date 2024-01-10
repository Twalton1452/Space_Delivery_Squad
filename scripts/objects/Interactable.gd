@icon("res://art/icons/hand-point.svg")
extends Area3D
class_name Interactable

signal interacted(interactable: Interactable, interacter: Player)

## If the interactable should visually return to its original state once interacted with
@export var toggler = false
@export var time_to_interact : float = 0.0
## When the player is hovering the Interactable, should it display [E]?
@export var display_action_button_before_text = true
@export var interact_display_text = "Interact"
@export var interacted_sfx : AudioStream

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
	collision_layer = Constants.INTERACTABLE_LAYER

func disable() -> void:
	collision_layer = Constants.NON_INTERACTABLE_LAYER

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
	
	if interacted_sfx:
		AudioManager.play_one_shot_3d(self, interacted_sfx)
	
	interacted.emit(self, interacter)
