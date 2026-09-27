extends RigidBody3D

@export var hold_distance := 0.5
@export var minimum_hold_distance := 0.35
@export var maximum_hold_distance := 1.2
@export var hold_force := 45.0
@export var max_hold_force := 55.0
@export var velocity_damping := 8.0

var _holder: CharacterBody3D


func begin_hold(player: CharacterBody3D) -> void:
	_holder = player
	freeze = false
	can_sleep = false
	continuous_cd = true
	add_collision_exception_with(player)
	player.add_collision_exception_with(self)


func release_hold() -> void:
	if is_instance_valid(_holder):
		remove_collision_exception_with(_holder)
		_holder.remove_collision_exception_with(self)
	_holder = null
	can_sleep = true


func is_being_held() -> bool:
	return is_instance_valid(_holder)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_holder):
		return

	var camera: Camera3D = _holder.get_node("Head/Camera3D")
	if global_position.distance_to(camera.global_position) > maximum_hold_distance:
		release_hold()
		return

	var distance := clampf(hold_distance, minimum_hold_distance, maximum_hold_distance)
	var target_position: Vector3 = camera.global_position + _holder.get_camera_forward() * distance
	var offset: Vector3 = target_position - global_position
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var force: Vector3 = offset * hold_force - linear_velocity * velocity_damping
	force += Vector3.UP * mass * gravity
	apply_central_force(force.limit_length(max_hold_force))
