extends CharacterBody3D
class_name Player

signal interacted

const WALK_SPEED = 2.0
const JUMP_VELOCITY = 3.0
const BASE_FOV = 75.0
const FOV_CHANGE = 2.0

@onready var player_input : PlayerInput = $PlayerInput
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var camera : Camera3D = $Camera3D
@onready var interacter : Interacter = $Camera3D/Interacter
@onready var holder : RemoteTransform3D = $Camera3D/Holder

var look_speed = .005
var move_speed = WALK_SPEED

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func get_held_node() -> Node3D:
	return get_node_or_null(holder.remote_path)

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
		move_and_slide()
		animate()
		return
	
	var direction = (transform.basis * Vector3(player_input.x, 0, player_input.y)).normalized()
	if player_input.dropping:
		drop()
	if player_input.interacting:
		interact()
	move(direction, player_input.jumping, delta)
	movement_based_fov_change(delta)
	animate()

func drop() -> void:
	# Nothing to drop
	if holder.remote_path == NodePath(""):
		return

	InteractionHandler.attempt_drop_node(multiplayer.get_unique_id())

func drop_node() -> void:
	holder.remote_path = NodePath("")

func hold(node_path: String) -> void:
	holder.remote_path = node_path

func interact() -> void:
	# Interacting with air
	if interacter.current_interactable == null:
		# TODO: Error noise
		return
	
	# TODO: Play an animation to hide response time from server
	
	InteractionHandler.attempt_interaction(multiplayer.get_unique_id(), interacter.current_interactable.get_path())
	interacted.emit()

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

func animate() -> void:
	# TODO: Create client-side animation for moving some hands
	if is_multiplayer_authority():
		return
	
	if velocity.length() > 0 and is_on_floor():
		animation_player.play("walking")
	else:
		if animation_player.is_playing():
			# Wait until the looping animation finished and ensure they're idle
			# Then stop the animation
			await get_tree().create_timer(animation_player.current_animation_length - animation_player.current_animation_position).timeout
			if velocity.length() == 0:
				animation_player.stop()
		else:
			animation_player.stop()
