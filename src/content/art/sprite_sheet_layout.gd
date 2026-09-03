class_name SpriteSheetLayout
extends Resource
## How a character sprite sheet is cut up, as authored data. The art CONTRACT this template
## ships, and the reason a game with a different sheet edits no code.
##
## WHY THIS EXISTS. CharacterVisual used to carry `FACING_COUNT = 8` and `FRAME_COUNT = 4` as
## constants, and the eight-way sector maths as a SEPARATE literal `TAU / 8.0` that had to agree
## with the first by hand. Two places holding one number is a bug waiting for the first game whose
## sheet has four facings. Here the count appears once and the sector width is DERIVED from it, so
## the two cannot disagree.
##
## THE SHEET IS COLUMNS OF FACING BY ROWS OF FRAME, and the rows are grouped into ANIMATIONS:
##
##     facings = 4, frames = 3, animations = 2, idle_row = 0, walk_row = 1
##
##             col 0    col 1    col 2    col 3
##     row 0   idle.0   idle.0   idle.0   idle.0     <- animation 0 (idle), frame 0
##     row 1   idle.1   ...                          <- animation 0, frame 1
##     row 2   idle.2   ...                          <- animation 0, frame 2
##     row 3   walk.0   ...                          <- animation 1 (walk), frame 0
##     row 4   walk.1   ...
##     row 5   walk.2   ...
##
## So `sheet_rows()` is `frames * animations`, and an animation is addressed by its INDEX, not by
## its first row — an author who moves the walk block down does not have to recount.
## `animations = 1` with both rows at 0 is the single-block sheet this project shipped before
## T2.1, which is why every existing sheet keeps working unchanged.
##
## A FACING IS NOT A COLUMN. `GameEnums.Facing` has eight values because that is what the GAME
## reasons about — which way a character is turned. How many of those the ART distinguishes is a
## separate question this resource answers, and `column_for_angle` answers it by quantising the
## angle into `facings` sectors rather than by mapping down from eight.
##
## OWNS: the dimensions of one sheet, and validating them against the texture.
## MUST NOT: hold a texture, touch a node, know what animation a character is playing, or touch
## an autoload — tools/ loads content classes under `--script`, where autoload identifiers do not
## resolve, so a single `Log` call here would break a build gate.

## Cells across: how many directions the art distinguishes. The sector width is derived from
## this and nothing else.
@export_range(1, 32, 1) var facings: int = 8
## Cells down within ONE animation: the length of its cycle.
@export_range(1, 64, 1) var frames: int = 4
## How many animation blocks are stacked down the sheet. 1 is a sheet with a single cycle.
@export_range(1, 32, 1) var animations: int = 1
## One cell in texture pixels. DECLARED rather than divided out of the texture, so a sheet of the
## wrong size is a named problem instead of every character in the game silently misplaced.
@export var cell_size: Vector2i = Vector2i(32, 48)
## Which animation block plays when standing still, and which when moving. Equal values mean the
## sheet has no separate idle, which is legal and was the only possibility before T2.1.
@export_range(0, 31, 1) var idle_row: int = 0
@export_range(0, 31, 1) var walk_row: int = 0


## Total rows down the sheet. Derived: an author sets the cycle length and the block count.
func sheet_rows() -> int:
	return frames * animations


## The whole sheet in texture pixels, for validating a texture against this layout.
func sheet_size() -> Vector2i:
	return Vector2i(cell_size.x * facings, cell_size.y * sheet_rows())


## Width of one direction sector in radians. THE derivation — one number, one place.
func sector_radians() -> float:
	return TAU / float(facings)


## Quantise an angle (0 = towards the camera, increasing clockwise) into a sheet column.
func column_for_angle(angle: float) -> int:
	return posmod(roundi(angle / sector_radians()), facings)


## Which animation block a state plays. Clamped rather than trusted: a layout whose walk_row
## points past the end of the sheet should draw the last block, not an out-of-range cell.
func animation_for(moving: bool) -> int:
	return clampi(walk_row if moving else idle_row, 0, animations - 1)


## The Sprite3D `frame` for one cell. Sprite3D numbers cells left to right, then top to bottom,
## so the row has to be multiplied by the column count and not by anything else.
func frame_index(column: int, frame: int, animation: int) -> int:
	var row: int = clampi(animation, 0, animations - 1) * frames + posmod(frame, frames)
	return row * facings + posmod(column, facings)


## Everything wrong with this layout, as data rather than a log line, so the same check serves
## the game, the test suite and a headless validator. `texture` may be null: a layout is valid
## on its own, and only a MISMATCH is a problem.
func problems(texture: Texture2D = null) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	if cell_size.x <= 0 or cell_size.y <= 0:
		found.append("%s declares a cell of %s, which has no area" % [resource_path, cell_size])
	if idle_row >= animations or walk_row >= animations:
		found.append("%s names row %d/%d past its %d animation(s)" % [
			resource_path, idle_row, walk_row, animations,
		])
	if texture != null and Vector2i(texture.get_size()) != sheet_size():
		found.append("%s expects a %s sheet; the texture is %s" % [
			resource_path, sheet_size(), Vector2i(texture.get_size()),
		])
	return found
