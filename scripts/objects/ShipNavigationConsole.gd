extends Node3D
class_name ShipNavigationConsole

## Physical object the Players interact with to affect the Path the Ship takes

@export var quad_for_viewport : MeshInstance3D
@export var navigation_viewport : SubViewport
@export var left_arrow_button : Interactable
@export var right_arrow_button : Interactable
@export var lock_in_button : Interactable
@export var landing_lever : Interactable
@export var ship_navigation : ShipNavigation
@export var highlight_mat : StandardMaterial3D

var enter_galaxy_event : Event = load("res://resources/events/navigation/enter_galaxy.tres")

func _ready() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_texture = navigation_viewport.get_texture()
	left_arrow_button.interacted.connect(_on_left_button_pressed)
	right_arrow_button.interacted.connect(_on_right_button_pressed)
	lock_in_button.interacted.connect(_on_lock_in_button_pressed)
	landing_lever.interacted.connect(_on_landing_lever_activated)
	ship_navigation.reached_destination.connect(_on_reached_destination)
	
	enable()

func enable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.WHITE

func disable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.BLACK
	lock_in_button.remove_highlight()

func _on_reached_destination() -> void:
	lock_in_button.remove_highlight()

func _on_left_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	ship_navigation.select_next_left_path()
	lock_in_button.remove_highlight()

func _on_right_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	ship_navigation.select_next_right_path()
	lock_in_button.remove_highlight()

func _on_lock_in_button_pressed(interactable: Interactable, _interacter: Player) -> void:
	ship_navigation.lock_in_path()
	interactable.add_highlight(highlight_mat)

func _on_landing_lever_activated(_interactable: Interactable, _interacter: Player) -> void:
	if enter_galaxy_event.occurring:
		EventManager.request_event_end(enter_galaxy_event)
	else:
		EventManager.request_event_start(enter_galaxy_event)
