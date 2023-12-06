extends CharacterBody3D
class_name Player

const WALK_SPEED = 3.0
const JUMP_VELOCITY = 3.0
const BASE_FOV = 75.0
const FOV_CHANGE = 2.0

@onready var player_input : PlayerInput = $PlayerInput
@onready var camera : Camera3D = $Camera3D
@onready var interacter : Interacter = $Camera3D/Interacter
@onready var holder : RemoteTransform3D = $Camera3D/Holder

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
	
	var direction = (transform.basis * Vector3(player_input.x, 0, player_input.y)).normalized()
	if player_input.dropping:
		drop()
	if player_input.interacting:
		interact()
	move(direction, player_input.jumping, delta)
	movement_based_fov_change(delta)

func drop() -> void:
	# Nothing to drop
	if holder.remote_path == NodePath(""):
		return

	# Dropping object
	var holding_object = get_node(holder.remote_path) as Node3D
	# TODO: Drop noise
	holder.remote_path = NodePath("")
	holding_object.rotation = Vector3.ZERO
	
	# Raycast below the object to find out where to drop it
	var space_state = get_world_3d().direct_space_state
	var origin = holding_object.global_position
	var end = origin + Vector3.DOWN * 1000
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	holding_object.position.y = result.position.y

func interact() -> void:
	# Interacting with air
	if interacter.current_interactable == null:
		# TODO: Error noise
		return
	
	# Can't pick up something while holding another thing
	if holder.remote_path != NodePath(""):
		# TODO: Error noise
		return
	
	# TODO: Play an animation to hide response time from server
	
	InteractionHandler.attempt_interaction(multiplayer.get_unique_id(), interacter.current_interactable.get_path())

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
