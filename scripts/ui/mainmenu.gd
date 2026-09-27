extends Control

const GAME_SCENE := "res://node_3d.tscn"

signal resume_requested

@export var is_overlay := false

var _options_root: CenterContainer
var _options_button: Button
var _volume_slider: HSlider
var _volume_label: Label
var _tts_check: CheckBox
var _resolution_option: OptionButton


func _ready() -> void:
	if is_overlay:
		process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		add_to_group("pause_menu")
	var primary_button: Button = $CenterContainer/Menu/ContinueButton
	primary_button.text = "Continue" if is_overlay else "Start"
	primary_button.pressed.connect(_on_continue_pressed)
	$CenterContainer/Menu/OptionsButton.pressed.connect(_on_options_pressed)
	$CenterContainer/Menu/ExitButton.pressed.connect(_on_exit_pressed)
	_build_options_panel()
	primary_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _options_root.visible:
			_close_options()
		elif is_overlay:
			close_menu()
		else:
			_on_exit_pressed()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	_options_root.hide()
	$CenterContainer.show()
	$CenterContainer/Menu/ContinueButton.grab_focus()


func close_menu() -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resume_requested.emit()


func _on_continue_pressed() -> void:
	if is_overlay:
		close_menu()
	elif ResourceLoader.exists(GAME_SCENE):
		get_tree().change_scene_to_file(GAME_SCENE)


func _on_options_pressed() -> void:
	$CenterContainer.hide()
	_options_root.show()
	_options_button.grab_focus()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _build_options_panel() -> void:
	_options_root = CenterContainer.new()
	_options_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_options_root.visible = false
	add_child(_options_root)

	var panel := PanelContainer.new()
	_options_root.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	_volume_label = Label.new()
	vbox.add_child(_volume_label)
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.custom_minimum_size = Vector2(280, 0)
	_volume_slider.set_value_no_signal(Settings.volume * 100.0)
	_volume_slider.value_changed.connect(_on_volume_changed)
	vbox.add_child(_volume_slider)
	_update_volume_label(Settings.volume)

	_tts_check = CheckBox.new()
	_tts_check.text = "Text-to-speech"
	_tts_check.button_pressed = Settings.tts_enabled
	_tts_check.toggled.connect(_on_tts_toggled)
	vbox.add_child(_tts_check)

	var resolution_label := Label.new()
	resolution_label.text = "Resolution"
	vbox.add_child(resolution_label)
	_resolution_option = OptionButton.new()
	_populate_resolutions()
	_resolution_option.item_selected.connect(_on_resolution_selected)
	vbox.add_child(_resolution_option)

	_options_button = Button.new()
	_options_button.text = "Back"
	_options_button.pressed.connect(_close_options)
	vbox.add_child(_options_button)


func _populate_resolutions() -> void:
	for size in Settings.available_resolutions():
		var index := _resolution_option.item_count
		_resolution_option.add_item("%d x %d" % [size.x, size.y])
		_resolution_option.set_item_metadata(index, size)
		if size == Settings.resolution:
			_resolution_option.select(index)


func _close_options() -> void:
	_options_root.hide()
	$CenterContainer.show()
	$CenterContainer/Menu/OptionsButton.grab_focus()


func _on_volume_changed(value: float) -> void:
	Settings.set_volume(value / 100.0)
	_update_volume_label(Settings.volume)


func _update_volume_label(value: float) -> void:
	_volume_label.text = "Volume (%d%%)" % roundi(value * 100.0)


func _on_tts_toggled(pressed: bool) -> void:
	Settings.set_tts_enabled(pressed)


func _on_resolution_selected(index: int) -> void:
	Settings.set_resolution(_resolution_option.get_item_metadata(index))
