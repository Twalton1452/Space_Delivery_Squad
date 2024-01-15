extends Node
class_name Health

signal damaged(current_health: float)

@export var visual_bar : TextureProgressBar
@export var max_health = 100.0
@export var value = 100.0 : 
	set(new_value):
		value = new_value
		visual_bar.value = value

@onready var player : Player = $"../.."

var oxygen_deprived_damage = 100.0

func _ready() -> void:
	player.state_changed.connect(_on_player_state_changed)
	idle_visual()

func idle_visual() -> void:
	visual_bar.tint_progress.a = 0.4

func active_visual() -> void:
	visual_bar.tint_progress.a = 1.0

func _on_player_state_changed(flags: int, changed: int) -> void:
	if changed & Player.Flags.OXYGEN_DEPRIVED:
		if flags & Player.Flags.OXYGEN_DEPRIVED:
			take_damage(oxygen_deprived_damage)
		else:
			pass

func take_damage(amount: float) -> void:
	value -= amount
	if value >= max_health:
		player.turn_flags_off(Player.Flags.DAMAGED)
		idle_visual()
	elif value > 0.0:
		player.turn_flags_on(Player.Flags.DAMAGED)
		active_visual()
	else:
		player.turn_flags_on(Player.Flags.DEAD)
		active_visual()
