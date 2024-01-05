extends Node
class_name PowerLoss

func _ready() -> void:
	PowerGrid.power_lost.connect(_on_power_lost)
	PowerGrid.power_gained.connect(_on_power_gained)

func _on_power_lost() -> void:
	for child in get_tree().get_nodes_in_group("Lights").front().get_children():
		(child as Light3D).hide()
	
	for player in PlayerManager.get_players():
		player.turn_flags_on(Player.Flags.OXYGEN_DEPLETING)
	
	for power_consumer in get_tree().get_nodes_in_group(Constants.POWER_CONSUMER_GROUP):
		(power_consumer as PowerConsumer).turn_off_functionality()
	
	for power_fallback in get_tree().get_nodes_in_group(Constants.POWER_FALLBACK_GROUP):
		(power_fallback as PowerFallback).turn_on_functionality()

func _on_power_gained() -> void:
	for child in get_tree().get_nodes_in_group("Lights").front().get_children():
		(child as Light3D).show()
	
	for player in PlayerManager.get_players():
		player.turn_flags_off(Player.Flags.OXYGEN_DEPLETING)
	
	for power_consumer in get_tree().get_nodes_in_group(Constants.POWER_CONSUMER_GROUP):
		(power_consumer as PowerConsumer).turn_on_functionality()
	
	for power_fallback in get_tree().get_nodes_in_group(Constants.POWER_FALLBACK_GROUP):
		(power_fallback as PowerFallback).turn_off_functionality()
