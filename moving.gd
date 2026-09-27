extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.002

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
	if event.is_action_pressed("interact"):
		try_interact()
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func try_interact():
	if interaction_ray.is_colliding():
		var object = interaction_ray.get_collider()

		if object.has_method("interact"):
			object.interact()


func _physics_process(delta):
	var input_dir = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if direction:
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
