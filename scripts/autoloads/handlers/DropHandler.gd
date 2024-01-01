extends Node

## Autoloaded

var queue : Array[DropRequest] = []
var sequence_number = 0

class DropRequest extends Request:
	var dropper_id: int
	var dropping: Node3D

#region Client/Server RPCs
@rpc("any_peer", "call_remote", "reliable")
func tell_server_of_drop_request(dropping_path: String) -> void:
	var dropper = PlayerManager.get_player_by_id(multiplayer.get_remote_sender_id())
	var dropping = get_node_or_null(dropping_path)
	request_drop(dropper, dropping)

@rpc("authority", "call_remote", "reliable")
func broadcast_dropped_node(p_id: int, dropped_node_path: String, dropped_node_position: Vector3) -> void:
	var dropper = PlayerManager.get_player_by_id(p_id)
	var dropping = get_node_or_null(dropped_node_path)
	drop(dropper, dropping, dropped_node_position)
#endregion Client/Server RPCs

func request_drop(dropper: Player, dropping: Node3D) -> DropRequest:
	var request = DropRequest.new()
	request.dropper_id = dropper.name.to_int()
	request.dropping = dropping
	if multiplayer.is_server():
		queue_request(request)
		#var result = await request.resolved
	elif dropping != null:
		tell_server_of_drop_request.rpc_id(1, dropping.get_path())
	return request

func process_request(request: DropRequest) -> void:
	var dropper = PlayerManager.get_player_by_id(request.dropper_id)
	if dropper == null or request.dropping == null:
		fail_request(request)
	else:
		evaluate_drop(request.dropper_id)

func evaluate_drop(p_id: int) -> void:
	var player := PlayerManager.get_player_by_id(p_id)
	if player == null:
		return
	
	var player_held_node = player.get_held_node()
	# Nothing to drop
	if player_held_node == null:
		return
	
	# Dropping object
	# Raycast below the object to find out where to drop it
	## TODO: Crouching makes this fail, too close to the ground
	var result = Helpers.ray_cast(player_held_node, Vector3.DOWN, 1000.0)
	# No placeable ground
	if result.size() == 0:
		return
	
	var dropped_position = player_held_node.position
	dropped_position.y = result.position.y
	drop(player, player_held_node, dropped_position)
	
	var held_node_path = player_held_node.get_path()
	broadcast_dropped_node.rpc(p_id, held_node_path, dropped_position)
	
func drop(dropper: Player, dropped_node: Node3D, dropped_node_position: Vector3) -> void:
	var held_node = dropper.get_held_node()
	dropper.drop_node()
	
	# NOTE: Desync Protection
	# the client is requesting they are dropping what they have, but it doesn't
	# line up with the server. So just make the player drop what they have
	if held_node != dropped_node:
		return
	
	if dropped_node is Item:
		dropped_node.on_dropped()
	
	dropped_node.position = dropped_node_position
	dropped_node.rotation = Vector3.ZERO

func fulfill_drop(request: Request) -> void:
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
