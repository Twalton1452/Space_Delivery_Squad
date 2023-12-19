extends Node

## Autoloaded

## Class to authoritatively handle interactions
## This helps avoid race conditions on who owns what object in the world
## Ex: Player 1 and Player 2 press Interact at the same time with similar ping
##     Each player might see on their screen they got the object, but the other player has it instead
## While the server is resolving the interaction, we can hide the delay by playing an animation

@rpc("any_peer", "call_remote", "reliable")
func tell_server_of_interaction_attempt_by_client(p_id, node_path: String) -> void:
	interact(p_id, node_path)

@rpc("authority", "call_remote", "reliable")
func notify_peers_of_interaction(p_id: int, path_to_interacted_node: String) -> void:
	var player = PlayerManager.get_player_by_id(p_id)
	if player == null:
		return
	
	interact_with_node(player, path_to_interacted_node)

@rpc("any_peer", "call_remote", "reliable")
func tell_server_of_drop_attempt_by_client(p_id) -> void:
	drop(p_id)

@rpc("authority", "call_remote", "reliable")
func notify_peers_of_drop(p_id: int, dropped_node_position: Vector3) -> void:
	var player = PlayerManager.get_player_by_id(p_id)
	if player == null:
		return
	
	drop_node(player, dropped_node_position)

func attempt_drop_node(p_id: int) -> void:
	if multiplayer.is_server():
		drop(p_id)
		return
	
	tell_server_of_drop_attempt_by_client.rpc_id(1, p_id)

func interact_with_node(player: Player, interactable_node_path: String) -> void:
	var node_on_interactable_layer = get_node(interactable_node_path)
	if node_on_interactable_layer is Interactable:
		node_on_interactable_layer.interact(player)
		return
	
	# Node has no "interact" method, must be trying to pick something up
	if player.get_held_node() != null:
		return
	
	player.hold(node_on_interactable_layer.get_parent().get_path())
	var held_node = get_node(interactable_node_path) as CollisionObject3D
	held_node.collision_layer = Constants.NON_INTERACTABLE_COLLISION_LAYERS

func drop_node(player: Player, dropped_node_position: Vector3) -> void:
	var held_node = player.get_held_node()
	player.drop_node()
	if held_node == null:
		return
	
	held_node.position = dropped_node_position
	held_node.rotation = Vector3.ZERO
	for child in held_node.get_children():
		if child is Area3D:
			child.collision_layer = Constants.INTERACTABLE_COLLISION_LAYERS
			break

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
	if player.global_position.distance_to(player_attempting_to_interact_with.global_position) > Constants.ACCEPTABLE_INTERACTABLE_DISTANCE_IN_M:
		return false
	
	var path_to_interactable = player_attempting_to_interact_with.get_path()
	interact_with_node(player, path_to_interactable)
	notify_peers_of_interaction.rpc(p_id, path_to_interactable)
	return true

func drop(p_id: int) -> void:
	var player := PlayerManager.get_player_by_id(p_id)
	if player == null:
		return
	
	var player_held_node = player.get_held_node()
	# Nothing to drop
	if player_held_node == null:
		return
	
	# Dropping object
	# Raycast below the object to find out where to drop it
	var space_state = player.get_world_3d().direct_space_state
	var origin = player_held_node.global_position
	var end = origin + Vector3.DOWN * 1000
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	# No placeable ground
	if result.size() == 0:
		return
	
	var dropped_position = player_held_node.position
	dropped_position.y = result.position.y
	drop_node(player, dropped_position)
	
	notify_peers_of_drop.rpc(p_id, dropped_position)
