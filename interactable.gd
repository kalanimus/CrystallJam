extends RigidBody3D

@export var display_name: String = "объект"

func interact():
	print("Вы взаимодействовали с объектом: %s" % display_name)
