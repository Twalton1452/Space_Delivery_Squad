@tool
extends Node3D

@export_category("Debug")
@export var spread: bool:
	set(value):
		print("Spreading ", get_child_count(), " child objects")
		_on_spread()

func _on_spread() -> void:
	var x = 1
	var column = 0
	var max_row_size = 10
	for child in get_children():
		child.position.x = x
		child.position.y = 0
		child.position.z = column
		x += 1
		if x % max_row_size == 0:
			column += 1
			x = 0
