extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var main_menu_audio_player = $CanvasLayer/MainMenu/AudioStreamPlayer
@onready var address_entry = $CanvasLayer/MainMenu/PanelContainer/MarginContainer/VBoxContainer/IPAddressEntry
@onready var player_view_body_mesh = $CanvasLayer/MainMenu/PlayerView/SubViewport/bean_armature/Armature/Skeleton3D/Body
@onready var player_name_edit = $CanvasLayer/MainMenu/PlayerCustomization/VBoxContainer/LineEdit

const PORT = 9998

func _ready():
	$CanvasLayer/MainMenu/PanelContainer/MarginContainer/VBoxContainer/HostButton.grab_focus()
	for child in $CanvasLayer/MainMenu/PlayerCustomization/VBoxContainer/HBoxContainer.get_children():
		(child as TextureButton).pressed.connect(_on_color_button_pressed)
	LevelManager.prepare_first_level_async.call_deferred()

func _on_color_button_pressed() -> void:
	# gnarly
	for child in $CanvasLayer/MainMenu/PlayerCustomization/VBoxContainer/HBoxContainer.get_children():
		if (child as TextureButton).button_pressed:
			(player_view_body_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color = (child as TextureButton).self_modulate

func _unhandled_input(event):
	if event.is_action_pressed("options"):
		# show menu instead
		_on_quit_button_pressed()

func _on_host_button_pressed():
	var enet_peer = ENetMultiplayerPeer.new()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	if OS.has_feature("standalone"):
		upnp_setup()
	
	TickHandler.enable()
	host_or_join()

func _valid_ip_address() -> bool:
	if OS.has_feature("standalone"):
		return address_entry.text.length() > 0
	return true

func _valid_server() -> bool:
	# TODO: Check if the ipaddress entered has a server running
	return true

func _on_join_button_pressed():
	if not _valid_ip_address() or not _valid_server():
		return
	
	var enet_peer = ENetMultiplayerPeer.new()
	
	if OS.has_feature("standalone"):
		enet_peer.create_client(address_entry.text, PORT)
		# TODO: Check the status of the connection and reload the scene if it takes too long
	else:
		enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.server_disconnected.connect(server_disconnect)
	host_or_join()

func server_disconnect():
	get_tree().quit()

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

func cleanup_main_menu() -> void:
	pass

func host_or_join():
	main_menu_audio_player.play()
	main_menu.hide()
	cleanup_main_menu()
	var player_color = (player_view_body_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color
	var player_name = player_name_edit.text
	PlayerManager.store_local_player_settings(player_name, player_color)
	
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		LevelManager.go_to_first_level()
	else:
		Transition.fade_out()

func _on_quit_button_pressed():
	get_tree().quit.call_deferred()

