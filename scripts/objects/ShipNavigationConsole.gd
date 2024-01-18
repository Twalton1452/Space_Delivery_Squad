extends Node3D
class_name ShipNavigationConsole

## Physical object the Players interact with to affect the Path the Ship takes

signal enter_galaxy_lever_pulled
signal locked_in

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
	enter_galaxy_event.started.connect(_on_enter_galaxy)
	enter_galaxy_event.ended.connect(_on_exit_galaxy)
	
	enable()

func _on_enter_galaxy() -> void:
	landing_lever.interact_display_text = "Enter Galaxy"

func _on_exit_galaxy() -> void:
	landing_lever.interact_display_text = "Exit Galaxy"

func enable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.WHITE
	ship_navigation.unpause_travel()
	landing_lever.enable()
	left_arrow_button.enable()
	right_arrow_button.enable()
	lock_in_button.enable()

func disable() -> void:
	(quad_for_viewport.material_override as StandardMaterial3D).albedo_color = Color.BLACK
	lock_in_button.remove_highlight()
	ship_navigation.pause_travel()
	landing_lever.disable()
	left_arrow_button.disable()
	right_arrow_button.disable()
	lock_in_button.disable()

func _on_reached_destination() -> void:
	lock_in_button.remove_highlight()

func _on_left_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	ship_navigation.select_next_left_path()
	lock_in_button.remove_highlight()

func _on_right_button_pressed(_interactable: Interactable, _interacter: Player) -> void:
	ship_navigation.select_next_right_path()
	lock_in_button.remove_highlight()

func _on_lock_in_button_pressed(interactable: Interactable, _interacter: Player) -> void:
	interactable.add_highlight(highlight_mat)
	var destination_name = ship_navigation.lock_in_path()
	locked_in.emit(destination_name)

func _on_landing_lever_activated(_interactable: Interactable, _interacter: Player) -> void:
	enter_galaxy_lever_pulled.emit()
	lock_in_button.remove_highlight()

