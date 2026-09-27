extends StaticBody3D

signal my_custom_signal();


func interact():
	my_custom_signal.emit();
	
