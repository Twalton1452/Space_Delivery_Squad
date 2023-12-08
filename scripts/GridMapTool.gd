@tool
extends GridMap

@export_category("Debug")
@export var erase: bool:
	set(value):
		_on_erase()

func _on_erase() -> void:
	return
	#print("Erasing GridMap Cells")
	#clear()
