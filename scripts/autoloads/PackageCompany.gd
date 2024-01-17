extends Node

## TODO: Autoloaded

var package_requests : Array[Package] = []
var package_scene : PackedScene = preload("res://scenes/components/Package.tscn")

func _ready():
	await LevelManager.changed_level
	setup()

func setup() -> void:
	pass

func receive_package_request_from(resident: Universe.Resident) -> void:
	var new_package : Package = package_scene.instantiate()
	new_package.assign_to(resident)
	var time_to_deliver = randi_range(5, 10)
	new_package.time_left_to_deliver = time_to_deliver
	package_requests.push_back(new_package)
