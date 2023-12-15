extends CharacterBody3D
class_name Player

signal interacted

const WALK_SPEED = 1.5
const RUN_SPEED = 2.0
const JUMP_VELOCITY = 3.0
const FOV_CHANGE = 2.0

@onready var player_input : PlayerInput = $PlayerInput
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var camera : Camera3D = $Camera3D
@onready var interacter : Interacter = $Camera3D/Interacter
@onready var holder : RemoteTransform3D = $Camera3D/Holder
@onready var skeleton_3d : Skeleton3D = $bean_armature/Armature/Skeleton3D
@onready var stamina_bar : TextureProgressBar = $Camera3D/HUD/StaminaProgressBar

var look_speed = .005
var move_speed = WALK_SPEED
var head_bone_id = -1
var base_fov = 80.0
var stamina = 100.0
var stamina_recharge_per_frame = 0.2
var stamina_consume_rate_per_frame = 0.8

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func get_held_node() -> Node3D:
	return get_node_or_null(holder.remote_path)

func _ready():
	if is_multiplayer_authority():
		$bean_armature/Armature/Skeleton3D/Eyes.hide()
	else:
		stamina_bar.hide()
	head_bone_id = skeleton_3d.find_bone("Head")
	base_fov = camera.fov

## Based on the velocity, change the camera's FOV
## not used at the moment because the x,z velocity don't reset to 0
## so the fov never changes back once it gets modified unless hitting a wall
func movement_based_fov_change(delta) -> void:
	var velocity_clamped = clamp(velocity.length(), 0.5, move_speed * 2)
	var target_fov = base_fov + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

## Server receives Input from clients and moves them
func _physics_process(delta):
	if not is_multiplayer_authority():
		animate()
		return
	
	var direction = (transform.basis * Vector3(player_input.x, 0, player_input.y)).normalized()
	if player_input.dropping:
		drop()
	if player_input.interacting:
		interact()
	
	# Hasty implementation for now
	# TODO: Move stamina_bar into its own script listening for stamina changes
	stamina = clampf(stamina + stamina_recharge_per_frame - (stamina_consume_rate_per_frame * player_input.sprinting), 0.0, 100.0)
	stamina_bar.value = stamina
	
	if player_input.sprinting and stamina > 0.0:
		move_speed = WALK_SPEED + RUN_SPEED
		stamina_bar.tint_progress.a = 1.0
		stamina_bar.show()
	else:
		move_speed = WALK_SPEED
		stamina_bar.tint_progress.a = 0.4
		if stamina >= 100.0:
			stamina_bar.hide()
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
		animation_player.speed_scale = clamp(velocity.length(), 1.0, 1.8)
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

#region Elevator Pushing Player Through World Solution
func _on_moving_object_detector_body_entered(body):
	add_collision_exception_with(body)

func _on_moving_object_detector_body_exited(body):
	remove_collision_exception_with(body)
#endregion

# Animate clients necks
func _on_multiplayer_synchronizer_synchronized():
	skeleton_3d.set_bone_pose_rotation(head_bone_id, Quaternion.from_euler(Vector3(-player_input.neck_look, 0.0, 0.0)))
