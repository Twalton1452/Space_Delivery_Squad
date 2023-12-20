extends StaticBody3D
class_name Connecter


var rays : Array[RayCast3D]
var neighbors : Array[Connecter]

func _ready() -> void:
	add_to_group(Constants.CONNECTER_GROUP)
	for child in get_children():
		if child is RayCast3D:
			rays.push_back(child)
		if child is Interactable:
			child.interacted.connect(_on_picked_up)
	
	neighbors.resize(rays.size())
	
	if placed():
		await get_tree().physics_frame
		discover_neighbors()

func placed() -> bool:
	return collision_layer & Constants.CONNECTER_LAYER == Constants.CONNECTER_LAYER

func discover_neighbors() -> void:
	for i in range(0, rays.size()):
		var ray = rays[i]
		ray.enabled = true
		ray.force_raycast_update()
		
		if ray.get_collider() != null and ray.get_collider() is Connecter and not ray.get_collider() in neighbors:
			neighbors[i] = ray.get_collider()
			print(name, " connected to ", ray.get_collider().name)
		
		ray.enabled = false

func disconnect_neighbor(connecter: Connecter) -> void:
	neighbors.erase(connecter)

func disconnect_from_neighbors() -> void:
	for neighbor in neighbors:
		disconnect_neighbor(self)

func _on_placed() -> void:
	discover_neighbors()
	collision_layer = Constants.CONNECTER_LAYER

func _on_picked_up(_interactable: Interactable, _interacter: Player) -> void:
	disconnect_from_neighbors()
	collision_layer = 0

func carry(fluid, from: Connecter) -> void:
	for neighbor in neighbors:
		# No backflow
		if from == neighbor or neighbor == null:
			continue
		neighbor.carry(fluid, self)
