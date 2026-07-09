extends RefCounted

## Utility for using stencils (requires Godot 4.5+) to restrict rendering to a portal.

var _value: int
var _materials: Dictionary[StandardMaterial3D, StandardMaterial3D] = {}
var _materials_inverse: Dictionary[StandardMaterial3D, StandardMaterial3D] = {}


## Pass in the stencil reference value you would like to use for your portal.
func _init(p_value: int = 1) -> void:
	_value = p_value


## Modifies StandardMaterial3D's on the given node and all descendants so it only appears in the portal.
##
## If you're using a custom ShaderMaterial, it'll need to be modified manually.
func setup_object_materials(p_parent: Node3D) -> void:
	if p_parent is MeshInstance3D:
		_update_mesh_instance(p_parent)
	for child in p_parent.find_children("*", "MeshInstance3D", true, false):
		_update_mesh_instance(child)

	if p_parent is GPUParticles3D:
		_update_gpu_particles(p_parent)
	for child in p_parent.find_children("*", "GPUParticles3D", true, false):
		_update_gpu_particles(child)


## Restores the given node and all descendants to their original StandardMaterial3D materials.
##
## This is the reverse of `setup_object_materials()`.
func restore_object_materials(p_parent: Node3D) -> void:
	if p_parent is MeshInstance3D:
		_restore_mesh_instance(p_parent)
	for child in p_parent.find_children("*", "MeshInstance3D", true, false):
		_restore_mesh_instance(child)

	if p_parent is GPUParticles3D:
		_restore_gpu_particles(p_parent)
	for child in p_parent.find_children("*", "GPUParticles3D", true, false):
		_restore_gpu_particles(child)


## Modifies the StandardMaterial3D of the given node to act as a portal.
##
## Can work on both flat (`QuadMesh`) or cube-shaped (`BoxMesh`) portals.
func setup_portal_material(p_portal: MeshInstance3D) -> void:
	var mat := p_portal.get_active_material(0)
	if not mat:
		mat = StandardMaterial3D.new()

	if mat and mat is StandardMaterial3D:
		var new_mat: StandardMaterial3D = mat.duplicate()
		new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		new_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.0)
		new_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		new_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		new_mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
		new_mat.stencil_flags = BaseMaterial3D.STENCIL_FLAG_WRITE
		new_mat.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_ALWAYS
		new_mat.stencil_reference = _value
		new_mat.render_priority = -50
		p_portal.set_surface_override_material(0, new_mat)


func _update_mesh_instance(p_mesh: MeshInstance3D) -> void:
	var surface_count := p_mesh.mesh.get_surface_count()
	for i in range(surface_count):
		_update_mesh_instance_material(p_mesh, i)


func _update_mesh_instance_material(p_mesh: MeshInstance3D, i: int) -> void:
	var mat := p_mesh.get_active_material(i)
	if not mat:
		return
	if _materials_inverse.has(mat):
		return

	if mat and mat is StandardMaterial3D:
		p_mesh.set_surface_override_material(i, _get_stencilized_material(mat))


func _update_gpu_particles(p_gpu_particles: GPUParticles3D) -> void:
	var meshes := [
		p_gpu_particles.draw_pass_1,
		p_gpu_particles.draw_pass_2,
		p_gpu_particles.draw_pass_3,
		p_gpu_particles.draw_pass_4,
	]
	for mesh in meshes:
		if not mesh:
			continue
		for i in range(mesh.get_surface_count()):
			var mat: Material = mesh.surface_get_material(i)
			if mat and mat is StandardMaterial3D:
				mesh.surface_set_material(i, _get_stencilized_material(mat))


func _get_stencilized_material(p_material: StandardMaterial3D) -> StandardMaterial3D:
	if _materials.has(p_material):
		return _materials[p_material]

	var new_mat: StandardMaterial3D = p_material.duplicate()
	new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	new_mat.cull_mode = BaseMaterial3D.CULL_BACK
	new_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	new_mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
	new_mat.stencil_flags = BaseMaterial3D.STENCIL_FLAG_READ
	new_mat.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_EQUAL
	new_mat.stencil_reference = _value

	_materials[p_material] = new_mat
	_materials_inverse[new_mat] = p_material

	return new_mat


func _restore_mesh_instance(p_mesh: MeshInstance3D) -> void:
	var surface_count := p_mesh.mesh.get_surface_count()
	for i in range(surface_count):
		var mat := p_mesh.get_surface_override_material(i)
		if mat and _materials_inverse.has(mat):
			p_mesh.set_surface_override_material(i, _materials_inverse[mat as StandardMaterial3D])


func _restore_gpu_particles(p_gpu_particles: GPUParticles3D) -> void:
	var meshes := [
		p_gpu_particles.draw_pass_1,
		p_gpu_particles.draw_pass_2,
		p_gpu_particles.draw_pass_3,
		p_gpu_particles.draw_pass_4,
	]
	for mesh in meshes:
		if not mesh:
			continue
		for i in range(mesh.get_surface_count()):
			var mat: Material = mesh.surface_get_material(i)
			if mat and _materials_inverse.has(mat):
				mesh.surface_set_material(i, _materials_inverse[mat as StandardMaterial3D])
