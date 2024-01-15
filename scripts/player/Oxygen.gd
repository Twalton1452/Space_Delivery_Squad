extends Node
class_name Oxygen

@export var visual_bar : TextureProgressBar
@export var max_oxygen = 100.0
@export var value = 100.0 : 
	set(new_value):
		value = new_value
		visual_bar.value = value
@export var recharge_rate_per_second = 2.0
@export var consume_rate_per_second = 1.0

@onready var player : Player = $"../.."

var can_breathe = true : 
	get:
		return value > 0.0
var recharging = true
var draining = false

func _ready() -> void:
	player.state_changed.connect(_on_player_state_changed)
	idle_visual()

func _on_player_state_changed(flags: int, changed: int) -> void:
	if changed & Player.Flags.OXYGEN_DEPLETING:
		if flags & Player.Flags.OXYGEN_DEPLETING:
			begin_draining_oxygen()
		else:
			begin_recharging_oxygen()
	
	if changed & Player.Flags.OXYGEN_DEPRIVED:
		# TODO: Some kind of Ticking Debuff that applies damage?
		if flags & Player.Flags.OXYGEN_DEPRIVED:
			pass
		else:
			pass

func idle_visual() -> void:
	visual_bar.tint_progress.a = 0.4

func active_visual() -> void:
	visual_bar.tint_progress.a = 1.0

func begin_draining_oxygen() -> void:
	if draining:
		return
	
	recharging = false
	draining = true
	active_visual()
	drain_oxygen()

func drain_oxygen() -> void:
	var percent_per_frame = consume_rate_per_second / Engine.physics_ticks_per_second
	while draining:
		value = clampf(value - percent_per_frame, 0.0, max_oxygen)
		
		await get_tree().physics_frame
		if value <= 0.0:
			draining = false
			player.turn_flags_on(Player.Flags.OXYGEN_DEPRIVED)

func begin_recharging_oxygen() -> void:
	if recharging:
		return
	
	draining = false
	recharging = true
	idle_visual()
	recharge_oxygen()

func recharge_oxygen() -> void:
	player.turn_flags_off(Player.Flags.OXYGEN_DEPLETING)
	if player.is_flag_on(Player.Flags.OXYGEN_DEPRIVED):
		player.turn_flags_off(Player.Flags.OXYGEN_DEPRIVED)
	
	var percent_per_frame = recharge_rate_per_second / Engine.physics_ticks_per_second
	while recharging:
		value = clampf(value + percent_per_frame, 0.0, max_oxygen)
		
		await get_tree().physics_frame
		if value >= max_oxygen:
			recharging = false
