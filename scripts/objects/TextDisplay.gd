extends Node3D
class_name TextDisplay

## A Text Display for players to Edit and customize their ship as they see fit

@onready var interactable : Interactable = $Interactable
@onready var label : Label3D = $Label3D

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	interactable.interact_display_text = label.text

func _on_interacted(_interactable: Interactable, interacter: Player) -> void:
	interacter.turn_flags_on(Player.Flags.BUSY)
	
	# Clientside interaction here
	if not interacter.is_multiplayer_authority():
		return
	
	var line_edit : LineEdit = load("res://scenes/ui/player_line_edit.tscn").instantiate()
	line_edit.text = label.text
	line_edit.caret_column = line_edit.text.length()
	interacter.hud.add_child(line_edit)
	line_edit.grab_focus()
	(interacter.hud.get_node("Label") as Label).text = "Editing Text"
	
	await interacter.no_longer_busy
	if label.text != line_edit.text:
		label.text = line_edit.text
		interactable.interact_display_text = label.text
		# Using MultiplayerSynchronizer to distribute the new label
		if not multiplayer.is_server():
			notify_server_text_changed.rpc_id(1, label.text)
	
	(interacter.hud.get_node("Label") as Label).text = label.text
	line_edit.queue_free()

@rpc("any_peer", "call_remote", "unreliable")
func notify_server_text_changed(new_label: String) -> void:
	label.text = new_label
	interactable.interact_display_text = label.text
