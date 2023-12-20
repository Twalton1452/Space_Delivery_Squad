extends Node3D

@onready var canvas_layer = $CanvasLayer
@onready var viewing_position = $ViewingPosition
@onready var screen = $CanvasLayer/Screen

var connecter_sprite = preload("res://art/WhiteSquare.png")

func _ready() -> void:
	canvas_layer.hide()
	for child in get_children():
		if child is Interactable:
			child.interacted.connect(_on_interacted)

func _on_interacted(_interactable: Interactable, interacter: Player) -> void:
	if not interacter.is_multiplayer_authority():
		return
	interacter.global_position = viewing_position.global_position
	interacter.global_rotation = viewing_position.global_rotation
	enable()
	# Apply Effect and listen for Effect removal event then Disable

func enable() -> void:
	# Only generate once until we can disable
	if screen.get_child_count() > 0:
		return
	var adjustment = screen.size.x / screen.size.y
	canvas_layer.show()
	for connecter in get_tree().get_nodes_in_group(Constants.CONNECTER_GROUP):
		var tex_rect = TextureRect.new()
		tex_rect.texture = connecter_sprite
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Place the Dot
		var remapped_x = remap(connecter.global_position.x, -10, 10, screen.position.x, screen.position.x + screen.size.x)
		var remapped_z = remap(connecter.global_position.z, -10, 10, screen.position.y, screen.position.y + screen.size.y)
		tex_rect.position = Vector2(remapped_z, remapped_x / adjustment)
		
		# Customize the Dot
		if connecter is Connecter:
			tex_rect.size = Vector2(8, 8)
			if connecter.neighbors.size() == 0:
				tex_rect.self_modulate = Color.RED
		else:
			tex_rect.size =  Vector2(12, 12)
			tex_rect.self_modulate = Color.CHARTREUSE
		
		screen.add_child(tex_rect)

func disable() -> void:
	canvas_layer.hide()
	for child in screen.get_children():
		child.queue_free()
