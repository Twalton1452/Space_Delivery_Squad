class_name Helpers

static func ray_cast(from: Node3D, direction: Vector3, distance: float) -> Dictionary:
	var space_state = from.get_world_3d().direct_space_state
	var origin = from.global_position
	var end = origin + direction * distance
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	return space_state.intersect_ray(query)
