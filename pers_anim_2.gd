extends Node3D


const ANIMATION_NAME := "mixamo_com_002"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ap: AnimationPlayer = find_child("AnimationPlayer")
	var anim := ap.get_animation(ANIMATION_NAME)
	anim.loop_mode = Animation.LOOP_LINEAR
	ap.play(ANIMATION_NAME)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
