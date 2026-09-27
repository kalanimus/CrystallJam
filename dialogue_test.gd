extends Control

const MENU_SCENE := "res://mainmenu.tscn"

const LINES := [
	{"speaker": "Narrator", "text": "You wake in a room that looks like yours, yet something is [i]wrong[/i]."},
	{"speaker": "You", "text": "[b]Where am I?[/b] This doesn't make sense."},
	{"speaker": "???", "text": "You can run... but you can never escape [shake rate=20 level=8]yourself[/shake]."},
	{"speaker": "SAM", "text": "Hello. I am Software Automatic Mouth. I can speak any text you give me."},
	{"speaker": "Narrator", "text": "Rich text works too: [color=gold]gold[/color], [wave]wavy[/wave], and [rainbow]colors[/rainbow]."},
]

@onready var _lower_third: LowerThird = $LowerThird
@onready var _voice_toggle: CheckBox = $TopBar/VoiceToggle

var _finished: bool = false


func _on_static_body_3d_my_custom_signal() -> void:
	$TopBar/Back.pressed.connect(_on_back_pressed)
	$TopBar/Replay.pressed.connect(_on_replay_pressed)
	_voice_toggle.toggled.connect(_on_voice_toggled)
	_lower_third.queue_finished.connect(_on_queue_finished)
	_lower_third.voice_enabled = _voice_toggle.button_pressed
	_lower_third.queue_lines(LINES)



func _advance_or_replay() -> void:
	if _finished:
		_finished = false
		_lower_third.queue_lines(LINES)
	else:
		_lower_third.advance()


func _on_queue_finished() -> void:
	_finished = true
	_lower_third.show_line("[center]— end of demo —[/center]\nPress Space to replay.", "")


func _on_voice_toggled(pressed: bool) -> void:
	_lower_third.voice_enabled = pressed
	if not pressed:
		_lower_third.stop_voice()


func _on_replay_pressed() -> void:
	_finished = false
	_lower_third.voice_enabled = _voice_toggle.button_pressed
	_lower_third.queue_lines(LINES)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
	
	
	
