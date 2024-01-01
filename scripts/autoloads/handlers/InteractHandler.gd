extends Node

## Autoloaded

## Class to authoritatively handle interactions
## This helps avoid race conditions on who owns what object in the world
## Ex: Player 1 and Player 2 press Interact at the same time with similar ping
##     Each player might see on their screen they got the object, but the other player has it instead
## While the server is resolving the interaction, we can hide the delay by playing an animation

var queue : Array[InteractRequest] = []
var sequence_number = 0

class InteractRequest extends Request:
	var interacter_id: int
	var interacting: Interactable


@rpc("any_peer", "call_remote", "reliable")
func tell_server_of_interaction(node_path: String) -> void:
	var interacter = PlayerManager.get_player_by_id(multiplayer.get_remote_sender_id())
	var interactable = get_node_or_null(node_path)
	request_interaction(interacter, interactable)

@rpc("authority", "call_remote", "reliable")
func broadcast_interaction(p_id: int, path_to_interacted_node: String) -> void:
	var interacter = PlayerManager.get_player_by_id(p_id)
	var interactable = get_node_or_null(path_to_interacted_node)
	interact(interacter, interactable)

func interact(player: Player, interactable: Interactable) -> void:
	if interactable == null:
		return
	
	if interactable is Interactable:
		interactable.interact(player)

func request_interaction(player: Player, interacted_node: Node3D) -> InteractRequest:
	var request = InteractRequest.new()
	request.interacter_id = player.name.to_int()
	request.interacting = interacted_node
	if multiplayer.is_server():
		queue_request(request)
	elif interacted_node != null:
		tell_server_of_interaction.rpc_id(1, interacted_node.get_path())
	return request

func evaluate_interact(p_id: int, interactable: Interactable) -> void:
	var player = PlayerManager.get_player_by_id(p_id)
	if player == null:
		return
	
	# Interacting with air
	if interactable == null or not interactable is Interactable:
		return
	
	# Player is too far, maybe spoofed packet, or terrible lag
	# Ideally we would check against a sequence number and store player positions
	# relative to sequence numbers so we can look back on this position instead of their
	# current server position
	if player.global_position.distance_to(interactable.global_position) > Constants.ACCEPTABLE_INTERACTABLE_DISTANCE_IN_M:
		return
	
	interact(player, interactable)
	broadcast_interaction.rpc(p_id, interactable.get_path())

func fail_request(request: InteractRequest) -> void:
	push_warning("[InteractHandler] Request %s failed Interacter: %s, Interacting: %s" %
		[request.sequence, request.interacter_id, request.interacting])
	request.fail()

func process_request(request: InteractRequest) -> void:
	var interacter = PlayerManager.get_player_by_id(request.interacter_id)
	if interacter == null or request.interacting == null:
		fail_request(request)
	else:
		evaluate_interact(request.interacter_id, request.interacting)

## Puts the request in the queue
## returns if it was able to put it in the queue
func queue_request(request: Request) -> bool:
	sequence_number += 1
	request.sequence = sequence_number
	queue.push_back(request)
	return true

func process_queue() -> void:
	for request in queue:
		process_request(request)
	queue.clear()
