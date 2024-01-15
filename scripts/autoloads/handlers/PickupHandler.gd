extends Node

## Autoloaded

var queue : Array[PickupRequest] = []
var sequence_number = 0

class PickupRequest extends Request:
	var picker_upper_id: int
	var to_pick_up: Item

#region Client/Server RPCs
@rpc("any_peer", "call_remote", "reliable")
func tell_server_of_pickup_request(to_be_picked_up_path: String) -> void:
	var picker_upper = PlayerManager.get_player_by_id(multiplayer.get_remote_sender_id())
	var to_be_picked_up = get_node_or_null(to_be_picked_up_path)
	request_pickup(picker_upper, to_be_picked_up)

@rpc("authority", "call_remote", "reliable")
func broadcast_picked_up_node(p_id: int, picked_up_node_path: String) -> void:
	var picker_upper = PlayerManager.get_player_by_id(p_id)
	var to_be_picked_up = get_node_or_null(picked_up_node_path)
	pickup(picker_upper, to_be_picked_up)
#endregion Client/Server RPCs

func pickup(picker_upper: Player, to_be_picked_up: Item) -> void:
	if to_be_picked_up == null:
		return
	
	if picker_upper.get_held_node() != null:
		# Pickup request went through but the client has something else somehow
		# Maybe override what the Player has right now and ask the server where this
		# unknown item should be going?
		if picker_upper.get_held_node() != to_be_picked_up:
			pass
		return

	picker_upper.hold(to_be_picked_up)
	to_be_picked_up.on_held(picker_upper)

func request_pickup(picker_upper: Player, to_be_picked_up: Item) -> PickupRequest:
	var request = PickupRequest.new()
	request.picker_upper_id = picker_upper.name.to_int()
	request.to_pick_up = to_be_picked_up
	if multiplayer.is_server():
		queue_request(request)
		#var result = await request.resolved
	elif to_be_picked_up != null:
		tell_server_of_pickup_request.rpc_id(1, to_be_picked_up.get_path())
	return request

func evaluate_pickup(p_id: int, to_be_picked_up: Item) -> void:
	var picker_upper := PlayerManager.get_player_by_id(p_id)
	if picker_upper == null or picker_upper.get_held_node() != null:
		return
	
	pickup(picker_upper, to_be_picked_up)
	broadcast_picked_up_node.rpc(p_id, to_be_picked_up.get_path())

func process_request(request: PickupRequest) -> void:
	var picker_upper = PlayerManager.get_player_by_id(request.picker_upper_id)
	if picker_upper == null or request.to_pick_up == null:
		fail_request(request)
	else:
		evaluate_pickup(request.picker_upper_id, request.to_pick_up)
	
func fulfill_pickup(request: Request) -> void:
	request.fulfill()

func fail_request(request: Request) -> void:
	request.fail()

func invalidate_request(request: Request) -> void:
	request.invalidate()

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
