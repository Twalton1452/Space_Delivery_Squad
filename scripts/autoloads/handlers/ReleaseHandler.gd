extends Node

## Autoloaded

## Class to hold onto requests that come in to release items into mostly Slots
## Should solve race conditions where two clients try to release something into a Slot
## at the same time.

var queue : Array[ReleaseRequest] = []
var sequence_number = 0

class ReleaseRequest extends Request:
	var releaser_id: int
	var releasing: Node3D
	var releasing_to: Node3D

#region Client/Server RPCs
@rpc("any_peer", "call_remote", "reliable")
func tell_server_of_player_release_request(releasing_node_path: String, receiver_node_path: String) -> void:
	var releaser = PlayerManager.get_player_by_id(multiplayer.get_remote_sender_id())
	var releasing = get_node_or_null(releasing_node_path)
	var receiver = get_node_or_null(receiver_node_path)
	request_player_release(releaser, releasing, receiver)

@rpc("authority", "call_remote", "reliable")
func broadcast_player_released_node(p_id: int, releasing_node_path: String, path_to_receiver_node: String) -> void:
	var player = PlayerManager.get_player_by_id(p_id)
	if player == null:
		return
	
	release_node_to_slot(p_id, releasing_node_path, path_to_receiver_node)
#endregion Client/Server RPCs

# Ask what is being released specifically instead of inferring it from the player's
# held item. This way we can notify clients that are desync'd correctly and get back on track
func request_player_release(releaser: Player, releasing: Node3D, released_to: Node3D) -> ReleaseRequest:
	var request = ReleaseRequest.new()
	request.releaser_id = releaser.name.to_int()
	request.releasing = releasing
	request.releasing_to = released_to
	if multiplayer.is_server():
		queue_request(request)
		#var result = await request.resolved
	elif released_to != null:
		tell_server_of_player_release_request.rpc_id(1, releasing.get_path(), released_to.get_path())
	return request

func release_node_to_slot(p_id: int, releasing_path: String, slot_path: String) -> void:
	var player = PlayerManager.get_player_by_id(p_id)
	var releasing_node = get_node_or_null(releasing_path)
	# If the player was still holding it, tell them to drop it
	if player != null and releasing_node == player.get_held_node():
		player.drop_node()
	
	# Receive the node into the Slot even if the player wasn't holding it anymore
	# May be able to help recover from Desyncs this way
	var slot : Slot = get_node_or_null(slot_path)
	if releasing_node != null and slot != null and !slot.is_holding_node():
		slot.receive_node(releasing_node)

## Make sure the release request can go through before we tell the clients
func evaluate_release(p_id: int, releasing: Node3D, receiver: Node3D) -> void:
	var player = PlayerManager.get_player_by_id(p_id)
	if player == null or not player.is_holding_node():
		return
	
	if releasing == null or receiver == null:
		return
	
	if receiver is Slot:
		if receiver.is_holding_node():
			return
		
		release_node_to_slot(p_id, releasing.get_path(), receiver.get_path())
		broadcast_player_released_node.rpc(p_id, releasing.get_path(), receiver.get_path())

func fail_request(request: ReleaseRequest) -> void:
	push_warning("[ReleaseHandler] Request %s failed Releaser: %s, Releasing: %s, Releasing to %s" %
		[request.sequence, request.releaser_id, request.releasing, request.releasing_to])
	request.fail()

func process_request(request: ReleaseRequest) -> void:
	var releaser = PlayerManager.get_player_by_id(request.releaser_id)
	if releaser == null or request.releasing == null or request.releasing_to == null:
		fail_request(request)
	else:
		evaluate_release(request.releaser_id, request.releasing, request.releasing_to)

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
