extends Node3D
class_name Door

signal open
signal close

@export var triggers : Array[Area3D]
@export var open_sfx : AudioStream
@export var close_sfx : AudioStream

@export_category("Internal Scene Stuff")
@export var collision_body : CollisionObject3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

var opened = false

func _ready() -> void:
	for trigger in triggers:
		if trigger is Interactable:
			trigger.interacted.connect(_on_interactable_interacted)
		elif trigger is TriggerZone:
			trigger.triggered.connect(_on_trigger_zone_activated)
			trigger.empty.connect(_on_trigger_zone_emptied)

func _on_trigger_zone_activated(trigger_zone: TriggerZone, what_entered: CollisionObject3D) -> void:
	_on_trigger(trigger_zone, what_entered)

func _on_trigger_zone_emptied(trigger_zone: TriggerZone, what_exited: CollisionObject3D) -> void:
	_on_trigger(trigger_zone, what_exited)

func _on_interactable_interacted(interactable: Interactable, who_interacted: Player) -> void:
	_on_trigger(interactable, who_interacted)

func _on_trigger(_trigger: Area3D, _interacter: Player) -> void:
	# Allows for interupting the animation cleanly
	var current_seek = 0.0
	if animation_player.is_playing():
		current_seek = animation_player.current_animation_position
	
	if not opened:
		animation_player.play("open")
		animation_player.seek(current_seek, true)
		collision_body.collision_layer = 0
		opened = true
		AudioManager.play_one_shot_3d(self, open_sfx, true, -20.0, AudioManager.AudioFallOff.SHORT)
		open.emit()
	else:
		# Need the end of the animation for playing backwards
		if not animation_player.is_playing():
			current_seek = animation_player.get_animation("open").length
		
		animation_player.play_backwards("open")
		animation_player.seek(current_seek, true)
		collision_body.collision_layer = 1 << 0
		opened = false
		AudioManager.play_one_shot_3d(self, close_sfx, true, -20.0, AudioManager.AudioFallOff.SHORT)
		close.emit()
