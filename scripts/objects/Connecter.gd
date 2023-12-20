extends StaticBody3D
class_name Connecter

signal disconnecting(this_connecter: Connecter)

var rays : Array[RayCast3D]
var neighbors : Array[Connecter]
var max_fluid_capacity = 0.1
var fluid_reserves = 0.0

var debug_label : Label3D

func _ready() -> void:
	add_to_group(Constants.CONNECTER_GROUP)
	for child in get_children():
		if child is RayCast3D:
			rays.push_back(child)
		if child is Interactable:
			child.interacted.connect(_on_picked_up)
	
	neighbors.resize(rays.size())
	debug_label = Label3D.new()
	add_child(debug_label)
	debug_label.text = "0.0"
	debug_label.position += Vector3(0.0, 0.5, 0.0)
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
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
		
		if ray.get_collider() != null:
			if ray.get_collider() is Connecter and not ray.get_collider() in neighbors:
				neighbors[i] = ray.get_collider()
				#print(name, " connected to ", ray.get_collider().name)
			elif ray.get_collider() is ConnecterSystem:
				ray.get_collider().connect_to(self)
		
		ray.enabled = false

func disconnect_neighbor(connecter: Connecter) -> void:
	neighbors.erase(connecter)

func disconnect_from_neighbors() -> void:
	disconnecting.emit(self)
	for neighbor in neighbors:
		if neighbor != null:
			neighbor.disconnect_neighbor(self)

func _on_placed() -> void:
	discover_neighbors()
	collision_layer = Constants.CONNECTER_LAYER

func _on_picked_up(_interactable: Interactable, _interacter: Player) -> void:
	disconnect_from_neighbors()
	collision_layer = 0

## Holds the maximum amount of fluid and discards the rest
## returns whether it was able to deliver the fluid
func carry(fluid: float, from: Connecter) -> bool:
	if fluid + fluid_reserves > max_fluid_capacity:
		return false
	
	fluid_reserves += fluid
	fluid_reserves = clampf(fluid_reserves, 0.0, max_fluid_capacity)
	
	var fluid_delivered = flow(from)
	while fluid_delivered > 0.0:
		fluid_delivered = flow(from)
	
	debug_label.text = str(fluid_reserves)
	return true

## A single flow of the reserves in the Connecter
## returns the amount delivered in a flow
func flow(from: Connecter) -> float:
	# Reached the end of a ConnecterSystem
	# If there is only one neighbor then it flowed from there
	if neighbors.size() - 1 == 0:
		return 0.0
	
	var fluid_output_per_neighbor = snappedf(fluid_reserves / (neighbors.size() - 1), 0.001)
	var fluid_delivered = 0.0
	
	if fluid_output_per_neighbor == 0.0:
		return 0.0
	
	for neighbor in neighbors:
		# No backflow
		if from == neighbor or neighbor == null:
			continue
		
		# Check if neighbor has the capacity before subtracting from ours
		if neighbor.carry(fluid_output_per_neighbor, self):
			fluid_delivered += fluid_output_per_neighbor
			fluid_reserves -= fluid_output_per_neighbor
			fluid_reserves = clampf(fluid_reserves, 0.0, max_fluid_capacity)
	
	return fluid_delivered

## Probably not going to use
func emission(fluid: float) -> void:
	print("Reached the end. Emitting ", fluid, " fluid")
	fluid_reserves = 0.0
