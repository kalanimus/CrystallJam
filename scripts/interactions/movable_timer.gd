extends "res://scripts/interactions/movable.gd"

@export var start_hours := 10

@onready var _display: Label3D = $Display

var _remaining_seconds: float


func _ready() -> void:
	_remaining_seconds = float(start_hours * 60 * 60)
	_update_display()


func _process(delta: float) -> void:
	_remaining_seconds = maxf(0.0, _remaining_seconds - delta)
	_update_display()


func _update_display() -> void:
	var total_seconds := ceili(_remaining_seconds)
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60
	_display.text = "%02d:%02d:%02d" % [hours, minutes, seconds]
