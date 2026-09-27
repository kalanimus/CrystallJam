extends Control

const MENU_SCENE := "res://mainmenu.tscn"

const LINES := [
	{"speaker": "Narrator", "text": "You wake in a room that looks like yours, yet something is [i]wrong[/i]."},
	{"speaker": "You", "text": "[b]Where am I?[/b] This doesn't make sense."},
	{"speaker": "???", "text": "You can run... but you can never escape [shake rate=20 level=8]yourself[/shake]."},
	{"speaker": "SAM", "text": "Hello. I am Software Automatic Mouth. I can speak any text you give me."},
	{"speaker": "Narrator", "text": "Rich text works too: [color=gold]gold[/color], [wave]wavy[/wave], and [rainbow]colors[/rainbow]."},
]

const END_LINE := {"speaker": "", "text": "[center]— end of demo —[/center]"}

signal dialogue_started
signal dialogue_finished

@onready var _lower_third: LowerThird = $LowerThird
@onready var _voice_toggle: CheckBox = $TopBar/VoiceToggle

var _engaged: bool = false
var _finished: bool = false
var _connected: bool = false


func _ready() -> void:
	hide()


func _on_interactive_cube_my_custom_signal() -> void:
	if not _connected:
		_connected = true
		$TopBar/Back.pressed.connect(_on_back_pressed)
		$TopBar/Replay.pressed.connect(_on_replay_pressed)
		_voice_toggle.toggled.connect(_on_voice_toggled)
		_lower_third.queue_finished.connect(_on_queue_finished)
	_lower_third.voice_enabled = _voice_toggle.button_pressed
	_start_dialogue()


func _start_dialogue() -> void:
	_engaged = true
	_finished = false
	show()
	dialogue_started.emit()
	_lower_third.queue_lines(LINES + [END_LINE])


func _advance_dialogue() -> void:
	_lower_third.advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _engaged or _finished:
		return
	var advance := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if advance:
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func _on_queue_finished() -> void:
	_finished = true
	dialogue_finished.emit()
	hide()


func _on_voice_toggled(pressed: bool) -> void:
	_lower_third.voice_enabled = pressed
	if not pressed:
		_lower_third.stop_voice()


func _on_replay_pressed() -> void:
	_lower_third.voice_enabled = _voice_toggle.button_pressed
	_start_dialogue()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
