class_name Helpers

static func ray_cast(from: Node3D, direction: Vector3, distance: float) -> Dictionary:
	var space_state = from.get_world_3d().direct_space_state
	var origin = from.global_position
	var end = origin + direction * distance
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	return space_state.intersect_ray(query)

static func ray_cast_bodies(from: Node3D, direction: Vector3, distance: float) -> Dictionary:
	var space_state = from.get_world_3d().direct_space_state
	var origin = from.global_position
	var end = origin + direction * distance
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return space_state.intersect_ray(query)

static func deg_to_rad_vec3(vec: Vector3) -> Vector3:
	return Vector3(deg_to_rad(vec.x), deg_to_rad(vec.y), deg_to_rad(vec.z))
