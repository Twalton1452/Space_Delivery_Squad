extends Node
class_name PlayerInput

## Class to record authoritative player input
## Useful separation for when deciding to move to Clientside-Prediction
## May get rid of this

@export var x := 0.0
@export var y := 0.0
@export var jumping := 0

@onready var player : Player = get_parent()

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	
	setup.call_deferred()

func setup() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	
	# Only used to exit the game currently
	if event.is_action_pressed("unlock_cursor"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * player.look_speed)
		player.camera.rotate_x(-event.relative.y * player.look_speed)
		player.camera.rotation.x = clamp(player.camera.rotation.x, -PI/2, PI/2)

func _physics_process(_delta):
	if not is_multiplayer_authority():
		return
	
	jumping = Input.is_action_pressed("jump")

	x = Input.get_axis("left", "right")
	y = Input.get_axis("up", "down")
