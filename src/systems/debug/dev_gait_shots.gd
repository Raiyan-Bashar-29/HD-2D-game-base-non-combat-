extends Node
## Photographs a character in every gait its sheet declares, and - since T5.8 - in every
## DIRECTION it can walk. The fourth debug file, and it exists because Phase T5.s last exit
## criterion is a PICTURE.
##
## WHY A FOURTH FILE RATHER THAN A FLAG ON dev_stage.gd
## The other three each answer one question - `dev_capture.gd` "what does this LOOK like",
## `dev_probes.gd` "does this sequence work", `dev_stage.gd` "put the world in that state" -
## and a gait capture needs all three at once, per gait, five times in one run. It also owns a
## fact none of them has: WHEN to open the shutter. A gait has no still moment to aim a frame
## number at (gotcha 52), so this waits until the character is actually in the gait and shoots
## then, rather than guessing a frame and hoping the area had loaded.
##
## AUTOMATED USE - everything after the bare `--` is passed to the game:
##   godot_console --resolution 960x540 --quit-after 600 -- --new-game --freeze-time \
##       --gait-shots=<dir>
##
##   --gait-shots=<dir>     drive the player through idle, walk, run, sneak and climb through
##                          the real input path, and for each one write <dir>/gait_<name>.png,
##                          a x5 nearest-neighbour crop beside it, and a log line decoding the
##                          block, column and cell out of sprite.frame.
##   --facing-shots=<dir>   walk the player north, east, south and west and photograph each,
##                          same shutter and same decode, into <dir>/facing_<name>.png.
##
## WHY THE FACING PASS IS HERE AND NOT IN A FIFTH FILE. It is the same shutter problem with the
## other axis substituted: hold a real key, wait for the character to be actually doing it, then
## read the number and the picture in the same frame. Everything a facing capture needs -
## SETTLE_FRAMES, HOLD_FRAMES, the post-draw await of gotcha 59, the logical-size crop of
## gotcha 60 - is already here and would have been copied verbatim. What the split would have
## bought is a more accurate FILE NAME, which is not worth four duplicated gotchas.
##
## T5.6 RECORDED THE ABSENCE AS ITS OWN GAP: every capture this project had ever taken was of
## column 0 or column 1, so the facing system had never been photographed at all - and when it
## finally was, the sheet turned out to draw one pose eight times (T5.8).
##
## READ THE LOG AND THE PICTURE TOGETHER, because neither is sufficient. A sprite drawn from the
## wrong cell is still a person (gotcha 28), so the photograph alone proves nothing about WHICH
## cell; and --headless shades nothing (gotcha 2), so the decoded number alone proves nothing
## about whether it reached a screen. The alt placeholder sheet carries three pip tallies for
## exactly this reason: the number in the log and the pips in the image have to agree.
##
## OWNS: driving a character through its gaits and its facings, and capturing each.
## MUST NOT: be depended upon by gameplay, pose a velocity or a sprite frame by hand, or know
## anything about a particular sheet. It presses the keys a player presses and reads what the
## game drew. Deleting this file must not break the game.

const GAITS: Array[GameEnums.MoveState] = [
	GameEnums.MoveState.IDLE, GameEnums.MoveState.WALK, GameEnums.MoveState.RUN,
	GameEnums.MoveState.SNEAK, GameEnums.MoveState.CLIMB,
]
## Physics frames to hold a gait before shooting. Long enough for acceleration to reach the
## gait's real speed and for the cycle to leave cell 0, short enough that the player is still
## in shot - at run speed they clear the courtyard in about a second.
const HOLD_FRAMES: int = 22
## How far up an authored climb this probe lifts the player. A ladder, not a flight.
const CLIMB_HEIGHT: float = 2.2
## Frames to let the boot transition settle before the first gait. Same wait every probe in
## this project opens with, and for the same reason: gotcha 9.
const SETTLE_FRAMES: int = 30
## The four directions the facing pass walks, named by the SCREEN. Which sheet column each one
## reaches depends on the camera's yaw and is deliberately not assumed here - it is read out of
## `sprite.frame` and logged, so the picture and the number can be checked against each other.
const COMPASS: Array[StringName] = [&"north", &"east", &"south", &"west"]

var _dir: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--gait-shots="):
			_dir = argument.trim_prefix("--gait-shots=")
			_run()
		elif argument.begins_with("--facing-shots="):
			_dir = argument.trim_prefix("--facing-shots=")
			_run_facings()


func _run() -> void:
	var player: PlayerController = await _wait_for_player()
	if player == null:
		return
	var home: Vector3 = player.global_position
	for gait: GameEnums.MoveState in GAITS:
		await _one(player, gait, home)
	Log.info("test", "--gait-shots done")


## THE SAME CHARACTER WALKING NORTH, EAST, SOUTH AND WEST, which nothing in this repository had
## ever photographed before T5.8 - every capture ever taken was of column 0 or column 1. The
## directions are pressed as KEYS and named by the screen, because that is what an owner watching
## the game sees; which sheet COLUMN each one reaches is the decoded number in the log, and the
## two together are the claim.
func _run_facings() -> void:
	var player: PlayerController = await _wait_for_player()
	if player == null:
		return
	var home: Vector3 = player.global_position
	for compass: StringName in COMPASS:
		player.global_position = home
		var action: StringName = _compass_action(compass)
		_hold(action, true)
		for _i: int in HOLD_FRAMES:
			await get_tree().physics_frame
		await _shoot(player, "facing_%s" % compass)
		_hold(action, false)
	Log.info("test", "--facing-shots done")


## The wait every probe in this file opens with, and the player it found. Null means the run has
## already logged why, so a caller only has to stop.
func _wait_for_player() -> PlayerController:
	while Director.current_area_id == &"":
		await get_tree().process_frame
	for _i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	var player: PlayerController = get_tree().root.find_child("Player", true, false)
	if player == null:
		Log.error("test", "%s found no Player" % _dir)
		return null
	DirAccess.make_dir_recursive_absolute(_dir)
	return player


func _one(player: PlayerController, gait: GameEnums.MoveState, home: Vector3) -> void:
	player.global_position = home
	_press(gait, true)
	if gait == GameEnums.MoveState.CLIMB:
		player.begin_climb(home + Vector3(0.0, CLIMB_HEIGHT, 0.0))
	for _i: int in HOLD_FRAMES:
		await get_tree().physics_frame
	await _shoot(player, "gait_%s" % str(GameEnums.MoveState.keys()[gait]).to_lower())
	_press(gait, false)


## The shutter, and the one thing this file owns that no other debug file does.
##
## THE NUMBER AND THE PICTURE MUST COME FROM THE SAME FRAME. Reading sprite.frame BEFORE the
## post-draw await put a physics step between them, so the log said cellframe 2 while the
## photograph showed one foot pip - two honest measurements of two different moments, which
## reads exactly like the sheet being wrong.
func _shoot(player: PlayerController, label: String) -> void:
	await RenderingServer.frame_post_draw
	var shot: Image = get_viewport().get_texture().get_image()
	var layout: SpriteSheetLayout = player.visual.layout
	var cell: int = player.visual.sprite.frame
	Log.info("test", "%s: %s block=%d column=%d cellframe=%d" % [
		label, player.visual.describe(), (cell / layout.facings) / layout.frames,
		cell % layout.facings, (cell / layout.facings) % layout.frames,
	])
	shot.save_png("%s/%s.png" % [_dir, label])
	_zoom(shot, player).save_png("%s/%s_zoom.png" % [_dir, label])


## Screen north, east, south and west as the action a player holds. A function rather than a
## const table because `Actions` is an autoload, and an autoload identifier does not resolve in
## a const initialiser.
func _compass_action(compass: StringName) -> StringName:
	match compass:
		&"north":
			return Actions.MOVE_UP
		&"east":
			return Actions.MOVE_RIGHT
		&"south":
			return Actions.MOVE_DOWN
	return Actions.MOVE_LEFT


func _hold(action: StringName, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)


## The pips are two screen pixels wide at this framing, so the full capture proves the swap and
## this proves the CELL. Nearest-neighbour, because a smoothed pip cannot be counted.
##
## `unproject_position` ANSWERS IN THE VIEWPORT'S LOGICAL SIZE, NOT IN WINDOW PIXELS. The
## project scales content from 1920x1080, so at a --resolution of 960x540 every unprojected
## point came back at exactly twice its place in the captured image and the first five crops
## were photographs of grass. Scale by the ratio the shot itself reports rather than by a
## number, or the crop is right at one resolution and silently wrong at every other.
func _zoom(shot: Image, player: PlayerController) -> Image:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var logical: Vector2 = camera.get_viewport().get_visible_rect().size
	var scale: Vector2 = Vector2(shot.get_size()) / logical
	var at: Vector2i = Vector2i(camera.unproject_position(
		player.global_position + Vector3(0.0, 0.75, 0.0)) * scale)
	var box: Rect2i = Rect2i(at - Vector2i(45, 55), Vector2i(90, 110))
	var crop: Image = shot.get_region(box.intersection(Rect2i(Vector2i.ZERO, shot.get_size())))
	crop.resize(crop.get_width() * 5, crop.get_height() * 5, Image.INTERPOLATE_NEAREST)
	return crop


## Real input, through Input.parse_input_event, because a probe that posed the velocity by hand
## would photograph a mock. A climb is the exception and goes through begin_climb(), which is
## the same public call ClimbPoint makes.
func _press(gait: GameEnums.MoveState, down: bool) -> void:
	var held: Array[StringName] = []
	match gait:
		GameEnums.MoveState.WALK:
			held = [Actions.MOVE_RIGHT]
		GameEnums.MoveState.RUN:
			held = [Actions.MOVE_RIGHT, Actions.RUN]
		GameEnums.MoveState.SNEAK:
			held = [Actions.MOVE_RIGHT, Actions.SNEAK]
	for action: StringName in held:
		_hold(action, down)
