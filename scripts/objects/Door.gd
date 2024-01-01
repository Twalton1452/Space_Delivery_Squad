extends Node3D
class_name Door

signal open
signal close

@export var triggers : Array[Interactable]
# TODO: Would rather a component based approach to power instead of
# 		a hard set power value on each entity that needs power
@export var power_cost = 0.0

@export_category("Internal Scene Stuff")
@export var collision_body : CollisionObject3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

var opened = false

func _ready() -> void:
	for trigger in triggers:
		trigger.interacted.connect(_on_trigger)

func _on_trigger(_interactable: Interactable, _interacter: Player) -> void:
	if power_cost > 0.0 and PowerGrid.draw_power(power_cost) < power_cost:
		return
	
	# Allows for interupting the animation cleanly
	var current_seek = 0.0
	if animation_player.is_playing():
		current_seek = animation_player.current_animation_position
	
	if not opened:
		animation_player.play("open")
		animation_player.seek(current_seek, true)
		collision_body.collision_layer = 0
		opened = true
		open.emit()
	else:
		# Need the end of the animation for playing backwards
		if not animation_player.is_playing():
			current_seek = animation_player.get_animation("open").length
		
		animation_player.play_backwards("open")
		animation_player.seek(current_seek, true)
		collision_body.collision_layer = 1 << 0
		opened = false
		close.emit()
