extends Node

## Global game settings (audio volume, text-to-speech, window resolution)
## exposed as the `Settings` autoload. Loads from and saves to user://settings.cfg.

const CONFIG_PATH := "user://settings.cfg"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

const DEFAULT_VOLUME := 0.8
const DEFAULT_TTS_ENABLED := true
const DEFAULT_RESOLUTION := Vector2i(1280, 720)

signal volume_changed(value: float)
signal tts_changed(enabled: bool)
signal resolution_changed(size: Vector2i)

var volume: float = DEFAULT_VOLUME
var tts_enabled: bool = DEFAULT_TTS_ENABLED
var resolution: Vector2i = DEFAULT_RESOLUTION


func _ready() -> void:
	load_settings()
	_apply_volume()
	_apply_resolution()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	volume_changed.emit(volume)
	save_settings()


func set_tts_enabled(enabled: bool) -> void:
	if tts_enabled == enabled:
		return
	tts_enabled = enabled
	tts_changed.emit(tts_enabled)
	save_settings()


func set_resolution(size: Vector2i) -> void:
	if size.x <= 0 or size.y <= 0:
		return
	resolution = size
	_apply_resolution()
	resolution_changed.emit(resolution)
	save_settings()


# Returns the selectable resolutions, always including the current one.
func available_resolutions() -> Array[Vector2i]:
	var sizes := RESOLUTIONS.duplicate()
	if not sizes.has(resolution):
		sizes.append(resolution)
		sizes.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.x * a.y < b.x * b.y)
	return sizes


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	volume = clampf(float(config.get_value("audio", "volume", DEFAULT_VOLUME)), 0.0, 1.0)
	tts_enabled = bool(config.get_value("accessibility", "tts_enabled", DEFAULT_TTS_ENABLED))
	var width := int(config.get_value("display", "width", DEFAULT_RESOLUTION.x))
	var height := int(config.get_value("display", "height", DEFAULT_RESOLUTION.y))
	resolution = Vector2i(width, height)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("accessibility", "tts_enabled", tts_enabled)
	config.set_value("display", "width", resolution.x)
	config.set_value("display", "height", resolution.y)
	config.save(CONFIG_PATH)


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


func _apply_resolution() -> void:
	DisplayServer.window_set_size(resolution)
	var origin := DisplayServer.screen_get_position()
	var screen := DisplayServer.screen_get_size()
	DisplayServer.window_set_position(origin + (screen - resolution) / 2)
