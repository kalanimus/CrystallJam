extends StaticBody3D

@export var prompt := "Listen"


func interact(player: Node) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue")
	if not dialogue or not dialogue.has_method("start_demo"):
		return

	if player and player.has_method("lock_movement"):
		player.lock_movement()
		if not dialogue.dialogue_finished.is_connected(player.unlock_movement):
			dialogue.dialogue_finished.connect(player.unlock_movement)

	dialogue.start_demo()
