extends Node

## Autoloaded

@onready var music_player : AudioStreamPlayer = $Music

enum AudioFallOff {
	SHORT,
	MEDIUM,
	LONG
}

var mic_capture: VOIPInputCapture
var muted = false

var users = {} # {Peer ID: AudioStreamPlayer3D}
var debug_disable_voip = true # Auto-disabled when exported

func _unhandled_input(event):
	if event.is_action_pressed("ui_end"):
		muted = !muted
		print("Muted: ", muted)

func _ready():
	_voip_setup()
	
	# Unmute by default when exported
	# Adjust based on player settings
	if OS.has_feature("standalone"):
		for i in AudioServer.bus_count:
			# Don't enable the player to hear themselves
			if AudioServer.get_bus_name(i) != "Mic":
				AudioServer.set_bus_mute(i, false)

func _process(_delta):
	mic_capture.send_test_packets()

#region VOIP
func _voip_setup() -> void:
	if debug_disable_voip and not OS.has_feature("standalone"):
		set_process(false)
		return
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	PlayerManager.player_controlling_node.connect(_on_player_controlling_node)
	
	var mic_bus_id = AudioServer.get_bus_index("Mic")
	mic_capture = AudioServer.get_bus_effect(mic_bus_id, 0) # AudioBus has VOIPInputCapture we're listening to
	mic_capture.packet_ready.connect(_on_packet_ready)

func _on_peer_connected(peer_id: int) -> void:
	if users.get(peer_id) != null:
		return
	
	# Create an AudioBus for the peer so we can add effects to it later
	var peer_audio_bus_id = AudioServer.bus_count
	AudioServer.add_bus(peer_audio_bus_id)
	AudioServer.set_bus_name(peer_audio_bus_id, str(peer_id))
	
	var peer_audio_player = AudioStreamPlayer3D.new()
	peer_audio_player.unit_size = 1.5 # distance
	peer_audio_player.bus = str(peer_id)
	peer_audio_player.name = str(peer_id)
	peer_audio_player.autoplay = true
	peer_audio_player.stream = AudioStreamVOIP.new()
	#add_child(peer_audio_player)
	users[peer_id] = peer_audio_player

func _on_peer_disconnected(peer_id: int) -> void:
	if users[peer_id] == null or users[peer_id].is_queued_for_deletion():
		return
	users[peer_id].queue_free()
	users.erase(peer_id)

func _on_player_controlling_node(peer_id: int) -> void:
	var player_info = PlayerManager.get_by_id(peer_id)
	if player_info == null or player_info.controlling_node == null:
		return
	
	_on_peer_connected(peer_id)
	player_info.controlling_node.add_child(users[peer_id])

# Data is ready to send over the network!
func _on_packet_ready(data) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and not muted:
		_send_voip_packet.rpc(data)

@rpc("any_peer", "call_remote", "unreliable", 2)
func _send_voip_packet(data) -> void:
	(users[multiplayer.get_remote_sender_id()].stream as AudioStreamVOIP).push_packet(data)
#endregion VOIP

func change_to(music_clip: AudioStream) -> void:
	music_player.stream = music_clip
	music_player.play()

func play_one_shot_global(sfx: AudioStream) -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	sfx_player.stream = sfx
	add_child(sfx_player)
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()

func play_one_shot_3d(to_parent: Node3D, sfx: AudioStream, volume_db: float = 0.0, falloff: AudioFallOff = AudioFallOff.MEDIUM) -> void:
	var sfx_player = AudioStreamPlayer3D.new()
	sfx_player.bus = "SFX"
	sfx_player.stream = sfx
	sfx_player.volume_db = volume_db
	sfx_player.area_mask = Constants.PLAYER_LAYER
	match falloff:
		AudioFallOff.SHORT:
			sfx_player.unit_size = 5.0
		AudioFallOff.MEDIUM:
			sfx_player.unit_size = 10.0
		AudioFallOff.LONG:
			sfx_player.unit_size = 15.0
	to_parent.add_child(sfx_player, true)
	sfx_player.position = Vector3.ZERO
	sfx_player.play()
	await sfx_player.finished
	sfx_player.queue_free()
