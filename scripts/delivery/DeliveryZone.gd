extends Node3D

@export var delivery_lever : Interactable

@onready var area_3d : Area3D = $Area3D

func _ready() -> void:
	if multiplayer.is_server():
		delivery_lever.interacted.connect(_on_delivery_attempted)

func _on_delivery_attempted(interactable: Interactable, _interacter: Player) -> void:
	# Deliver
	if interactable.toggler and not interactable.toggled:
		area_3d.monitoring = true
		await get_tree().physics_frame
		
		var bodies = area_3d.get_overlapping_bodies()
		var areas = area_3d.get_overlapping_areas()
		for body in bodies:
			if body is Player:
				_handle_delivering_player(body)
		for area in areas:
			if area is Interactable:
				_handle_delivering_interactable(area)
		
		area_3d.monitoring = false

func _handle_delivering_player(player: Player) -> void:
	player.queue_free()

func _handle_delivering_interactable(interactable: Interactable) -> void:
	interactable.owner.queue_free()
