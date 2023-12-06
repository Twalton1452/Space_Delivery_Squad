extends Node

## Autoloaded

## Class to authoritatively handle interactions
## This helps avoid race conditions on who owns what object in the world
## Ex: Player 1 and Player 2 press Interact at the same time with similar ping
##     Each player might see on their screen they got the object, but the other player has it instead
## While the server is resolving the interaction, we can hide the delay by playing an animation

const ACCEPTABLE_PICKUP_DISTANCE_IN_M = 5


@rpc("any_peer", "call_remote", "reliable")
func tell_server_of_interaction_attempt_by_client(p_id, node_path: String) -> void:
	interact(p_id, node_path)

@rpc("authority", "call_remote", "reliable")
func notify_peers_of_interaction(p_id: int, path_to_interacted_node: String) -> void:
	var player = PlayerManager.get_player_by_id(p_id)
	if player == null:
		return
	
	interact_with_node(player, path_to_interacted_node)

func interact_with_node(player: Player, node_path: String) -> void:
	player.holder.remote_path = node_path

func attempt_interaction(p_id: int, node_path: String) -> void:
	if multiplayer.is_server():
		interact(p_id, node_path)
		return
	
	tell_server_of_interaction_attempt_by_client.rpc_id(1, p_id, node_path)

func interact(p_id: int, node_path: String) -> bool:
	var player = PlayerManager.get_player_by_id(p_id)
	if player == null:
		return false
	
	var player_attempting_to_interact_with = get_node(node_path)
	
	# Interacting with air
	if player_attempting_to_interact_with == null:
		return false
	
	# Player is too far, maybe spoofed packet, or terrible lag
	if player.position.distance_to(player_attempting_to_interact_with.position) > ACCEPTABLE_PICKUP_DISTANCE_IN_M:
		return false
	
	# Can't pick up something while holding another thing
	if player.holder.remote_path != NodePath(""):
		return false
	
	var path_to_interactable = player_attempting_to_interact_with.get_parent().get_path()
	interact_with_node(player, path_to_interactable)
	notify_peers_of_interaction.rpc(p_id, path_to_interactable)
	return true
