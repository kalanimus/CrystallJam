extends Control


func _ready() -> void:
	add_to_group("ending")
	hide()
	$QuitButton.pressed.connect(_on_quit_pressed)
	$RestartButton.pressed.connect(_on_restart_pressed)
	_connect_timer.call_deferred()


func _connect_timer() -> void:
	var timer := get_tree().get_first_node_in_group("timer")
	if timer and timer.has_signal("finished"):
		timer.finished.connect(show_ending)


func show_ending() -> void:
	if visible:
		return
	modulate.a = 0.0
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)


func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.close()")
	get_tree().quit()


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
