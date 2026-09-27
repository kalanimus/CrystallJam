extends "res://scripts/interactions/movable.gd"

@export var start_hours := 10

@onready var _display: Label3D = $Display

var _remaining_seconds: float
var _dialogue_active := false


func _ready() -> void:
	_remaining_seconds = float(start_hours * 60 * 60)
	_update_display()
	_connect_dialogue.call_deferred()


func _connect_dialogue() -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue")
	if dialogue == null:
		return
	if dialogue.has_signal("dialogue_started"):
		dialogue.dialogue_started.connect(_on_dialogue_started)
	if dialogue.has_signal("dialogue_finished"):
		dialogue.dialogue_finished.connect(_on_dialogue_finished)


func _on_dialogue_started() -> void:
	_dialogue_active = true


func _on_dialogue_finished() -> void:
	_dialogue_active = false


func _process(delta: float) -> void:
	if not _dialogue_active:
		return
	_remaining_seconds = maxf(0.0, _remaining_seconds - delta)
	_update_display()


func _update_display() -> void:
	var total_seconds := ceili(_remaining_seconds)
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60
	_display.text = "%02d:%02d:%02d" % [hours, minutes, seconds]
