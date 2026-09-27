extends Control

const GAME_SCENE := "res://node_3d.tscn"
const VOICE_TEST_SCENE := "res://gdsam_test.tscn"
const DIALOGUE_TEST_SCENE := "res://dialogue_test.tscn"


func _ready() -> void:
	$CenterContainer/Menu/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/Menu/OptionsButton.pressed.connect(_on_options_pressed)
	$CenterContainer/Menu/VoiceTestButton.pressed.connect(_on_voice_test_pressed)
	$CenterContainer/Menu/DialogueTestButton.pressed.connect(_on_dialogue_test_pressed)
	$CenterContainer/Menu/ExitButton.pressed.connect(_on_exit_pressed)
	$CenterContainer/Menu/StartButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_exit_pressed()
		get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	if ResourceLoader.exists(GAME_SCENE):
		get_tree().change_scene_to_file(GAME_SCENE)
	else:
		push_warning("Start pressed, but '%s' does not exist yet." % GAME_SCENE)


func _on_options_pressed() -> void:
	print("Options pressed (not implemented yet).")


func _on_voice_test_pressed() -> void:
	get_tree().change_scene_to_file(VOICE_TEST_SCENE)


func _on_dialogue_test_pressed() -> void:
	get_tree().change_scene_to_file(DIALOGUE_TEST_SCENE)


func _on_exit_pressed() -> void:
	get_tree().quit()
