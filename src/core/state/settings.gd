extends Node
## User preferences. Autoload `Settings`.
##
## WHY IT IS SEPARATE FROM Flags
## Settings belong to the player's machine, not to the save file. Copying a save to another
## computer should not drag someone else's resolution and volume along with it. Different
## lifetime, different file.
##
## Stored as a plain ConfigFile at user://settings.cfg so a player can read and repair it by
## hand if a bad value ever locks them out of the game.
##
## OWNS: the settings file, the default values, and applying the ones that belong to the
## window and the display server.
## MUST NOT: apply audio or gameplay settings itself. It announces a change through
## Events.setting_changed and the owning system reacts. That keeps this file from growing a
## branch for every feature that ever gains an option.

const PATH: String = "user://settings.cfg"

## Every setting the game has, with its default. This is also the validation list: a key
## that is not here is rejected, so a typo cannot silently create a dead setting.
const DEFAULTS: Dictionary = {
	"video/window_mode": 0,          # 0 windowed, 1 borderless fullscreen, 2 exclusive
	"video/vsync": 1,                # matches DisplayServer.VSyncMode
	"video/max_fps": 0,              # 0 = uncapped
	"video/resolution_scale": 1.0,   # rendering/scaling_3d/scale at runtime
	"video/bloom": true,
	"video/depth_of_field": true,    # the tilt-shift look; off is a real accessibility need
	"video/shadows": true,
	"audio/master": 0.9,
	"audio/music": 0.8,
	"audio/ambience": 0.8,
	"audio/sfx": 0.9,
	"audio/ui": 0.8,
	"gameplay/text_speed": 1.0,      # dialogue characters per tick multiplier
	"gameplay/autosave": true,
	"gameplay/run_is_toggle": false, # hold to run by default
	"gameplay/show_interact_hints": true,
	"gameplay/camera_shake": 1.0,
	"accessibility/text_scale": 1.0,
	"accessibility/reduce_motion": false,
	"accessibility/high_contrast_prompts": false,
	"accessibility/subtitles": true,
	"accessibility/hold_to_confirm": false,
	"locale": "en",
}

## The one setting with no section, and the second this file applies without a system owning it.
const LOCALE: String = "locale"

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_load_from_disk()
	_apply_display()
	_apply_locale()
	Log.info("settings", "Loaded %d settings" % DEFAULTS.size())


## Read a setting. `path` is "section/key" exactly as written in DEFAULTS.
func get_value(path: String) -> Variant:
	if not DEFAULTS.has(path):
		Log.error("settings", "Unknown setting '%s' requested" % path)
		return null
	var parts: PackedStringArray = _split(path)
	return _config.get_value(parts[0], parts[1], DEFAULTS[path])


func get_bool(path: String) -> bool:
	var value: Variant = get_value(path)
	return value if value is bool else false


func get_float(path: String) -> float:
	var value: Variant = get_value(path)
	if value is float:
		return value
	if value is int:
		return float(value as int)
	return 0.0


func get_int(path: String) -> int:
	var value: Variant = get_value(path)
	if value is int:
		return value
	if value is float:
		return roundi(value as float)
	return 0


func get_string(path: String) -> String:
	var value: Variant = get_value(path)
	return value if value is String else ""


## Write a setting, announce it, and persist. Unknown keys are refused loudly rather than
## stored, so a typo shows up immediately instead of becoming a setting nothing reads.
func set_value(path: String, value: Variant) -> void:
	if not DEFAULTS.has(path):
		Log.error("settings", "Refusing to set unknown setting '%s'" % path)
		return
	var expected: int = typeof(DEFAULTS[path])
	var got: int = typeof(value)
	var numeric_swap: bool = (expected == TYPE_FLOAT and got == TYPE_INT) or (expected == TYPE_INT and got == TYPE_FLOAT)
	if got != expected and not numeric_swap:
		Log.error("settings", "'%s' expects %s, got %s" % [path, type_string(expected), type_string(got)])
		return

	var parts: PackedStringArray = _split(path)
	_config.set_value(parts[0], parts[1], value)
	save()
	Events.setting_changed.emit(parts[0], parts[1], value)
	if parts[0] == "video":
		_apply_display()
	elif path == LOCALE:
		_apply_locale()


func save() -> void:
	var err: Error = _config.save(PATH)
	if err != OK:
		Log.error("settings", "Could not write %s: %s" % [PATH, error_string(err)])


## Restore every default and re-apply. Used by the settings screen's reset button.
func reset_to_defaults() -> void:
	_config.clear()
	save()
	_apply_display()
	for path: String in DEFAULTS:
		var parts: PackedStringArray = _split(path)
		Events.setting_changed.emit(parts[0], parts[1], DEFAULTS[path])
	Log.info("settings", "Reset to defaults")


func _load_from_disk() -> void:
	var err: Error = _config.load(PATH)
	if err == ERR_FILE_NOT_FOUND:
		Log.info("settings", "No settings file yet — writing defaults")
		save()
		return
	if err != OK:
		Log.warn("settings", "%s unreadable (%s) — using defaults" % [PATH, error_string(err)])


## Applied here rather than announced, because nothing else owns the window.
func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_apply_vsync(get_int("video/vsync"))
	Engine.max_fps = get_int("video/max_fps")
	match get_int("video/window_mode"):
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _split(path: String) -> PackedStringArray:
	var parts: PackedStringArray = path.split("/", false, 1)
	if parts.size() == 1:
		return PackedStringArray(["general", parts[0]])
	return parts


## Mapped explicitly rather than cast, because an out-of-range integer in a hand-edited
## settings file would otherwise become an invalid enum value.
func _apply_vsync(mode: int) -> void:
	match mode:
		0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		2:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		3:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
		_:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)


## THE SECOND SETTING THIS FILE APPLIES ITSELF, and for `_apply_display`'s reason rather than by
## analogy with it: nothing else owns `TranslationServer` either. A consumer would have to be a
## system, and "the language" is not one - every screen reads it, none of them owns it.
##
## NOT skipped under headless, which is the one way this differs from the display. A translation
## has no window in it, so the suite can and does assert against `tr()` - and the criterion this
## closes ("switch language at runtime and see every visible string change") would otherwise be
## provable only by eye.
##
## An empty or unknown locale is left alone rather than forced: `TranslationServer` falls back to
## the project's default, and a settings file hand-edited to nonsense should not blank the UI.
func _apply_locale() -> void:
	var wanted: String = get_string(LOCALE)
	if wanted == "":
		return
	TranslationServer.set_locale(wanted)
	Log.info("settings", "Locale -> %s" % TranslationServer.get_locale())
