extends Node
## Staging: put the game into the state a photograph needs, then get out of the way.
##
## THE SEAM, AND WHY THERE ARE NOW THREE DEBUG FILES
## `dev_capture.gd` answers "what does the game LOOK like under condition X" and owns the
## shutter. `dev_probes.gd` answers "does sequence Y actually work" and owns the measurements.
## This file answers "put the player THERE, holding THAT, with THIS person feeling THAT way" so
## the other two have something worth looking at. All three were one file until the budget
## checker refused it twice, at 310 and then at 320 of the 250 allowed code lines — and both
## times the seam it exposed was already there in the reasoning. That is the tool working.
##
## EVERY FLAG HERE GOES THROUGH THE REAL PATH. Standing is set through `Flags` on the key
## `Standing` publishes, an interaction is a real `InputEventAction` through
## `Input.parse_input_event`, a conversation opens through the same bus signal a `Speaker`
## emits. A staging tool that reached past the game to pose it would photograph a mock.
##
## THE FLAGS RUN CONCURRENTLY, and each waits a different number of frames before acting, which
## is what orders them: --stand-by settles first, --cycle after it, --interact last. That is
## fragile if a fourth is added; add it with a longer wait than the one it must follow.
##
## EVERYTHING AFTER THE BARE `--` IS PASSED TO THE GAME:
##
##   --give=<list>        put items in the player's bag: item/rose_key,item/rose_petal:3
##   --open-inventory     push the inventory screen over a stopped world. Apply --give first,
##                        or the capture shows an empty bag.
##   --talk=<id>          open a conversation: --talk=talk/gardener
##   --talk-advance=<n>   press through n lines, to capture a branch rather than the opening.
##   --goto=<area>        travel somewhere else once the boot load has settled.
##   --stand-by=<name>    put the player beside a named node and let the sensor settle on it.
##   --standing=<who>:<n> set someone's standing, to photograph an action refused, failing and
##                        succeeding without playing the twenty minutes it takes to earn it.
##   --cycle=<n>          press the cycle key n times, to select past the first of several
##                        overlapping targets. An NPC with two path actions and a conversation
##                        is three overlapping interactables.
##   --interact=<n>       press the interact key n times, so a capture shows the OUTCOME of an
##                        action rather than only its prompt. A refusal, a failure and a
##                        success look identical until the button is pressed.
##   --new-game           start a game. Since WP-12 the boot goes to the main menu, not to an
##                        area, so without this there is no world to photograph.
##   --open-menu=<list>   push menus by name, innermost last: main_menu, pause, settings,
##                        saves, controls. `--open-menu=pause,settings` puts settings over the
##                        pause menu.
##   --npc-settle=<n>     let NPCs walk for n physics frames, so a screenshot shows them AT
##                        their posts rather than halfway there.
##
## OWNS: putting the world into a named state for a capture.
## MUST NOT: be depended upon by gameplay, measure anything, or reach past the game to pose it.
## Deleting this file must not break the game.

var _talk_advance: int = 0
## Set by --new-game, read by --open-menu: a menu pushed before the transition lands is closed
## again by it, because ScreenKeys unwinds the stack on every travel.
var _fresh_game: bool = false


func _ready() -> void:
	# Staging has to work with a screen open: half of what is worth photographing is a screen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_arguments()


func _parse_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--give="):
			_give(argument.trim_prefix("--give="))
		elif argument == "--open-inventory":
			_open_inventory()
		elif argument.begins_with("--talk-advance="):
			_talk_advance = maxi(0, argument.trim_prefix("--talk-advance=").to_int())
		elif argument.begins_with("--talk="):
			_talk(StringName(argument.trim_prefix("--talk=")))
		elif argument.begins_with("--goto="):
			_goto(StringName(argument.trim_prefix("--goto=")))
		elif argument.begins_with("--stand-by="):
			_stand_by(argument.trim_prefix("--stand-by="))
		elif argument.begins_with("--standing="):
			_force_standing(argument.trim_prefix("--standing="))
		elif argument.begins_with("--cycle="):
			_cycle_target(maxi(1, argument.trim_prefix("--cycle=").to_int()))
		elif argument.begins_with("--interact="):
			_press_interact(maxi(1, argument.trim_prefix("--interact=").to_int()))
		elif argument == "--new-game":
			_fresh_game = true
			_new_game()
		elif argument.begins_with("--open-menu="):
			_open_menu(argument.trim_prefix("--open-menu="))
		elif argument.begins_with("--npc-settle="):
			_npc_settle(maxi(1, argument.trim_prefix("--npc-settle=").to_int()))


## Wait for a transition to finish and for the freed area to actually leave the tree.
## Duplicated in dev_probes.gd, deliberately: five lines repeated once is a better trade than a
## shared base class binding two independent debug nodes together.
func _settled() -> void:
	while Director.is_transitioning():
		await get_tree().process_frame
	for _i: int in 4:
		await get_tree().process_frame


func _wait_for_area() -> void:
	while Director.current_area_id == &"":
		await get_tree().process_frame
	await _settled()


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



## Travel back and forth `count` times and report what it cost. A leak in a transition is
## invisible in a single trip and obvious over twenty, which is why the criterion is twenty
## and why this is a RUN rather than an assertion: TestCase.run() is synchronous and cannot
## await a threaded load.
##
## Node count and static memory are sampled with the area settled and the same area loaded at
## both ends, so the two numbers are directly comparable. Anything that grows per trip shows
## up as a slope rather than noise.
func _goto(area_id: StringName) -> void:
	await _wait_for_area()
	Events.area_change_requested.emit(area_id, &"")
	await _settled()
	Log.info("test", "--goto arrived in '%s'" % Director.current_area_id)


## Open a conversation for a capture. Goes through the SAME bus signal a Speaker emits, so what
## is photographed is the real path and not a screen posed by hand.
func _talk(talk_id: StringName) -> void:
	await _wait_for_area()
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



## Step the clock through a whole day and report where every NPC actually stands at each hour.
## The criterion is "at the market at noon and home at night"; this is the measurement.
func _npc_settle(frames: int) -> void:
	await _wait_for_area()
	for _i: int in frames:
		await get_tree().physics_frame
	for npc: Node in _all_npcs():
		var brain: NpcBrain = npc as NpcBrain
		Log.info("test", "--npc-settle %s at '%s' (%s), %.2fm away" % [
			npc.name, brain.current_waypoint(), brain.activity_name(),
			_distance_to_intent(brain),
		])


## Walk the player up to a named node and let the interaction sensor settle on it. A capture of
## a prompt is worthless if the prompt is for whatever happened to be nearest the spawn point.
func _stand_by(node_name: String) -> void:
	await _wait_for_area()
	var target: Node3D = get_tree().root.find_child(node_name, true, false) as Node3D
	if target == null:
		Log.error("test", "--stand-by found no node called '%s'" % node_name)
		return
	var player: Node3D = Director.player
	player.global_position = target.global_position + Vector3(0.0, 0.0, 1.1)
	for _i: int in 30:
		await get_tree().physics_frame
	var sensor: InteractionSensor = player.get_node_or_null(
		^"InteractionSensor") as InteractionSensor
	var current: Interactable = sensor.current()
	Log.info("test", "--stand-by beside '%s', sensor has '%s'" % [
		node_name, current.name if current != null else "NOTHING",
	])


## Force a standing before a capture, so the same action can be photographed refused, failing
## and succeeding without playing the twenty minutes it would take to earn it.
func _force_standing(value: String) -> void:
	var parts: PackedStringArray = value.split(":")
	if parts.size() != 2:
		Log.warn("test", "--standing expects <who>:<n>, got '%s'" % value)
		return
	var who: StringName = StringName(parts[0])
	Flags.set_flag(Standing.key(who), parts[1].to_int())
	Log.info("test", "--standing %s = %d by command line" % [who, Standing.of(who)])


## Press the cycle key, to select past the first of several overlapping targets. An NPC offering
## two path actions plus a conversation is three overlapping interactables, and this is how a
## capture reaches the second one.
func _cycle_target(times: int) -> void:
	await _wait_for_area()
	for _i: int in 40:
		await get_tree().physics_frame
	for _i: int in times:
		var event := InputEventAction.new()
		event.action = Actions.INTERACT_CYCLE
		event.pressed = true
		Input.parse_input_event(event)
		await get_tree().physics_frame
		await get_tree().physics_frame
	var sensor: InteractionSensor = Director.player.get_node_or_null(
		^"InteractionSensor") as InteractionSensor
	var current: Interactable = sensor.current()
	Log.info("test", "--cycle %d: sensor has '%s'" % [
		times, current.name if current != null else "NOTHING",
	])


## Press the interact key for real, so a capture photographs what the action DID. The three
## outcomes of a path action - refused, committed and failed, committed and succeeded - all
## show the same prompt beforehand, and differ only in the line that follows.
##
## Runs after --stand-by and --cycle have chosen a target, so the ordering of the flags on the
## command line is the ordering of the actions.
func _press_interact(times: int) -> void:
	await _wait_for_area()
	for _i: int in 70:
		await get_tree().physics_frame
	var sensor: InteractionSensor = Director.player.get_node_or_null(
		^"InteractionSensor") as InteractionSensor
	for _i: int in times:
		var target: Interactable = sensor.current()
		Log.info("test", "--interact on '%s'" % (target.name if target != null else "NOTHING"))
		var press := InputEventAction.new()
		press.action = Actions.INTERACT
		press.pressed = true
		Input.parse_input_event(press)
		await get_tree().physics_frame
		var release := InputEventAction.new()
		release.action = Actions.INTERACT
		release.pressed = false
		Input.parse_input_event(release)
		for _f: int in 20:
			await get_tree().physics_frame
	Log.info("test", "--interact done, keeper standing is %d" % Standing.of(&"keeper"))
func _distance_to_intent(brain: NpcBrain) -> float:
	var markers: Node = _waypoints_node()
	if markers == null:
		return -1.0
	var marker: Node3D = markers.get_node_or_null(
		NodePath(String(brain.current_waypoint()))) as Node3D
	if marker == null:
		return -1.0
	return marker.global_position.distance_to(brain.global_position)


func _waypoints_node() -> Node:
	var area: Node = get_tree().root.find_child("Waypoints", true, false)
	return area


func _all_npcs() -> Array[Node]:
	var out: Array[Node] = []
	var actors: Node = get_tree().root.find_child("Actors", true, false)
	if actors == null:
		return out
	for child: Node in actors.get_children():
		if child is NpcBrain:
			out.append(child)
	return out


## Spawn a crowd and measure. The criterion is that thirty NPCs do not MEASURABLY cost frame
## time, so both numbers are reported and the comparison is left visible rather than asserted
## against a threshold that would be meaningless on another machine.


## Start a game. Since WP-12 the boot sequence goes to the main menu rather than straight into
## an area, which is exactly what makes this a base rather than a demo — but it means a capture
## of the world needs this flag first.
func _new_game() -> void:
	await get_tree().process_frame
	Director.start_new_game()
	Log.info("test", "--new-game requested '%s'" % Director.FIRST_AREA)


## Push menus by name for a capture, innermost last.
##
## Waits for the transition when --new-game is on the same line, because `ScreenKeys` unwinds
## the stack on every travel — a menu pushed before the area lands is closed again by it.
func _open_menu(list: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _fresh_game:
		await _wait_for_area()
	var stack: UiRoot = UiRoot.find(self)
	for menu_id: String in list.split(",", false):
		var screen: UiScreen = ScreenKeys.menu_for(StringName(menu_id))
		if stack == null or screen == null:
			Log.error("test", "--open-menu=%s found no stack or no such menu" % menu_id)
			return
		Log.info("test", "--open-menu %s pushed: %s" % [menu_id, str(stack.open(screen))])
