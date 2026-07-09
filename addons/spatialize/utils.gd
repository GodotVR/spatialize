extends RefCounted


static func get_relative_transform(p_node: Node3D, p_relative_to: Node3D) -> Transform3D:
	var node_global_transform := p_node.global_transform
	var relative_to_global_transform := p_relative_to.global_transform
	return relative_to_global_transform.affine_inverse() * node_global_transform


static func set_relative_transform(p_node: Node3D, p_relative_to: Node3D, p_transform: Transform3D) -> void:
	var relative_to_global_transform := p_relative_to.global_transform
	var new_global_transform := relative_to_global_transform * p_transform
	p_node.global_transform = new_global_transform


static func get_relative_position(p_node: Node3D, p_relative_to: Node3D) -> Vector3:
	return get_relative_transform(p_node, p_relative_to).origin


static func set_relative_position(p_node: Node3D, p_relative_to: Node3D, p_position: Vector3) -> void:
	set_relative_transform(p_node, p_relative_to, Transform3D(Basis(), p_position))
