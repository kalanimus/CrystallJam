extends RigidBody3D

@export var speaker := "Куб"
@export_multiline var dialogue_text := "Something is wroing with this cube!"


func interact(_player: CharacterBody3D) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue")
	if dialogue and dialogue.has_method("show_text"):
		dialogue.show_text(dialogue_text, speaker)
