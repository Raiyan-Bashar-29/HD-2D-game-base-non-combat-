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
##   --cross-area-save    empty a chest in the hall, take an item in the courtyard, save,
##                        reload, and report whether BOTH survived. Proves world state on the
##                        far side of an unloaded area, which no assertion can: a threaded
##                        load needs frames and TestCase.run() is synchronous.
##   --round-trips=<n>    travel courtyard -> lantern_hall -> courtyard n times, reporting
##                        node count and static memory before and after. This is how the
##                        twenty-round-trip leak criterion is actually measured.
##   --talk=<id>          open a conversation once the boot load has settled, so the dialogue
##                        box can be captured. Takes the bare id: --talk=talk/gardener
##   --talk-advance=<n>   press through n lines after --talk, to capture a branch rather than
##                        always the opening line
##   --goto=<area>        travel to an area once the boot load has settled, so a capture can
##                        be taken somewhere other than the starting area.
##   --open-inventory     push the inventory screen, to capture a real screen over a
##                        stopped world. Apply --give first or the capture shows an empty bag.
##   --new-game           the game no longer boots into an area (WP-12): it boots into the main
##                        menu. Every flag above that waits for an area needs this first, and it
##                        goes through Director.start_new_game, which is what the menu row calls.
##   --open-menu=<list>   push menus by name for a capture, innermost last: main_menu, pause,
##                        settings, saves, controls. `--open-menu=pause,settings` puts settings
##                        over the pause menu, the way a player reaches it. Built through
##                        ScreenKeys.menu_for, so a capture cannot photograph a screen
##                        assembled differently from the real one. Waits for the area when
##                        --new-game is on the same line.
##
## OWNS: capture, and CLI-driven overrides for time and weather.
## MUST NOT: be depended upon by gameplay. Deleting this file must not break the game.

const SHOT_DIR: String = "user://screenshots"
const DEFAULT_SHOT_FRAME: int = 30

var _shot_path: String = ""
var _shot_frame: int = DEFAULT_SHOT_FRAME
var _frames: int = 0
var _captured: bool = false
var _talk_advance: int = 0
## Set by --new-game, read by --open-menu: a menu pushed before the transition lands is closed
## again by it, because ScreenKeys unwinds the stack on every travel.
var _fresh_game: bool = false


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
		elif argument.begins_with("--talk="):
			_talk(StringName(argument.trim_prefix("--talk=")))
		elif argument.begins_with("--talk-advance="):
			_talk_advance = maxi(0, argument.trim_prefix("--talk-advance=").to_int())
		elif argument.begins_with("--goto="):
			_goto(StringName(argument.trim_prefix("--goto=")))
		elif argument == "--cross-area-save":
			_cross_area_save()
		elif argument.begins_with("--round-trips="):
			_round_trips(maxi(1, argument.trim_prefix("--round-trips=").to_int()))
		elif argument == "--open-inventory":
			_open_inventory()
		elif argument == "--new-game":
			_fresh_game = true
			_new_game()
		elif argument.begins_with("--open-menu="):
			_open_menu(argument.trim_prefix("--open-menu="))
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
	# Wait for an area, not merely for the tree to settle. Since WP-12 the boot path stops at
	# the main menu, so without --new-game alongside this there is no world to photograph.
	while Director.current_area_id == &"":
		await get_tree().process_frame
	await _settled()
	var stack: UiRoot = UiRoot.find(self)
	if stack == null:
		Log.error("test", "--open-inventory found no UiRoot in the tree")
		return
	var opened: bool = stack.open(InventoryScreen.for_carrier(Director.player))
	Log.info("test", "--open-inventory pushed the inventory screen: %s" % str(opened))


## The main menu's New Game row, from the command line, so every flag that waits for an area
## still works now that boot stops at a menu. Deliberately Director.start_new_game and not a
## second implementation: a debug path that reimplements what it verifies verifies nothing.
##
## The stack is unwound by ScreenKeys on area_change_requested, so nothing here closes the menu.
func _new_game() -> void:
	await get_tree().process_frame
	Director.start_new_game()
	Log.info("test", "--new-game requested '%s'" % Director.FIRST_AREA)


## Push one or more menus for a capture, innermost last: `--open-menu=pause,settings` gives the
## settings screen over the pause menu over the world, which is how a player actually reaches
## it. Through ScreenKeys.menu_for, so what is photographed is the screen the game really
## builds and not one assembled by hand for the photograph.
##
## Two frames late for UiRoot, which is a sibling built in the same _ready() pass as this node.
## And when --new-game is also on the line, the area has to arrive FIRST: ScreenKeys unwinds the
## whole stack on area_change_requested, so a menu pushed before the transition is closed again
## by the transition it was waiting for.
func _open_menu(list: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _fresh_game:
		while Director.current_area_id == &"":
			await get_tree().process_frame
		await _settled()
	var stack: UiRoot = UiRoot.find(self)
	for menu_id: String in list.split(",", false):
		var screen: UiScreen = ScreenKeys.menu_for(StringName(menu_id))
		if stack == null or screen == null:
			Log.error("test", "--open-menu=%s found no stack or no such menu" % menu_id)
			return
		Log.info("test", "--open-menu %s pushed: %s" % [menu_id, str(stack.open(screen))])


## Travel back and forth `count` times and report what it cost. A leak in a transition is
## invisible in a single trip and obvious over twenty, which is why the criterion is twenty
## and why this is a RUN rather than an assertion: TestCase.run() is synchronous and cannot
## await a threaded load.
##
## Node count and static memory are sampled with the area settled and the same area loaded at
## both ends, so the two numbers are directly comparable. Anything that grows per trip shows
## up as a slope rather than noise.
func _round_trips(count: int) -> void:
	# Wait for the FIRST area, not merely for the tree to settle. Arguments are read in _ready,
	# before GameRoot has even requested the boot transition, so is_transitioning() is still
	# false here — settling on it alone reads an empty home and sends every return trip to "".
	while Director.current_area_id == &"":
		await get_tree().process_frame
	await _settled()
	var home: StringName = Director.current_area_id
	var nodes_before: int = _node_count()
	var memory_before: int = _static_memory()
	Log.info("test", "--round-trips %d from '%s': %d nodes, %d KiB" % [
		count, home, nodes_before, memory_before / 1024,
	])

	for trip: int in count:
		await _travel(&"lantern_hall", &"from_courtyard")
		await _travel(home, &"north_arch")
		Log.info("test", "  trip %d/%d: %d nodes, %d KiB" % [
			trip + 1, count, _node_count(), _static_memory() / 1024,
		])

	var nodes_after: int = _node_count()
	var memory_after: int = _static_memory()
	Log.info("test", "--round-trips done: nodes %d -> %d (%+d), memory %d -> %d KiB (%+d)" % [
		nodes_before, nodes_after, nodes_after - nodes_before,
		memory_before / 1024, memory_after / 1024, (memory_after - memory_before) / 1024,
	])


func _travel(area_id: StringName, spawn_id: StringName) -> void:
	Events.area_change_requested.emit(area_id, spawn_id)
	# A SECOND request in the same frame, which the guard must refuse. Asserted here rather
	# than in the suite because only a live transition can be interrupted.
	Events.area_change_requested.emit(area_id, spawn_id)
	await _settled()


## Wait for the transition to end, then let the freed area actually leave the tree —
## queue_free() takes effect at the end of a frame, so sampling immediately after arrival
## counts the old area as still present and reports a leak that is not there.
func _settled() -> void:
	while Director.is_transitioning():
		await get_tree().process_frame
	for _i: int in 4:
		await get_tree().process_frame


func _node_count() -> int:
	return DictRead.to_float(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) as int


func _static_memory() -> int:
	return DictRead.to_float(Performance.get_monitor(Performance.MEMORY_STATIC)) as int


## The criterion no assertion can reach: state in an area that is no longer loaded.
##
## Empty the hall's coffer, come back, take the courtyard's key, save, reload, and go and look
## at the coffer again. Per-object persistence is already covered by the suite, but only
## within ONE area that never left the tree. What is new here is that unloading an area must
## not take its world state with it.
const PROBE_SLOT: int = 5


func _cross_area_save() -> void:
	while Director.current_area_id == &"":
		await get_tree().process_frame
	await _settled()
	await _travel(&"lantern_hall", &"from_courtyard")
	Log.info("test", "--cross-area-save hall coffer emptied: %s" % str(_empty_the_coffer()))
	var bag: Inventory = Inventory.of(Director.player)
	bag.add(&"item/rose_key", 1)
	# Saved IN THE HALL and reloaded from the courtyard, deliberately. A save taken where the
	# reload already is cannot tell "the area was restored" from "the area never changed" —
	# which is exactly how a broken DictRead.get_name hid in Director for three packages.
	Log.info("test", "--cross-area-save saved in '%s': %s" % [
		Director.current_area_id, error_string(SaveSystem.save_to_slot(PROBE_SLOT)),
	])
	await _travel(&"courtyard", &"north_arch")

	# Wipe what a fresh session would not have, so a survival that is really just a value
	# nobody cleared cannot pass for a value that was restored.
	bag.clear_all()
	Flags.set_flag(&"obj/lantern_hall/hall_chest/emptied", false)
	Log.info("test", "--cross-area-save wiped: carrying %d, coffer emptied=%s" % [
		bag.total_count(), str(Flags.get_bool(&"obj/lantern_hall/hall_chest/emptied")),
	])

	Log.info("test", "--cross-area-save loaded: %s" % error_string(SaveSystem.load_from_slot(PROBE_SLOT)))
	await _settled()
	Log.info("test", "--cross-area-save after reload: area='%s', carrying %d" % [
		Director.current_area_id, Inventory.of(Director.player).total_count(),
	])
	await _travel(&"lantern_hall", &"from_courtyard")
	Log.info("test", "--cross-area-save coffer still empty: %s" % str(_coffer_is_empty()))
	SaveSystem.delete_slot(PROBE_SLOT)


func _empty_the_coffer() -> bool:
	var coffer: ItemContainer = _coffer()
	return coffer != null and coffer.attempt(Director.player)


func _coffer_is_empty() -> bool:
	var coffer: ItemContainer = _coffer()
	return coffer != null and coffer.is_emptied()


func _coffer() -> ItemContainer:
	var tree: SceneTree = get_tree()
	var found: Node = tree.root.find_child("HallChest", true, false)
	if found == null:
		Log.error("test", "--cross-area-save found no HallChest in the tree")
	return found as ItemContainer


## Travel somewhere for a capture. Waits for the boot load first: a request made before the
## first area exists is refused by the guard, which would look like the flag not working.
func _goto(area_id: StringName) -> void:
	while Director.current_area_id == &"":
		await get_tree().process_frame
	await _settled()
	Events.area_change_requested.emit(area_id, &"")
	await _settled()
	Log.info("test", "--goto arrived in '%s'" % Director.current_area_id)


## Open a conversation for a capture. Goes through the SAME bus signal a Speaker emits, so what
## is photographed is the real path and not a screen posed by hand.
func _talk(talk_id: StringName) -> void:
	while Director.current_area_id == &"":
		await get_tree().process_frame
	await _settled()
	Events.dialogue_requested.emit(talk_id)
	await get_tree().process_frame
	var stack: UiRoot = UiRoot.find(self)
	var screen: DialogueScreen = stack.top() as DialogueScreen
	if screen == null:
		Log.error("test", "--talk opened no dialogue screen for '%s'" % talk_id)
		return
	Log.info("test", "--talk opened '%s' at node '%s'" % [
		talk_id, screen.runner.current_node().node_id,
	])
	for _i: int in _talk_advance:
		await _reveal_done(screen)
		screen.runner.advance()
		await get_tree().process_frame
	await _reveal_done(screen)
	Log.info("test", "--talk resting on node '%s', %d choices" % [
		screen.runner.current_node().node_id, screen.runner.available_choices().size(),
	])


## Let the typewriter finish. A capture taken mid-reveal photographs half a sentence, which
## looks like a truncation bug rather than the feature it is.
func _reveal_done(screen: DialogueScreen) -> void:
	for _i: int in 240:
		if screen.reveal_complete():
			return
		await get_tree().process_frame
