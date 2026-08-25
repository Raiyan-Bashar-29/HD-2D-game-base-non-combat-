extends Node
## Developer capture and scene-state overrides. Lives in the game root.
##
## WHY THIS IS A REAL SYSTEM AND NOT A THROWAWAY SNIPPET
## The look of an HD-2D game is its whole point, and the look changes with the hour and the
## weather. Verifying it by launching the game and waiting twenty real minutes for dusk is
## not verification, it is hope. This node makes any lighting condition reachable in one
## command, and captures the result to a file that can be compared against last week's.
##
## MANUAL USE
##   F12   save a screenshot to user://screenshots/
##
## AUTOMATED USE — everything after the bare `--` is passed to the game:
##   godot_console --quit-after 40 -- --shot=user://shots/dusk.png --shot-frame=30 --time=19:10
##   godot_console --quit-after 40 -- --shot=user://shots/rain.png --weather=RAIN
##
##   --shot=<path>        where to write the capture. res:// and user:// both work.
##   --shot-frame=<int>   which frame to capture on. Default 30. Allow enough frames for
##                        the fade-in to finish and for volumetric fog to converge, or the
##                        image will be darker than the real thing.
##   --time=HH:MM         force the clock before capturing.
##   --freeze-time        stop the clock, so a capture is reproducible to the pixel.
##   --skip-to-hour=<int> perform the same time skip a rest point does, after --time.
##   --weather=<KIND>     force weather. Any GameEnums.WeatherKind name.
##   --give=<list>        put items in the player's bag: item/rose_key,item/rose_petal:3
##   --open-inventory     push the inventory screen, to capture a real screen over a
##                        stopped world. Apply --give first or the capture shows an empty bag.
##
## OWNS: capture, and CLI-driven overrides for time and weather.
## MUST NOT: be depended upon by gameplay. Deleting this file must not break the game.

const SHOT_DIR: String = "user://screenshots"
const DEFAULT_SHOT_FRAME: int = 30

var _shot_path: String = ""
var _shot_frame: int = DEFAULT_SHOT_FRAME
var _frames: int = 0
var _captured: bool = false


func _ready() -> void:
	# Captures must work while the game is paused - proving that a screen stops the world is
	# exactly what the capture is for. Pause table: src/ui/root/ui_root.gd.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_arguments()


func _process(_delta: float) -> void:
	if _shot_path == "" or _captured:
		return
	_frames += 1
	if _frames >= _shot_frame:
		_captured = true
		_capture(_shot_path)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed(Actions.DEBUG_SCREENSHOT):
		var stamp: String = Time.get_datetime_string_from_system(false, false).replace(":", "-")
		_capture("%s/shot_%s.png" % [SHOT_DIR, stamp])


## Reads the viewport's own texture, so what lands in the file is exactly what was on
## screen, post-processing and all.
func _capture(path: String) -> void:
	var view: Viewport = get_viewport()
	if view == null:
		Log.error("test", "Capture failed: no viewport")
		return
	var image: Image = view.get_texture().get_image()
	var directory: String = path.get_base_dir()
	if directory != "":
		var made: Error = DirAccess.make_dir_recursive_absolute(directory)
		if made != OK and made != ERR_ALREADY_EXISTS:
			Log.error("test", "Cannot create %s" % directory)
			return
	var err: Error = image.save_png(path)
	if err == OK:
		Log.info("test", "Captured %dx%d to %s" % [image.get_width(), image.get_height(), path])
	else:
		Log.error("test", "Capture to %s failed: %s" % [path, error_string(err)])


func _parse_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--shot="):
			_shot_path = argument.trim_prefix("--shot=")
		elif argument.begins_with("--shot-frame="):
			_shot_frame = maxi(1, argument.trim_prefix("--shot-frame=").to_int())
		elif argument.begins_with("--time="):
			_force_time(argument.trim_prefix("--time="))
		elif argument == "--freeze-time":
			Clock.paused = true
			Log.info("test", "Clock frozen by command line")
		elif argument.begins_with("--skip-to-hour="):
			_skip_to_hour(argument.trim_prefix("--skip-to-hour="))
		elif argument.begins_with("--give="):
			_give(argument.trim_prefix("--give="))
		elif argument == "--open-inventory":
			_open_inventory()
		elif argument.begins_with("--weather="):
			_force_weather(argument.trim_prefix("--weather="))


func _force_time(value: String) -> void:
	var parts: PackedStringArray = value.split(":")
	if parts.size() != 2:
		Log.warn("test", "--time expects HH:MM, got '%s'" % value)
		return
	Clock.set_time(Clock.day, parts[0].to_int(), parts[1].to_int())


func _force_weather(value: String) -> void:
	var names: Array = GameEnums.WeatherKind.keys()
	var index: int = names.find(value.to_upper())
	if index < 0:
		Log.warn("test", "Unknown weather '%s'. Valid: %s" % [value, ", ".join(names)])
		return
	Weather.force(index as GameEnums.WeatherKind)
	Log.info("test", "Weather forced to %s by command line" % value.to_upper())


## The same time skip a rest point performs, reachable from the command line, so a before and
## after capture can prove that skip_to_hour really drives the lighting rather than only
## moving a number. Deliberately Clock.skip_to_hour and not a second implementation: a debug
## path that reimplements the thing it verifies verifies nothing.
func _skip_to_hour(value: String) -> void:
	var skipped: int = Clock.skip_to_hour(value.to_int())
	Log.info("test", "Skipped %d minutes to %02d:00 by command line" % [skipped, Clock.hour])


## Fills the player's bag from the command line, so a capture of the inventory shows real rows
## produced by the real Inventory.add() rather than a mock the screen was posed against.
## Deferred: GameRoot spawns the player in the same _ready() pass that reads these arguments.
func _give(list: String) -> void:
	await get_tree().process_frame
	var bag: Inventory = Inventory.of(Director.player)
	if bag == null:
		Log.error("test", "--give found no inventory on the player")
		return
	for entry: String in list.split(",", false):
		var parts: PackedStringArray = entry.split(":")
		var count: int = parts[1].to_int() if parts.size() > 1 else 1
		var added: bool = bag.add(StringName(parts[0]), maxi(1, count))
		Log.info("test", "--give %s x%d: %s" % [parts[0], count, str(added)])


## Pushes the inventory screen so a windowed capture can show a real screen over a real,
## stopped world. Deferred by two frames: UiRoot is a sibling built in the same _ready() pass
## as this node, and --give needs its own frame before this one reads the bag.
func _open_inventory() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var stack: UiRoot = UiRoot.find(self)
	if stack == null:
		Log.error("test", "--open-inventory found no UiRoot in the tree")
		return
	var opened: bool = stack.open(InventoryScreen.for_carrier(Director.player))
	Log.info("test", "--open-inventory pushed the inventory screen: %s" % str(opened))
