extends PlayerEffect
class_name MoveSpeedEffect

var amount: float = 1.0

func begin() -> void:
	affected.apply_flat_move_speed_mod(amount)

func end() -> void:
	affected.apply_flat_move_speed_mod(-amount)
