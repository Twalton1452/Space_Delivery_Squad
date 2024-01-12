extends Node3D
class_name OxygenStation

## Source of truth for Oxygen on the Ship

signal enabled
signal disabled

var airlock_disaster : Event = load("res://resources/disasters/airlock.tres")
var power_loss_disaster : Event = load("res://resources/disasters/power_loss.tres")

func _ready() -> void:
	airlock_disaster.started.connect(_on_airlock_disaster_started)
	airlock_disaster.ended.connect(_on_airlock_disaster_ended)
	power_loss_disaster.started.connect(_on_power_loss_disaster_started)
	power_loss_disaster.ended.connect(_on_power_loss_disaster_ended)

func _on_airlock_disaster_started() -> void:
	disable()

func _on_airlock_disaster_ended() -> void:
	enable()

func _on_power_loss_disaster_started() -> void:
	disable()

func _on_power_loss_disaster_ended() -> void:
	enable()

func enable() -> void:
	# NOTE: OxygenStation has a PowerConsumer attached which calls enable() when power comes back
	# 		However we still want it to remain in an "off" state if other events are happening
	if airlock_disaster.occurring or power_loss_disaster.occurring:
		return
	
	enabled.emit()
	for player in PlayerManager.get_players():
		player.turn_flags_off(Player.Flags.OXYGEN_DEPLETING)

func disable() -> void:
	disabled.emit()
	for player in PlayerManager.get_players():
		player.turn_flags_on(Player.Flags.OXYGEN_DEPLETING)
