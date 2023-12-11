extends Node

## Autoloaded

@onready var music_player : AudioStreamPlayer = $Music

var mic_capture: VOIPInputCapture

var users = {} # {Peer ID: AudioStreamPlayer}

func _ready():
	_voip_setup()
	
	# Unmute by default when exported
	# Adjust based on player settings
	if OS.has_feature("standalone"):
		for i in AudioServer.bus_count:
			# Don't enable the player to hear themselves
			if AudioServer.get_bus_name(i) != "Mic":
				AudioServer.set_bus_mute(i, false)

func _voip_setup() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var mic_bus_id = AudioServer.get_bus_index("Mic")
	mic_capture = AudioServer.get_bus_effect(mic_bus_id, 0) # AudioBus has VOIPInputCapture we're listening to
	mic_capture.packet_ready.connect(_on_packet_ready)
	
func _process(_delta):
	mic_capture.send_test_packets()

func _on_peer_connected(peer_id: int) -> void:
	# Create an AudioBus for the peer so we can add effects to it later
	var peer_audio_bus_id = AudioServer.bus_count
	AudioServer.add_bus(peer_audio_bus_id)
	AudioServer.set_bus_name(peer_audio_bus_id, str(peer_id))
	
	var peer_audio_player = AudioStreamPlayer.new()
	peer_audio_player.bus = str(peer_id)
	peer_audio_player.name = str(peer_id)
	peer_audio_player.autoplay = true
	peer_audio_player.stream = AudioStreamVOIP.new()
	add_child(peer_audio_player)
	users[peer_id] = peer_audio_player

func _on_peer_disconnected(peer_id: int) -> void:
	if users[peer_id] == null or users[peer_id].is_queued_for_deletion():
		return
	users[peer_id].queue_free()
	users.erase(peer_id)

# Data is ready to send over the network!
func _on_packet_ready(data) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_send_voip_packet.rpc(data)

@rpc("any_peer", "call_remote", "unreliable")
func _send_voip_packet(data) -> void:
	(users[multiplayer.get_remote_sender_id()].stream as AudioStreamVOIP).push_packet(data)

func change_to(music_clip: AudioStream) -> void:
	music_player.stream = music_clip
	music_player.play()

func play_one_shot(sfx: AudioStream) -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	sfx_player.stream = sfx
	add_child(sfx_player)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()
