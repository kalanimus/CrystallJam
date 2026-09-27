extends RigidBody3D

@export var display_name: String = "объект"

func interact(_player: CharacterBody3D = null):
	print("Вы взаимодействовали с объектом: %s" % display_name)
