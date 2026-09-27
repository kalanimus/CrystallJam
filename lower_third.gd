class_name LowerThird
extends Control

## JRPG-style lower-third dialogue box with a typewriter reveal, BBCode rich text
## support, and optional SAM text-to-speech voicing.

signal reveal_started
signal reveal_finished
signal line_finished(speaker: String, text: String)
signal queue_finished

@export_multiline var initial_text: String = ""
@export var initial_speaker: String = ""
@export var characters_per_second: float = 45.0
@export var auto_hide_when_done: bool = false
@export var voice_enabled: bool = false
@export_enum("SAM", "Elf", "Alien", "Stuffy", "Old Lady") var voice_preset: int = 0:
	set(value):
		voice_preset = value
		if is_node_ready():
			_apply_voice_preset()

@onready var _speaker_label: Label = %SpeakerLabel
@onready var _text: RichTextLabel = %Text
@onready var _gdsam = %GDSAM
@onready var _player: AudioStreamPlayer = %AudioStreamPlayer

var _queue: Array = []
var _revealing: bool = false
var _reveal_progress: float = 0.0
var _reveal_target: int = 0
var _current_speaker: String = ""


func _ready() -> void:
	set_process(false)
	_gdsam.set_audio_stream_callback(_stream_from_buffer)
	_apply_voice_preset()
	if not initial_text.is_empty():
		show_line(initial_text, initial_speaker)


func _process(delta: float) -> void:
	if not _revealing:
		return
	_reveal_progress += characters_per_second * delta
	var shown := int(_reveal_progress)
	if shown < _reveal_target:
		_text.visible_characters = shown
		return
	_complete_reveal()


# Shows a single line immediately, replacing anything currently displayed and
# cancelling any queued lines.
func show_line(text: String, speaker: String = "") -> void:
	_queue.clear()
	_display(text, speaker)


# Queues a batch of lines. Each entry is a Dictionary with "text" and optionally "speaker".
func queue_lines(lines: Array) -> void:
	_queue = lines.duplicate()
	_show_next()


# Appends a single queued line.
func queue_line(text: String, speaker: String = "") -> void:
	_queue.append({"text": text, "speaker": speaker})
	if not _revealing:
		_show_next()


# Advances: completes the reveal if it is in progress, otherwise shows the next
# queued line (or emits queue_finished when empty).
func advance() -> void:
	if _revealing:
		_complete_reveal()
	elif not _queue.is_empty():
		_show_next()
	else:
		queue_finished.emit()


func is_revealing() -> bool:
	return _revealing


func is_speaking() -> bool:
	return _gdsam.is_playing()


func stop_voice() -> void:
	_gdsam.interrupt()


func _display(text: String, speaker: String) -> void:
	_current_speaker = speaker
	_speaker_label.text = speaker
	_speaker_label.visible = not speaker.is_empty()
	_text.text = text
	_text.visible_characters = 0
	_reveal_target = _text.get_total_character_count()
	_reveal_progress = 0.0
	_revealing = true
	show()
	set_process(true)
	reveal_started.emit()
	if voice_enabled:
		_speak(text)


func _show_next() -> void:
	if _queue.is_empty():
		queue_finished.emit()
		return
	var line: Dictionary = _queue.pop_front()
	_display(line.get("text", ""), line.get("speaker", ""))


func _complete_reveal() -> void:
	_revealing = false
	set_process(false)
	_text.visible_characters = -1
	reveal_finished.emit()
	line_finished.emit(_current_speaker, _text.get_parsed_text())
	if auto_hide_when_done and _queue.is_empty():
		hide()


func _speak(text: String) -> void:
	var phrase := _text.get_parsed_text().strip_edges()
	if phrase.is_empty():
		phrase = text.strip_edges()
	if phrase.is_empty():
		return
	_gdsam.interrupt()
	_gdsam.speak(_player, phrase)


func _apply_voice_preset() -> void:
	match voice_preset:
		1:
			_gdsam.set_voice_elf()
		2:
			_gdsam.set_voice_alien()
		3:
			_gdsam.set_voice_stuffy()
		4:
			_gdsam.set_voice_old_lady()
		_:
			_gdsam.set_voice_default()


func _stream_from_buffer(buffer: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.data = buffer
	return stream
