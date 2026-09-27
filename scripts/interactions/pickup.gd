extends RigidBody3D

@export var item_name := "Сфера"
@export_multiline var use_text := "This is a sphere"


func interact(_player: CharacterBody3D) -> void:
	var inventory := get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.add_item(self):
		print("Предмет добавлен в инвентарь: %s" % item_name)


func store_in_inventory(inventory: Node) -> void:
	freeze = true
	visible = false
	collision_layer = 0
	collision_mask = 0
	reparent(inventory, false)


func use_from_inventory() -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue")
	if dialogue and dialogue.has_method("show_text"):
		dialogue.show_text(use_text, item_name)
	else:
		print("Использован предмет: %s" % item_name)


func drop_from_inventory(world: Node, drop_position: Vector3, direction: Vector3) -> void:
	reparent(world)
	global_position = drop_position
	visible = true
	collision_layer = 1
	collision_mask = 1
	freeze = false
	linear_velocity = direction * 3.0 + Vector3.UP * 1.5
