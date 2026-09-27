extends HBoxContainer

const SLOT_COUNT := 10

var active_slot := 0
var slots: Array[Panel] = []
var slot_labels: Array[Label] = []
var items: Array = []


func _ready() -> void:
	add_to_group("inventory")
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
	items.resize(SLOT_COUNT)

	for index in SLOT_COUNT:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(52, 52)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var number := Label.new()
		number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.text = str(index + 1)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE

		slot.add_child(number)
		add_child(slot)
		slots.append(slot)
		slot_labels.append(number)

	_update_slot_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_active_slot(posmod(active_slot - 1, SLOT_COUNT))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_active_slot(posmod(active_slot + 1, SLOT_COUNT))
			get_viewport().set_input_as_handled()


func _on_dialogue_started() -> void:
	hide()


func _on_dialogue_finished() -> void:
	show()


func _set_active_slot(new_slot: int) -> void:
	active_slot = new_slot
	_update_slot_visuals()
	print("Активный слот: %d" % (active_slot + 1))


func add_item(item: RigidBody3D) -> bool:
	var free_slot := items.find(null)
	if free_slot == -1:
		print("Инвентарь заполнен")
		return false

	items[free_slot] = item
	item.store_in_inventory(self)
	_update_slot_visuals()
	return true


func use_active_item() -> void:
	var item = items[active_slot]
	if item and item.has_method("use_from_inventory"):
		item.use_from_inventory()


func drop_active_item(player: CharacterBody3D) -> void:
	var item = items[active_slot]
	if item == null:
		return

	var camera: Camera3D = player.get_node("Head/Camera3D")
	var direction: Vector3 = player.get_camera_forward()
	var drop_position: Vector3 = camera.global_position + direction * 1.2
	items[active_slot] = null
	item.drop_from_inventory(get_tree().current_scene, drop_position, direction)
	_update_slot_visuals()


func _update_slot_visuals() -> void:
	for index in slots.size():
		var item = items[index]
		slot_labels[index].text = str(index + 1) if item == null else "%d\n%s" % [index + 1, item.item_name]
		slots[index].add_theme_stylebox_override(
			"panel", _make_slot_style(index == active_slot)
		)


func _make_slot_style(is_active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.24, 0.92)
	style.border_color = Color(1, 0.8, 0.25, 1) if is_active else Color(0.7, 0.75, 0.85, 0.8)
	style.set_border_width_all(3 if is_active else 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style
