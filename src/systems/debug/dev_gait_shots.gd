extends Node
## Photographs a character in every gait its sheet declares. The fourth debug file, and it
## exists because Phase T5's last exit criterion is a PICTURE.
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
##   --gait-shots=<dir>   drive the player through idle, walk, run, sneak and climb through
##                        the real input path, and for each one write <dir>/gait_<name>.png,
##                        a x5 nearest-neighbour crop beside it, and a log line decoding the
##                        block, column and cell out of sprite.frame.
##
## READ THE LOG AND THE PICTURE TOGETHER, because neither is sufficient. A sprite drawn from the
## wrong cell is still a person (gotcha 28), so the photograph alone proves nothing about WHICH
## cell; and --headless shades nothing (gotcha 2), so the decoded number alone proves nothing
## about whether it reached a screen. The alt placeholder sheet carries three pip tallies for
## exactly this reason: the number in the log and the pips in the image have to agree.
##
## OWNS: driving a character through its gaits and capturing each.
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

var _dir: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--gait-shots="):
			_dir = argument.trim_prefix("--gait-shots=")
			_run()


func _run() -> void:
	while Director.current_area_id == &"":
		await get_tree().process_frame
	for _i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	var player: PlayerController = get_tree().root.find_child("Player", true, false)
	if player == null:
		Log.error("test", "--gait-shots found no Player")
		return
	DirAccess.make_dir_recursive_absolute(_dir)
	var home: Vector3 = player.global_position
	for gait: GameEnums.MoveState in GAITS:
		await _one(player, gait, home)
	Log.info("test", "--gait-shots done")


func _one(player: PlayerController, gait: GameEnums.MoveState, home: Vector3) -> void:
	player.global_position = home
	_press(gait, true)
	if gait == GameEnums.MoveState.CLIMB:
		player.begin_climb(home + Vector3(0.0, CLIMB_HEIGHT, 0.0))
	for _i: int in HOLD_FRAMES:
		await get_tree().physics_frame
	# THE NUMBER AND THE PICTURE MUST COME FROM THE SAME FRAME. Reading sprite.frame BEFORE the
	# post-draw await put a physics step between them, so the log said cellframe 2 while the
	# photograph showed one foot pip - two honest measurements of two different moments, which
	# reads exactly like the sheet being wrong.
	await RenderingServer.frame_post_draw
	var shot: Image = get_viewport().get_texture().get_image()
	var layout: SpriteSheetLayout = player.visual.layout
	var cell: int = player.visual.sprite.frame
	Log.info("test", "gait %s: %s block=%d column=%d cellframe=%d" % [
		str(GameEnums.MoveState.keys()[gait]), player.visual.describe(),
		(cell / layout.facings) / layout.frames,
		cell % layout.facings, (cell / layout.facings) % layout.frames,
	])
	var label: String = str(GameEnums.MoveState.keys()[gait]).to_lower()
	shot.save_png("%s/gait_%s.png" % [_dir, label])
	_zoom(shot, player).save_png("%s/gait_%s_zoom.png" % [_dir, label])
	_press(gait, false)


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
		var event := InputEventAction.new()
		event.action = action
		event.pressed = down
		Input.parse_input_event(event)
