extends Node
class_name Stamina

@export var visual_bar : TextureProgressBar
@export var max_stamina = 100.0
@export var value = 100.0 : 
	set(new_value):
		value = new_value
		visual_bar.value = value
@export var recharge_rate_per_second = 15.0
@export var consume_rate_per_second = 20.0

@onready var player : Player = $"../.."

var can_sprint = true : 
	get:
		return value > 0.0
var recharging = true
var draining = false

func _ready() -> void:
	player.state_changed.connect(_on_player_state_changed)
	idle_visual()

func _on_player_state_changed(flags: int, _changed: int) -> void:
	if flags & Player.Flags.SPRINTING:
		stop_recharge_stamina()
		begin_draining_stamina()
	else:
		stop_draining_stamina()
		begin_recharge_stamina()

func idle_visual() -> void:
	visual_bar.tint_progress.a = 0.4

func active_visual() -> void:
	visual_bar.tint_progress.a = 1.0

func begin_draining_stamina() -> void:
	if draining:
		return
	
	draining = true
	active_visual()
	drain_stamina()

func drain_stamina() -> void:
	var percent_per_frame = consume_rate_per_second / Engine.physics_ticks_per_second
	while draining:
		value = clampf(value - percent_per_frame, 0.0, max_stamina)
		await get_tree().physics_frame
		if value <= 0.0:
			draining = false

func stop_draining_stamina() -> void:
	draining = false

func begin_recharge_stamina() -> void:
	if recharging:
		return
	
	recharging = true
	idle_visual()
	recharge_stamina()

func recharge_stamina() -> void:
	var percent_per_frame = recharge_rate_per_second / Engine.physics_ticks_per_second
	while recharging:
		value = clampf(value + percent_per_frame, 0.0, max_stamina)
		await get_tree().physics_frame
		if value >= max_stamina:
			recharging = false

func stop_recharge_stamina() -> void:
	recharging = false
