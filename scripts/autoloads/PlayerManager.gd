extends Node

## Autoloaded

var players = {}

class Info:
	var id: int
	var name: String
	var controlling_node: Node3D
	
	func _init(p_id: int):
		id = p_id

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(p_id: int) -> void:
	_set_player(p_id, "", null)

func _on_peer_disconnected(p_id: int) -> void:
	var player = get_by_id(p_id)
	if player == null:
		return
	
	if player.controlling_node == null or player.controlling_node.is_queued_for_deletion():
		return
	
	player.controlling_node.queue_free()

func _set_player(p_id: int, p_name: String, controlling_node: Node3D) -> void:
	players[p_id] = Info.new(p_id)
	players[p_id].name = p_name
	players[p_id].controlling_node = controlling_node

func get_by_id(p_id: int) -> Info:
	return players.get(p_id)

func get_player_by_id(p_id: int) -> Player:
	var info = get_by_id(p_id)
	if info == null:
		return info
	return info.controlling_node

## The name of the player
func register_player_name(p_id: int, p_name: String) -> void:
	var player = get_by_id(p_id)
	if player == null:
		_set_player(p_id, p_name, null)
	else:
		player.name = p_name

## The node the player is controlling
func register_player_node(p_id: int, p_node: Node3D) -> void:
	var player = get_by_id(p_id)
	if player == null:
		_set_player(p_id, "", p_node)
	else:
		player.controlling_node = p_node
