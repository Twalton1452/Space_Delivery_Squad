extends CharacterBody3D
class_name Player

const WALK_SPEED = 5.0
const JUMP_VELOCITY = 3.0
const BASE_FOV = 75.0
const FOV_CHANGE = 2.0

@onready var player_input : PlayerInput = $PlayerInput
@onready var camera : Camera3D = $Camera3D

var look_speed = .005
var move_speed = WALK_SPEED

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

## Based on the velocity, change the camera's FOV
## not used at the moment because the x,z velocity don't reset to 0
## so the fov never changes back once it gets modified unless hitting a wall
func movement_based_fov_change(delta) -> void:
	var velocity_clamped = clamp(velocity.length(), 0.5, move_speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

## Server receives Input from clients and moves them
func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	# Capture direction during input because we let the player have authority
	# over their own rotation
	var direction = (transform.basis * Vector3(player_input.x, 0, player_input.y)).normalized()
	
	# Clientside Prediction - Simulate player movement
	move(direction, player_input.jumping, delta)
	movement_based_fov_change(delta)

func move(direction: Vector3, jump: int, delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if jump > 0 and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if is_on_floor():
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		# After a jump, allow the player to influence the direction slightly
		if direction:
			velocity.x = lerp(velocity.x, direction.x * move_speed, delta * 2.0)
			velocity.z = lerp(velocity.z, direction.z * move_speed, delta * 2.0)
	
	move_and_slide()
