extends Node3D

const Stencilizer = preload("res://addons/spatialize/stencilizer.gd")

@onready var portal_mesh: MeshInstance3D = %PortalMesh
@onready var game_parent: Node3D = %GameParent

var stencilizer := Stencilizer.new()


func _ready() -> void:
  stencilizer.setup_portal_material(portal_mesh)
  stencilizer.setup_object_materials(game_parent)
