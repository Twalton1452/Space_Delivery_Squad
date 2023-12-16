@tool
extends Node3D

@export_category("Debug")
@export var x_spacing = 1
@export var z_spacing = 1
@export var row_size = 10
@export var spread: bool:
	set(value):
		print("Spreading ", get_child_count(), " child objects")
		_on_spread()

func _on_spread() -> void:
	var x = 1
	var column = 0
	for child in get_children():
		child.position.x = x * x_spacing
		child.position.y = 0
		child.position.z = column
		x += 1
		if x % row_size == 0:
			column += z_spacing
			x = 0
