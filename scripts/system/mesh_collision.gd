extends Node3D

## Generates a static trimesh collision body for every MeshInstance3D below
## this node. Attach to an imported model root to make it solid.


func _ready() -> void:
	for mesh_instance in find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh:
			mesh_instance.create_trimesh_collision()
