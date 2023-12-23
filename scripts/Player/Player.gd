extends CharacterBody3D
class_name Player

signal interacted
signal no_longer_busy
signal holding_something(player: Player, something: Node3D)
signal dropped_something(player: Player, something: Node3D)

signal state_changed(flags: int, changed: int)
var state : int = 0 : 
	set(value):
		if state != value:
			var changed = state ^ value
			state = value
			state_changed.emit(state, changed)
enum Flags {
	NONE = 0,
	
	# Movement
	WALKING = 1 << 0,
	SPRINTING = 1 << 1,
	CROUCHING = 1 << 2,
	JUMPING = 1 << 3,
	FALLING = 1 << 4,
	LANDED = 1 << 5,
	
	# Interactions
	BUSY = 1 << 6, # Doing something clientside
	INTERACTING = 1 << 7,
	HOLDING = 1 << 8,
	DROPPING = 1 << 9,
	
	# States
	OXYGEN_BREATHING = 1 << 10,
	OXYGEN_DEPRIVED = 1 << 11,
	
}

signal _health_changed(value: float)
signal _oxygen_changed(value: float)
signal _stamina_changed(value: float)

const WALK_SPEED = 1.5
const RUN_SPEED = 2.5
const CROUCH_SPEED = 0.8
const JUMP_VELOCITY = 3.0
const FOV_CHANGE = 2.0

@export var crouched_size = 0.5
@export var uncrouched_size = 1.0

@onready var player_input : PlayerInput = $PlayerInput
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var camera : Camera3D = $Camera3D
@onready var interacter : Interacter = $Camera3D/Interacter
@onready var holder : RemoteTransform3D = $Camera3D/Holder
@onready var skeleton_3d : Skeleton3D = $bean_armature/Armature/Skeleton3D
@onready var stamina_bar : TextureProgressBar = $Camera3D/HUD/StaminaProgressBar
@onready var walking_collider : CollisionShape3D = $WalkingCollisionShape3D
@onready var crouching_collider : CollisionShape3D = $CrouchingCollisionShape3D

var look_speed = .005
var move_speed = WALK_SPEED
var flat_move_speed_mod = 0.0
var head_bone_id = -1
var base_fov = 80.0
var stamina = 100.0
var stamina_recharge_per_frame = 0.2
var stamina_consume_rate_per_frame = 0.8

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@rpc("authority", "call_remote", "reliable")
func notify_crouch() -> void:
	crouch()

@rpc("authority", "call_remote", "reliable")
func notify_uncrouch() -> void:
	uncrouch()

func get_held_node() -> Node3D:
	return get_node_or_null(holder.remote_path)

func _ready():
	if is_multiplayer_authority():
		set_clientside_settings()
	else:
		set_peer_settings()
	
	# Common between peer/client settings
	head_bone_id = skeleton_3d.find_bone("Head")
	state_changed.connect(_on_state_changed)

## Settings for the controlling player on their client
func set_clientside_settings() -> void:
	$bean_armature/Armature/Skeleton3D/Eyes.hide()
	state |= Flags.OXYGEN_BREATHING
	base_fov = camera.fov

## Settings for the spawned player peers
func set_peer_settings() -> void:
	$Camera3D/HUD.hide()

func _on_state_changed(new_state: int, changed: int) -> void:
	if changed & Flags.BUSY and not new_state & Flags.BUSY:
		no_longer_busy.emit()
	
	if changed & Flags.INTERACTING:
		if new_state & Flags.INTERACTING:
			interact()
	
	if changed & Flags.DROPPING:
		if new_state & Flags.DROPPING:
			drop()
	
	if changed & Flags.CROUCHING:
		if new_state & Flags.CROUCHING:
			crouch()
		else:
			uncrouch()
	
	if new_state & Flags.SPRINTING:
		move_speed = RUN_SPEED
		stamina_bar.tint_progress.a = 1.0
	elif new_state & Flags.CROUCHING:
		move_speed = CROUCH_SPEED
		stamina_bar.tint_progress.a = 0.4
	elif new_state & Flags.WALKING:
		move_speed = WALK_SPEED
		stamina_bar.tint_progress.a = 0.4
	else:
		stamina_bar.tint_progress.a = 0.4

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
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide() # need this for is_on_floor() to work
		return
	
	if state & Flags.BUSY:
		if player_input.interacting or player_input.dropping:
			state &= ~Flags.BUSY
		return
	
	var new_state = state
	var direction = (transform.basis * Vector3(player_input.x, 0, player_input.y)).normalized()
	
	# Interaction States
	if player_input.dropping:
		new_state |= Flags.DROPPING
	if player_input.interacting:
		new_state = (new_state & ~Flags.BUSY) | Flags.INTERACTING
	
	# Movement States
	if player_input.sprinting and stamina > 0.0:
		new_state = (new_state & ~(Flags.CROUCHING | Flags.WALKING)) | Flags.SPRINTING
	elif player_input.crouching:
		if not new_state & Flags.CROUCHING:
			new_state = (new_state & ~Flags.SPRINTING) | Flags.CROUCHING
		else:
			new_state &= ~Flags.CROUCHING
	elif direction.length() > 0:
		new_state = (new_state & ~Flags.SPRINTING) | Flags.WALKING
	else:
		new_state = new_state & ~(Flags.SPRINTING | Flags.WALKING)
	
	# A single set to only trigger the state_changed signal once
	state = new_state
	
	# TODO: Move stamina into its own script listening for the states to adjust the value
	if state & Flags.SPRINTING:
		stamina = clampf(stamina - stamina_consume_rate_per_frame, 0.0, 100.0)
	else:
		stamina = clampf(stamina + stamina_recharge_per_frame, 0.0, 100.0)
	
	
	# TODO: Move stamina_bar into its own script listening for stamina changes
	stamina_bar.value = stamina
	
	move_speed += flat_move_speed_mod
	move(direction, player_input.jumping, delta)
	movement_based_fov_change(delta)
	animate()

func drop() -> void:
	if holder.remote_path != NodePath(""):
		InteractionHandler.attempt_drop_node(multiplayer.get_unique_id())
	state &= ~Flags.DROPPING

func drop_node() -> void:
	var dropping = get_held_node()
	holder.remote_path = NodePath("")
	state &= ~(Flags.HOLDING | Flags.DROPPING)
	dropped_something.emit(self, dropping)
	
	if is_multiplayer_authority():
		interacter.enable()

func hold(node_path: String) -> void:
	holder.remote_path = node_path
	state = (state & ~Flags.INTERACTING) | Flags.HOLDING
	holding_something.emit(self, get_held_node())

func interact() -> void:
	# Interacting with air or doing something already
	if interacter.current_interactable != null:
		# TODO: Play an animation to hide response time from server
		InteractionHandler.attempt_interaction(multiplayer.get_unique_id(), interacter.current_interactable.get_path())
		interacted.emit()
	
	state &= ~Flags.INTERACTING

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

func peer_animate() -> void:
	if is_multiplayer_authority():
		return
	
	if velocity.length() > 0 and is_on_floor():
		animation_player.speed_scale = clamp(velocity.length(), 1.0, 1.8)
		animation_player.play("walking")
	else:
		if animation_player.is_playing():
			if not is_on_floor():
				animation_player.stop()
			else:
				# Wait until the looping animation finished and ensure they're idle
				# Then stop the animation
				await get_tree().create_timer(animation_player.current_animation_length - animation_player.current_animation_position).timeout
				if velocity.length() == 0:
					animation_player.stop()
		else:
			animation_player.stop()

func animate() -> void:
	# TODO: Create client-side animation for moving some hands
	if not is_multiplayer_authority():
		return

func crouch() -> void:
	walking_collider.disabled = true
	crouching_collider.disabled = false
	
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(skeleton_3d, "scale:y", crouched_size, 0.2).set_ease(Tween.EASE_IN)
	if is_multiplayer_authority():
		t.tween_property(camera, "position", $CrouchCameraPosition.position, 0.2).set_ease(Tween.EASE_IN)
		notify_crouch.rpc()

func uncrouch() -> void:
	walking_collider.disabled = false
	crouching_collider.disabled = true
	
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(skeleton_3d, "scale:y", uncrouched_size, 0.2).set_ease(Tween.EASE_OUT)
	if is_multiplayer_authority():
		t.tween_property(camera, "position", $WalkingCameraPosition.position, 0.2).set_ease(Tween.EASE_OUT)
		notify_uncrouch.rpc()

func turn_flags_on(flags: int) -> void:
	state |= flags

func turn_flags_off(flags: int) -> void:
	state &= ~flags

func apply_flat_move_speed_mod(amount: float) -> void:
	flat_move_speed_mod += amount

#region Elevator Pushing Player Through World Solution
func _on_moving_object_detector_body_entered(body):
	add_collision_exception_with(body)

func _on_moving_object_detector_body_exited(body):
	remove_collision_exception_with(body)
#endregion

# Animate clients necks
func _on_multiplayer_synchronizer_synchronized():
	skeleton_3d.set_bone_pose_rotation(head_bone_id, Quaternion.from_euler(Vector3(-player_input.neck_look, 0.0, 0.0)))
	peer_animate()
