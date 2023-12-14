extends Node3D


@export var speed = 0.5
@export var down_trigger : Interactable
@export var middle_trigger : Interactable
@export var up_trigger : Interactable

@export var floor_positions : Dictionary # { key: int, value: Vector3 }

var moving_tween : Tween

func _ready() -> void:
	down_trigger.interacted.connect(_on_down_trigger)
	middle_trigger.interacted.connect(_on_middle_trigger)
	up_trigger.interacted.connect(_on_up_trigger)

func _on_down_trigger() -> void:
	move_to(-1)

func _on_middle_trigger() -> void:
	move_to(0)

func _on_up_trigger() -> void:
	move_to(1)

func move_to(destination_floor: int) -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.kill()
	
	moving_tween = create_tween()
	var distance = position.distance_to(floor_positions[destination_floor])
	moving_tween \
		.tween_property(self, "position", floor_positions[destination_floor], distance / speed) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_delay(0.2)
