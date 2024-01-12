extends Node3D
class_name RadarConsole

## Physical object the Players interact with to affect the Path the Ship takes

@export var quad_for_viewport : MeshInstance3D
@export var radar_viewport : SubViewport
@export var left_arrow_button : Interactable
@export var right_arrow_button : Interactable
@export var lock_in_button : Interactable
@export var radar : Radar
@export var highlight_mat : StandardMaterial3D

func _ready() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_texture = radar_viewport.get_texture()
	left_arrow_button.interacted.connect(_on_left_button_pressed)
	right_arrow_button.interacted.connect(_on_right_button_pressed)
	lock_in_button.interacted.connect(_on_lock_in_button_pressed)
	radar.reached_destination.connect(_on_reached_destination)
	
	enable()

func enable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.WHITE

func disable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.BLACK
	lock_in_button.remove_highlight()

func _on_reached_destination() -> void:
	lock_in_button.remove_highlight()

func _on_left_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	radar.select_next_left_path()
	lock_in_button.remove_highlight()

func _on_right_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	radar.select_next_right_path()
	lock_in_button.remove_highlight()

func _on_lock_in_button_pressed(interactable: Interactable, _interacter: Player) -> void:
	radar.lock_in_path()
	interactable.add_highlight(highlight_mat)
