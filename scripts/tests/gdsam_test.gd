extends Control

const MENU_SCENE := "res://mainmenu.tscn"

@onready var gdsam = $GDSAM
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
@onready var speed: HSlider = %Speed
@onready var pitch: HSlider = %Pitch
@onready var mouth: HSlider = %Mouth
@onready var throat: HSlider = %Throat
@onready var singing: CheckBox = %Singing
@onready var phonetic: CheckBox = %Phonetic
@onready var voice: OptionButton = %Voice
@onready var input: LineEdit = %Input
@onready var status: Label = %Status


func _ready() -> void:
	gdsam.set_audio_stream_callback(_stream_from_buffer)
	gdsam.synthesis_failed.connect(_on_synthesis_failed)
	gdsam.started_phrase.connect(_on_started_phrase)

	%Speak.pressed.connect(_on_speak_pressed)
	%Interrupt.pressed.connect(gdsam.interrupt)
	%Back.pressed.connect(_on_back_pressed)

	speed.value_changed.connect(func(_v: float) -> void: _on_slider_changed())
	pitch.value_changed.connect(func(_v: float) -> void: _on_slider_changed())
	mouth.value_changed.connect(func(_v: float) -> void: _on_slider_changed())
	throat.value_changed.connect(func(_v: float) -> void: _on_slider_changed())
	singing.toggled.connect(func(v: bool) -> void: gdsam.singing = v)
	phonetic.toggled.connect(func(v: bool) -> void: gdsam.phonetic = v)
	voice.item_selected.connect(func(_i: int) -> void: _apply_voice())
	input.text_submitted.connect(func(_t: String) -> void: _on_speak_pressed())

	_apply_voice()
	input.grab_focus()


func _stream_from_buffer(buffer: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.data = buffer
	return stream


func _apply_voice() -> void:
	match voice.get_selected_id():
		1:
			gdsam.set_voice_elf()
		2:
			gdsam.set_voice_alien()
		3:
			gdsam.set_voice_stuffy()
		4:
			gdsam.set_voice_old_lady()
		_:
			gdsam.set_voice_default()
	_sync_sliders()
	_update_labels()


func _sync_sliders() -> void:
	speed.set_value_no_signal(gdsam.speed)
	pitch.set_value_no_signal(gdsam.pitch)
	mouth.set_value_no_signal(gdsam.mouth)
	throat.set_value_no_signal(gdsam.throat)


func _on_slider_changed() -> void:
	gdsam.speed = int(speed.value)
	gdsam.pitch = int(pitch.value)
	gdsam.mouth = int(mouth.value)
	gdsam.throat = int(throat.value)
	_update_labels()


func _update_labels() -> void:
	%SpeedLabel.text = "Speed (%d)" % gdsam.speed
	%PitchLabel.text = "Pitch (%d)" % gdsam.pitch
	%MouthLabel.text = "Mouth (%d)" % gdsam.mouth
	%ThroatLabel.text = "Throat (%d)" % gdsam.throat


func _on_speak_pressed() -> void:
	if input.text.strip_edges().is_empty():
		status.text = "Type something to speak."
		return
	status.text = "Speaking: %s" % input.text
	gdsam.speak(player, input.text)


func _on_started_phrase(phrase: String) -> void:
	status.text = "Speaking: %s" % phrase


func _on_synthesis_failed(phrase: String, message: String) -> void:
	status.text = "Failed on '%s': %s" % [phrase, message]


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
