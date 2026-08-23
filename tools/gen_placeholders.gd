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

# Facing order must match GameEnums.Facing exactly:
# SOUTH, SOUTH_EAST, EAST, NORTH_EAST, NORTH, NORTH_WEST, WEST, SOUTH_WEST
const SHOWS_FACE: Array[bool] = [true, true, false, false, false, false, false, true]

const SKIN: Color = Color(0.85, 0.68, 0.52)
const CLOTH: Color = Color(0.30, 0.45, 0.62)
const CLOTH_DARK: Color = Color(0.20, 0.31, 0.44)
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
	_save(_build_grid(256, 32, Color(0.42, 0.44, 0.38), Color(0.36, 0.38, 0.33)), "ground_grid.png")
	_save(_build_grid(128, 16, Color(0.55, 0.52, 0.47), Color(0.47, 0.44, 0.40)), "stone.png")
	_save(_build_noise(128, Color(0.33, 0.42, 0.26), Color(0.24, 0.33, 0.19)), "grass.png")
	_save(_build_noise(128, Color(0.45, 0.33, 0.22), Color(0.36, 0.26, 0.17)), "wood.png")
	_save(_build_marker(64), "marker.png")
	print("OK placeholder art written to ", OUT_DIR)
	quit(0)


## A full walk sheet: 8 facings across, 4 frames down.
func _build_character_sheet() -> Image:
	var sheet: Image = Image.create(CELL.x * DIRECTIONS, CELL.y * FRAMES, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for facing: int in DIRECTIONS:
		for frame: int in FRAMES:
			_draw_figure(sheet, Vector2i(facing * CELL.x, frame * CELL.y), facing, frame)
	return sheet


## One 32x48 figure. Deliberately simple: a readable silhouette with an obvious front.
func _draw_figure(image: Image, origin: Vector2i, facing: int, frame: int) -> void:
	# A two-frame leg swing, held for two frames each, so the cycle reads at low framerates.
	var swing: int = [0, 1, 0, -1][frame]

	# Legs
	_rect(image, origin + Vector2i(11, 36 + swing), Vector2i(4, 11), BOOT)
	_rect(image, origin + Vector2i(17, 36 - swing), Vector2i(4, 11), BOOT)

	# Torso, slightly narrower at the shoulders than the hips for a bit of shape.
	_rect(image, origin + Vector2i(10, 20), Vector2i(12, 17), CLOTH)
	_rect(image, origin + Vector2i(10, 20), Vector2i(12, 3), CLOTH_DARK)

	# Arms swing opposite the legs.
	_rect(image, origin + Vector2i(7, 22 - swing), Vector2i(3, 12), CLOTH_DARK)
	_rect(image, origin + Vector2i(22, 22 + swing), Vector2i(3, 12), CLOTH_DARK)

	# Head and hair
	_disc(image, origin + Vector2i(16, 13), 7, SKIN)
	_disc(image, origin + Vector2i(16, 11), 7, HAIR)
	_rect(image, origin + Vector2i(9, 6), Vector2i(14, 5), HAIR)

	# Eyes only on the facings that show a face, which is what makes the direction readable.
	if SHOWS_FACE[facing]:
		_rect(image, origin + Vector2i(13, 14), Vector2i(2, 2), EYE)
		_rect(image, origin + Vector2i(18, 14), Vector2i(2, 2), EYE)

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
