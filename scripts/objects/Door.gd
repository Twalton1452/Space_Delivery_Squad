extends Node3D
class_name Door

signal opened
signal closed

@export var triggers : Array[Area3D]
@export var open_sfx : AudioStream
@export var close_sfx : AudioStream

@export_category("Internal Scene Stuff")
@export var collision_body : CollisionObject3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

var is_open = false

func _ready() -> void:
	for trigger in triggers:
		if trigger is Interactable:
			trigger.interacted.connect(_on_interactable_interacted)
		elif trigger is TriggerZone:
			trigger.triggered.connect(_on_trigger_zone_activated)
			trigger.empty.connect(_on_trigger_zone_emptied)

func _on_trigger_zone_activated(_trigger_zone: TriggerZone, _what_entered: CollisionObject3D) -> void:
	open()

func _on_trigger_zone_emptied(_trigger_zone: TriggerZone, _what_exited: CollisionObject3D) -> void:
	close()

func _on_interactable_interacted(interactable: Interactable, who_interacted: Player) -> void:
	_on_trigger(interactable, who_interacted)

func _on_trigger(_trigger: Area3D, _interacter: Player) -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	if is_open:
		return
	
	# Allows for interupting the animation cleanly
	var current_seek = 0.0
	if animation_player.is_playing():
		current_seek = animation_player.current_animation_position
	animation_player.play("open")
	animation_player.seek(current_seek, true)
	collision_body.collision_layer = 0
	is_open = true
	AudioManager.play_one_shot_3d(self, open_sfx, true, -20.0)
	opened.emit()

func close() -> void:
	if not is_open:
		return
	
	# Allows for interupting the animation cleanly
	var current_seek = 0.0
	if animation_player.is_playing():
		current_seek = animation_player.current_animation_position
	
	# Need the end of the animation for playing backwards
	if not animation_player.is_playing():
		current_seek = animation_player.get_animation("open").length
	
	animation_player.play_backwards("open")
	animation_player.seek(current_seek, true)
	collision_body.collision_layer = Constants.WORLD_LAYER
	is_open = false
	AudioManager.play_one_shot_3d(self, close_sfx, true, -20.0)
	closed.emit()
