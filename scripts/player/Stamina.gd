extends Node
class_name Stamina

@export var visual_bar : TextureProgressBar
@export var max_stamina = 100.0
@export var value = 100.0 : 
	set(new_value):
		value = new_value
		visual_bar.value = value
@export var recharge_rate_per_frame = 0.2
@export var consume_rate_per_frame = 0.8

@onready var player : Player = $"../.."

var can_sprint = true : 
	get:
		return value > consume_rate_per_frame
var recharging = true
var draining = false

func _ready() -> void:
	player.state_changed.connect(_on_player_state_changed)

func _on_player_state_changed(flags: int, _changed: int) -> void:
	if flags & Player.Flags.SPRINTING:
		stop_recharge_stamina()
		begin_draining_stamina()
	else:
		stop_draining_stamina()
		begin_recharge_stamina()


func begin_draining_stamina() -> void:
	draining = true
	visual_bar.tint_progress.a = 1.0
	drain_stamina()

func drain_stamina() -> void:
	while draining:
		value = clampf(value - consume_rate_per_frame, 0.0, max_stamina)
		await get_tree().physics_frame
		if value <= 0.0:
			draining = false

func stop_draining_stamina() -> void:
	draining = false

func begin_recharge_stamina() -> void:
	recharging = true
	visual_bar.tint_progress.a = 0.4
	recharge_stamina()

func recharge_stamina() -> void:
	while recharging:
		value = clampf(value + recharge_rate_per_frame, 0.0, max_stamina)
		await get_tree().physics_frame
		if value >= max_stamina:
			recharging = false

func stop_recharge_stamina() -> void:
	recharging = false
