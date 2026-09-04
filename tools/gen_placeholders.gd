extends SceneTree
## Generates placeholder art procedurally, so the whole game can be built and looked at
## before a single real asset exists.
##
## WHY THIS IS A REAL TOOL AND NOT A HACK
## Art is deliberately deferred on this project. Without stand-ins, every visual system
## (billboarding, sprite lighting, facing, the camera rig, depth of field) would have to be
## written blind and verified later, which is how a rendering bug survives to month three.
## These files are ugly on purpose so nobody mistakes them for finished work.
##
## RUN:  godot_console --headless --script tools/gen_placeholders.gd
## OUT:  assets/placeholder/*.png  (committed, small, regenerable at any time)
##
## Note: this script cannot use the autoloads. A --script run does not create them, so it
## uses print() directly rather than Log. That is the one place in the project where that
## is allowed.

const OUT_DIR: String = "res://assets/placeholder"

# One character cell. 32x48 at a pixel_size of 0.01 gives a figure about 0.48m wide and
# 1.7m tall, which is roughly human against the 1m world grid.
const CELL: Vector2i = Vector2i(32, 48)
const DIRECTIONS: int = 8
const FRAMES: int = 4
## THREE BLOCKS SINCE T5.2: idle, walk, run. The sheet had ONE, because `animation_for` took a
## boolean and there was nowhere for a third to be named - so the template shipped an art
## CONTRACT that could not express the gaits its own controller already had.
const ANIMATIONS: int = 3
const IDLE_BLOCK: int = 0
const WALK_BLOCK: int = 1
const RUN_BLOCK: int = 2
## How far the legs and arms travel in each block. Idle barely moves, a run overreaches -
## these are the numbers that make the three cycles tell themselves apart in a capture.
const BLOCK_SWING: Array[int] = [1, 2, 5]
## And a cloth tint per block, on the ALT sheet's reasoning (gotcha 28): a running figure
## drawn from the walk block is still a person mid-stride, so the BLOCK has to be readable
## rather than judged. This is what turns a gait capture into a checkable prediction.
const BLOCK_TINT: Array[Color] = [
	Color(0.30, 0.45, 0.62), Color(0.24, 0.52, 0.44), Color(0.62, 0.34, 0.30),
]

# Facing order must match GameEnums.Facing exactly:
# SOUTH, SOUTH_EAST, EAST, NORTH_EAST, NORTH, NORTH_WEST, WEST, SOUTH_WEST
const SHOWS_FACE: Array[bool] = [true, true, false, false, false, false, false, true]

# THE SECOND SHEET, and it exists to be a DIFFERENT SHAPE rather than a second character.
# T2.1's headline claim is that a game swaps in a sheet with another cell and frame count and
# edits no code, so the proof needs a sheet that disagrees with the first one on every number:
# 4 facings not 8, a 24x40 cell not 32x48, and 3 frames in each of TWO animation blocks rather
# than 4 frames in one. Its layout is assets/placeholder/character_alt_layout.tres.
#
# EVERY CELL IS SELF-LABELLING, which is the point. A character drawn from the wrong cell still
# looks like a character (gotcha 2, in the one form headless cannot answer), so each cell carries
# a column tally down its left edge and a frame tally along its foot. A windowed capture can then
# be READ rather than judged: three left pips and two foot pips is column 2, frame 1, and no
# amount of plausible-looking pixel art can fake that.
const ALT_CELL: Vector2i = Vector2i(24, 40)
const ALT_DIRECTIONS: int = 4
const ALT_FRAMES: int = 3
const ALT_ANIMATIONS: int = 2
## Idle wears the first colour, walk the second, so which BLOCK is playing reads at a glance.
const ALT_BLOCK_TINT: Array[Color] = [Color(0.28, 0.55, 0.42), Color(0.72, 0.38, 0.22)]
const PIP: Color = Color(1.0, 0.95, 0.35)

const SKIN: Color = Color(0.85, 0.68, 0.52)
const BOOT: Color = Color(0.28, 0.22, 0.18)
const HAIR: Color = Color(0.16, 0.12, 0.10)
const EYE: Color = Color(0.09, 0.09, 0.12)


func _initialize() -> void:
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(OUT_DIR)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		print("FAIL could not create ", OUT_DIR)
		quit(1)
		return

	_save(_build_character_sheet(), "character_placeholder.png")
	_save(_build_alt_sheet(), "character_alt.png")
	_save(_build_grid(256, 32, Color(0.42, 0.44, 0.38), Color(0.36, 0.38, 0.33)), "ground_grid.png")
	_save(_build_grid(128, 16, Color(0.55, 0.52, 0.47), Color(0.47, 0.44, 0.40)), "stone.png")
	_save(_build_noise(128, Color(0.33, 0.42, 0.26), Color(0.24, 0.33, 0.19)), "grass.png")
	_save(_build_noise(128, Color(0.45, 0.33, 0.22), Color(0.36, 0.26, 0.17)), "wood.png")
	_save(_build_marker(64), "marker.png")
	print("OK placeholder art written to ", OUT_DIR)
	quit(0)


## A full gait sheet: 8 facings across, and THREE 4-frame blocks down - idle, walk, run. Rows run
## idle.0-3, walk.0-3, run.0-3, which is the order `frame_index` reads and `SpriteSheetLayout`
## names through `idle_row`, `walk_row` and `run_row`.
func _build_character_sheet() -> Image:
	var rows: int = FRAMES * ANIMATIONS
	var sheet: Image = Image.create(CELL.x * DIRECTIONS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for facing: int in DIRECTIONS:
		for block: int in ANIMATIONS:
			for frame: int in FRAMES:
				var row: int = block * FRAMES + frame
				_draw_figure(sheet, Vector2i(facing * CELL.x, row * CELL.y), facing, frame, block)
	return sheet


## One 32x48 figure. Deliberately simple: a readable silhouette with an obvious front.
func _draw_figure(image: Image, origin: Vector2i, facing: int, frame: int, block: int) -> void:
	# A two-frame leg swing, held for two frames each, so the cycle reads at low framerates. The
	# BLOCK scales how far it travels: a run overreaches, an idle barely shifts its weight.
	var reach: int = BLOCK_SWING[clampi(block, 0, BLOCK_SWING.size() - 1)]
	var swing: int = [0, 1, 0, -1][frame] * reach
	var cloth: Color = BLOCK_TINT[clampi(block, 0, BLOCK_TINT.size() - 1)]
	# A run leans into it, which reads at a glance even before the tint is noticed.
	var lean: int = -1 if block == RUN_BLOCK else 0

	# Legs
	_rect(image, origin + Vector2i(11, 36 + swing), Vector2i(4, 11), BOOT)
	_rect(image, origin + Vector2i(17, 36 - swing), Vector2i(4, 11), BOOT)

	# Torso, slightly narrower at the shoulders than the hips for a bit of shape.
	_rect(image, origin + Vector2i(10 + lean, 20), Vector2i(12, 17), cloth)
	_rect(image, origin + Vector2i(10 + lean, 20), Vector2i(12, 3), cloth.darkened(0.35))

	# Arms swing opposite the legs.
	_rect(image, origin + Vector2i(7 + lean, 22 - swing), Vector2i(3, 12), cloth.darkened(0.35))
	_rect(image, origin + Vector2i(22 + lean, 22 + swing), Vector2i(3, 12), cloth.darkened(0.35))

	# Head and hair
	_disc(image, origin + Vector2i(16 + lean * 2, 13), 7, SKIN)
	_disc(image, origin + Vector2i(16 + lean * 2, 11), 7, HAIR)
	_rect(image, origin + Vector2i(9 + lean * 2, 6), Vector2i(14, 5), HAIR)

	# Eyes only on the facings that show a face, which is what makes the direction readable.
	if SHOWS_FACE[facing]:
		_rect(image, origin + Vector2i(13 + lean * 2, 14), Vector2i(2, 2), EYE)
		_rect(image, origin + Vector2i(18 + lean * 2, 14), Vector2i(2, 2), EYE)

	# A bright shoulder flash on the character's left, so left and right facings differ.
	var flash: Color = Color(0.92, 0.76, 0.35)
	if facing >= 1 and facing <= 3:
		_rect(image, origin + Vector2i(21, 21), Vector2i(4, 4), flash)
	elif facing >= 5 and facing <= 7:
		_rect(image, origin + Vector2i(7, 21), Vector2i(4, 4), flash)


## A grid texture. Reads scale and motion instantly, which is what a placeholder is for.
func _build_grid(size: int, cell: int, base: Color, line: Color) -> Image:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var on_line: bool = (x % cell == 0) or (y % cell == 0)
			image.set_pixel(x, y, line if on_line else base)
	return image


## Deterministic pseudo-noise. No RandomNumberGenerator, so the output is identical every
## run and does not show up as a spurious change in version control.
func _build_noise(size: int, low: Color, high: Color) -> Image:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var h: int = (x * 73856093) ^ (y * 19349663)
			var t: float = float(absi(h) % 1000) / 1000.0
			image.set_pixel(x, y, low.lerp(high, t))
	return image


## A magenta-and-black target, the traditional "this is missing" texture.
func _build_marker(size: int) -> Image:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half: int = size / 2
	for y: int in size:
		for x: int in size:
			var checker: bool = ((x / (half / 2)) + (y / (half / 2))) % 2 == 0
			image.set_pixel(x, y, Color.MAGENTA if checker else Color.BLACK)
	return image


func _rect(image: Image, at: Vector2i, size: Vector2i, color: Color) -> void:
	for y: int in size.y:
		for x: int in size.x:
			_plot(image, at.x + x, at.y + y, color)


func _disc(image: Image, centre: Vector2i, radius: int, color: Color) -> void:
	for y: int in range(-radius, radius + 1):
		for x: int in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				_plot(image, centre.x + x, centre.y + y, color)


func _plot(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, color)


func _save(image: Image, file_name: String) -> void:
	var path: String = "%s/%s" % [OUT_DIR, file_name]
	var err: Error = image.save_png(path)
	if err == OK:
		print("  wrote %-30s %dx%d" % [file_name, image.get_width(), image.get_height()])
	else:
		print("  FAILED %s: %s" % [file_name, error_string(err)])


## The second sheet: 4 facings across, and 3 frames down in each of 2 animation blocks, so the
## rows run idle.0 idle.1 idle.2 walk.0 walk.1 walk.2. See ALT_CELL for why it exists.
func _build_alt_sheet() -> Image:
	var rows: int = ALT_FRAMES * ALT_ANIMATIONS
	var sheet: Image = Image.create(
		ALT_CELL.x * ALT_DIRECTIONS, ALT_CELL.y * rows, false, Image.FORMAT_RGBA8
	)
	sheet.fill(Color(0, 0, 0, 0))
	for column: int in ALT_DIRECTIONS:
		for row: int in rows:
			var origin: Vector2i = Vector2i(column * ALT_CELL.x, row * ALT_CELL.y)
			_draw_alt_cell(sheet, origin, column, row / ALT_FRAMES, row % ALT_FRAMES)
	return sheet


## One labelled figure. Simple on purpose: a readable body, an animation tint, and the two pip
## tallies that let a capture be read rather than believed.
func _draw_alt_cell(image: Image, origin: Vector2i, column: int, block: int, frame: int) -> void:
	var tint: Color = ALT_BLOCK_TINT[block]
	# Idle bobs by a pixel; walk swings its legs. Two visibly different cycles.
	var bob: int = 0 if block == 1 else [0, 1, 0][frame]
	var swing: int = [0, 2, -2][frame] if block == 1 else 0

	_rect(image, origin + Vector2i(9, 28 + swing), Vector2i(3, 9), BOOT)
	_rect(image, origin + Vector2i(13, 28 - swing), Vector2i(3, 9), BOOT)
	_rect(image, origin + Vector2i(8, 14 + bob), Vector2i(9, 15), tint)
	_disc(image, origin + Vector2i(12, 9 + bob), 5, SKIN)
	_rect(image, origin + Vector2i(7, 3 + bob), Vector2i(11, 4), HAIR)
	# Eyes only on column 0, which is towards the camera in a four-facing sheet.
	if column == 0:
		_rect(image, origin + Vector2i(10, 9 + bob), Vector2i(2, 2), EYE)
		_rect(image, origin + Vector2i(14, 9 + bob), Vector2i(2, 2), EYE)

	# column + 1 pips down the left edge, frame + 1 pips along the foot.
	for pip: int in column + 1:
		_rect(image, origin + Vector2i(1, 2 + pip * 4), Vector2i(2, 2), PIP)
	for pip: int in frame + 1:
		_rect(image, origin + Vector2i(2 + pip * 4, ALT_CELL.y - 3), Vector2i(2, 2), PIP)
