extends Node
class_name VoiceOrchestrator

signal received_voice_data
signal sent_voice_data
signal created_instance
signal removed_instance

@export var recording: bool = false : set = _set_recording
@export var listen: bool = false : set = _set_listen
@export_range(0.0, 1.0) var input_threshold: = 0.005 : set = _set_input_threshold

var instances := {}
var _id = null

func _ready() -> void:
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.connection_failed.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)

func _physics_process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() && multiplayer.is_server() && _id == null:
		_create_instance(multiplayer.get_unique_id())

	if (!multiplayer.has_multiplayer_peer() || !multiplayer.is_server()) && _id == 1:
		_reset()

func _create_instance(id: int) -> void:
	var instance := VoiceInstance.new()

	if id == multiplayer.get_unique_id():
		instance.recording = recording
		instance.listen = listen
		instance.input_threshold = input_threshold

		instance.sent_voice_data.emit()

		_id = id

	instance.received_voice_data.emit()

	instance.name = str(id)

	instances[id] = instance

	add_child(instance)

	created_instance.emit(id)

func _remove_instance(id: int) -> void:
	var instance: VoiceInstance = instances[id]

	if id == _id:
		_id = null

	instance.queue_free()

	instances.erase(id)

	removed_instance.emit(id)

func _reset() -> void:
	for id in instances.keys():
		_remove_instance(id)

func _set_recording(value: bool) -> void:
	if _id != null:
		instances[_id].recording = value

	recording = value

func _set_listen(value: bool) -> void:
	if _id != null:
		instances[_id].listen = value

	listen = value

func _set_input_threshold(value: float) -> void:
	if _id != null:
		instances[_id].input_threshold = value

	input_threshold = value

func _connected_ok() -> void:
	if (!multiplayer.has_multiplayer_peer() || !multiplayer.is_server()) && _id == 1:
		_reset()

	_create_instance(multiplayer.get_unique_id())

func _server_disconnected() -> void:
	_reset()

func _player_connected(id) -> void:
	_create_instance(id)

func _player_disconnected(id) -> void:
	_remove_instance(id)

func _received_voice_data(data: PackedFloat32Array, id: int) -> void:
	received_voice_data.emit(data, id)

func _sent_voice_data(data: PackedFloat32Array) -> void:
	sent_voice_data.emit(data)
