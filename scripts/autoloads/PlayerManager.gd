extends Node

## Autoloaded

signal player_controlling_node(p_id: int)

var players = {}

class Info:
	var id: int
	var name: String
	var controlling_node: Node3D
	var color: Color
	
	func _init(p_id: int):
		id = p_id

@rpc("any_peer", "call_remote", "reliable")
func notify_of_peer_settings(p_name: String, color: Color) -> void:
	var info = get_by_id(multiplayer.get_remote_sender_id())
	info.name = p_name
	info.color = color
	if info.controlling_node is Player:
		info.controlling_node.set_display_settings(info.name, info.color)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(p_id: int) -> void:
	_set_player(p_id, null)
	var p_info = get_by_id(multiplayer.get_unique_id())
	notify_of_peer_settings.rpc(p_info.name, p_info.color)

func _on_peer_disconnected(p_id: int) -> void:
	var player = get_by_id(p_id)
	if player == null:
		return
	
	if player.controlling_node == null or player.controlling_node.is_queued_for_deletion():
		return
	
	player.controlling_node.queue_free()

func _set_player(p_id: int, controlling_node: Node3D) -> void:
	if get_by_id(p_id) == null:
		players[p_id] = Info.new(p_id)
	players[p_id].controlling_node = controlling_node
	player_controlling_node.emit(p_id)

func get_by_id(p_id: int) -> Info:
	return players.get(p_id)

func get_player_by_id(p_id: int) -> Player:
	var info = get_by_id(p_id)
	if info == null:
		return info
	
	if info.controlling_node == null or info.controlling_node.is_queued_for_deletion():
		return null
	
	return info.controlling_node

func get_players() -> Array[Player]:
	var player_array : Array[Player] = []
	for player in players.values():
		player_array.push_back(player.controlling_node)
	return player_array

## The name of the player
func register_player_name(p_id: int, p_name: String) -> void:
	var player = get_by_id(p_id)
	if player == null:
		_set_player(p_id, null)
	else:
		player.name = p_name

## The node the player is controlling
func register_player_node(p_id: int, p_node: Node3D) -> void:
	var player = get_by_id(p_id)
	if player == null:
		_set_player(p_id, p_node)
	else:
		player.controlling_node = p_node
		player_controlling_node.emit(p_id)

func store_local_player_settings(p_name: String, color: Color) -> void:
	var p_id = multiplayer.get_unique_id()
	if get_by_id(p_id) == null:
		players[p_id] = Info.new(p_id)
	players[p_id].name = p_name
	players[p_id].color = color
