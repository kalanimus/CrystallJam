extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.002

var _movement_locked: bool = false
var _held_object: Node

@onready var head: Node3D = $Head
@onready var interaction_ray: RayCast3D = $Head/Camera3D/RayCast3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Поворот персонажа влево/вправо
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Поворот камеры вверх/вниз
		head.rotate_x(-event.relative.y * mouse_sensitivity)

		# Чтобы камера не переворачивалась
		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-89),
			deg_to_rad(89)
		)
	if event.is_action_pressed("interact") and not _movement_locked:
		try_interact()
	if event.is_action_released("interact"):
		_release_held_object()
	if not _movement_locked and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_get_inventory().use_active_item()
	if not _movement_locked and event is InputEventKey and event.pressed and event.physical_keycode == KEY_Q:
		_get_inventory().drop_active_item(self)
	if event.is_action_pressed("ui_cancel"):
		_open_pause_menu()


func lock_movement() -> void:
	_movement_locked = true
	_release_held_object()


func unlock_movement() -> void:
	_movement_locked = false


func _open_pause_menu() -> void:
	var menu := get_tree().get_first_node_in_group("pause_menu")
	if menu and menu.has_method("open_menu"):
		menu.open_menu()
		get_viewport().set_input_as_handled()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func try_interact():
	if is_instance_valid(_held_object):
		if _held_object.has_method("is_being_held") and not _held_object.is_being_held():
			_held_object = null
		else:
			return

	if interaction_ray.is_colliding():
		var object = interaction_ray.get_collider()

		if object.has_method("begin_hold"):
			object.begin_hold(self)
			_held_object = object
		elif object.has_method("interact"):
			object.interact(self)


func _release_held_object() -> void:
	if is_instance_valid(_held_object) and _held_object.has_method("release_hold"):
		_held_object.release_hold()
	_held_object = null


func get_camera_forward() -> Vector3:
	return -$Head/Camera3D.global_transform.basis.z


func _get_inventory():
	return get_tree().get_first_node_in_group("inventory")


func _physics_process(delta):
	var input_dir := Vector2.ZERO
	if not _movement_locked:
		input_dir = Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward"
		)

	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if _movement_locked:
		velocity.x = 0.0
		velocity.z = 0.0
	elif direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Гравитация
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	move_and_slide()
