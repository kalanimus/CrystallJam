extends RigidBody3D

@export var display_name: String = "объект"

signal my_custom_signal();

func interact():
	print("Вы взаимодействовали с объектом: %s" % display_name)
	my_custom_signal.emit();
