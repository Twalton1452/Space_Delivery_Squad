extends AnimatableBody3D


@export var speed = 0.5
@export var highlight_material : StandardMaterial3D
@export var up_triggers : Array[Interactable]
@export var middle_triggers : Array[Interactable]
@export var down_triggers : Array[Interactable]

@export var floor_positions : Dictionary # { key: int, value: Vector3 }

var moving_tween : Tween

func _ready() -> void:
	for up_trigger in up_triggers:
		up_trigger.interacted.connect(_on_up_trigger)
	for middle_trigger in middle_triggers:
		middle_trigger.interacted.connect(_on_middle_trigger)
	for down_trigger in down_triggers:
		down_trigger.interacted.connect(_on_down_trigger)

func _on_up_trigger(_interactable: Interactable, _interacter: Player) -> void:
	move_to(1)
	highlight_triggers_for(up_triggers)

func _on_middle_trigger(_interactable: Interactable, _interacter: Player) -> void:
	move_to(0)
	highlight_triggers_for(middle_triggers)

func _on_down_trigger(_interactable: Interactable, _interacter: Player) -> void:
	move_to(-1)
	highlight_triggers_for(down_triggers)

func highlight_triggers_for(triggers: Array[Interactable]) -> void:
	for trigger in triggers:
		trigger.add_highlight(highlight_material)
		
	await moving_tween.finished
	for trigger in triggers:
		trigger.remove_highlight()

func move_to(destination_floor: int) -> void:
	if moving_tween != null and moving_tween.is_valid():
		moving_tween.finished.emit()
		moving_tween.kill()
	
	moving_tween = create_tween()
	var distance = position.distance_to(floor_positions[destination_floor])
	moving_tween \
		.tween_property(self, "position", floor_positions[destination_floor], distance / speed) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_delay(0.2)
