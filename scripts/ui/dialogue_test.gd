extends Control

const MENU_SCENE := "res://mainmenu.tscn"

const LINES := [
	{"speaker": "Narrator", "text": "You wake in a room that looks like yours, yet something is [i]wrong[/i]."},
	{"speaker": "You", "text": "[b]Where am I?[/b] This doesn't make sense."},
	{"speaker": "???", "text": "You can run... but you can never escape [shake rate=20 level=8]yourself[/shake]."},
]

signal dialogue_started
signal dialogue_finished

@onready var _lower_third: LowerThird = $LowerThird
@onready var _voice_toggle: CheckBox = $TopBar/VoiceToggle

var _engaged := false
var _finished := false


func _ready() -> void:
	add_to_group("dialogue")
	$TopBar.hide()
	hide()
	$TopBar/Back.pressed.connect(_on_back_pressed)
	$TopBar/Replay.pressed.connect(_on_replay_pressed)
	_voice_toggle.toggled.connect(_on_voice_toggled)
	_lower_third.queue_finished.connect(_on_queue_finished)
	_lower_third.voice_enabled = _voice_toggle.button_pressed


func show_text(text: String, speaker: String = "") -> void:
	_engaged = true
	_finished = false
	show()
	dialogue_started.emit()
	_lower_third.voice_enabled = _voice_toggle.button_pressed
	_lower_third.show_line(text, speaker)


func start_demo() -> void:
	_engaged = true
	_finished = false
	show()
	dialogue_started.emit()
	_lower_third.queue_lines(LINES)


func _unhandled_input(event: InputEvent) -> void:
	if not _engaged or _finished:
		return
	var advance := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if advance:
		_lower_third.advance()
		get_viewport().set_input_as_handled()


func _on_queue_finished() -> void:
	if not _engaged:
		return
	_engaged = false
	_finished = true
	dialogue_finished.emit()
	hide()


func _on_voice_toggled(pressed: bool) -> void:
	_lower_third.voice_enabled = pressed
	if not pressed:
		_lower_third.stop_voice()


func _on_replay_pressed() -> void:
	start_demo()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
