extends BaseEffect
class_name PlayerEffect
	
var affected: Player

func _init(affected_player: Player) -> void:
	affected = affected_player
