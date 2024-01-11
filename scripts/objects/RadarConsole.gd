extends Node3D
class_name RadarConsole

## Physical object the Players interact with to affect the Path the Ship takes

@export var quad_for_viewport : MeshInstance3D
@export var radar_viewport : SubViewport
@export var left_arrow_button : Interactable
@export var right_arrow_button : Interactable

func _ready() -> void:
	enable()
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_texture = radar_viewport.get_texture()
	left_arrow_button.interacted.connect(_on_left_button_pressed)
	right_arrow_button.interacted.connect(_on_right_button_pressed)

func enable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.WHITE

func disable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.BLACK

func _on_left_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	# choose previous path
	pass

func _on_right_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	# choose next path
	pass

