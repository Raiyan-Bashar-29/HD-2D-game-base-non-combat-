class_name CharacterVisual
extends Node3D
## Turns movement into a billboarded, lit, correctly-sorted sprite. Used by the player and
## by every NPC, unchanged.
##
## THE SPRITE3D SETTINGS THAT MATTER, and why each one is what it is:
##
##   billboard = BILLBOARD_FIXED_Y
##       Rotates to face the camera around the Y axis only. Full BILLBOARD_ENABLED also
##       tips the sprite back as the camera pitches down, so a character standing on flat
##       ground appears to lean. Fixed-Y keeps them upright.
##
##   alpha_cut = ALPHA_CUT_DISCARD
##       This is the important one. With alpha blending, a sprite writes no depth, so it
##       cannot sort against other transparent things and casts no shadow. Discarding
##       transparent pixels instead makes the sprite opaque geometry: it sorts by depth
##       correctly, occludes properly, and casts a real shadow. The cost is no soft edges,
##       which is exactly right for pixel art.
##
##   texture_filter = TEXTURE_FILTER_NEAREST
##       Keeps pixels crisp. Linear filtering turns pixel art into mush at this scale.
##
##   shaded = true
##       Makes the sprite respond to lights, so a character walking under a lantern at
##       night is actually lit by it. Without this the day/night cycle would not touch
##       characters and they would look pasted on.
##
## THE SHEET'S DIMENSIONS ARE NOT IN THIS FILE. They are a `SpriteSheetLayout` resource on the
## `layout` @export, and every number that depends on them — hframes, vframes, the foot offset,
## the frame wrap, the direction sectors — is read from it. See that class for the grid.
##
## OWNS: the sprite, its facing, its sheet column, and its animation frame.
## MUST NOT: read input, move the character, contain game rules, or hold any sheet dimension of
## its own. It is told a velocity and a state, and it draws.

## The layout assumed when the @export below is unwired. Not a fallback anybody should rely on:
## it exists so an unwired node draws a recognisable character while the log says it is unwired,
## because gotcha 2's whole lesson is that a silent default looks exactly like success.
const DEFAULT_FACINGS: int = 8
const DEFAULT_FRAMES: int = 4
const DEFAULT_CELL: Vector2i = Vector2i(32, 48)

## How this character's sheet is cut up, as authored data. THE ART CONTRACT SEAM: until T2.1 this
## was `FACING_COUNT = 8` and `FRAME_COUNT = 4` as constants right here, so a game whose sheet had
## four facings and six frames needed a code edit — the one thing a template must never ask for.
@export var layout: SpriteSheetLayout = null

@export var texture: Texture2D = null
## World size of one texture pixel. 0.01 makes a 48px-tall sprite 0.48m... too small for a
## person, so the default is tuned so a 48px figure is about 1.7m.
@export var pixel_size: float = 0.035
## How many sheet frames per second at full walking speed.
@export var walk_fps: float = 8.0
## Movement speed treated as "full walk" for animation timing.
@export var reference_speed: float = 3.2
## Lifts the sprite so its feet sit on the ground rather than its centre.
@export var ground_offset: float = 0.0

var sprite: Sprite3D = null

var _layout: SpriteSheetLayout = null
var _facing: GameEnums.Facing = GameEnums.Facing.SOUTH
## The sheet COLUMN. Deliberately NOT derived from _facing: the enum is how many directions the
## GAME reasons about, `layout.facings` is how many the ART distinguishes, and mapping one onto
## the other would put the sector width back in two places that have to agree by hand.
var _column: int = 0
var _frame_time: float = 0.0
var _frame: int = 0
var _moving: bool = false
## WHAT THE CHARACTER IS DOING, which decides which animation BLOCK is drawn while `_moving`
## decides whether the block advances. The two were one boolean until T5.2, which is why a
## running character replayed the walk cycle faster and a sheet had nowhere to put a run.
## Pushed in by whoever drives this visual - never read from `Events.player_state_changed`,
## because every NPC uses this class and none of them is the player.
var _state: GameEnums.MoveState = GameEnums.MoveState.IDLE


func _ready() -> void:
	_layout = _resolved_layout()
	sprite = get_node_or_null(^"Sprite3D") as Sprite3D
	if sprite == null:
		sprite = Sprite3D.new()
		sprite.name = "Sprite3D"
		add_child(sprite)
	_configure_sprite()


func _configure_sprite() -> void:
	if texture != null:
		sprite.texture = texture
	sprite.hframes = _layout.facings
	sprite.vframes = _layout.sheet_rows()
	for problem: String in _layout.problems(sprite.texture):
		Log.warn("world", "%s: %s" % [name, problem])
	sprite.pixel_size = pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = true
	sprite.double_sided = true
	# Anchor the sprite by its feet. The sprite stays centred and is lifted by half its
	# height, so the node origin sits on the ground where the collision capsule does.
	sprite.centered = true
	sprite.offset = Vector2(0.0, float(_layout.cell_size.y) * 0.5)
	sprite.position = Vector3(0.0, ground_offset, 0.0)
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_apply_frame()


## Called every physics frame by whatever drives this character.
## `velocity` is world-space; only the horizontal part is used.
## `state` defaults to WALK so a caller that has not been updated behaves exactly as before:
## moving draws the walk block, standing still draws the idle one.
func update_from_velocity(velocity: Vector3, delta: float,
		state: GameEnums.MoveState = GameEnums.MoveState.WALK) -> void:
	var flat: Vector2 = Vector2(velocity.x, velocity.z)
	var speed: float = flat.length()
	_moving = speed > 0.05
	# A state that is not moving is IDLE whatever the caller said, so a character held still by
	# a dialogue box does not stand there playing its run cycle in place. CLIMB is the exception
	# and is deliberate: an authored climb writes `global_position` and leaves velocity at zero,
	# so it must be believed rather than derived.
	_state = state if _moving or state == GameEnums.MoveState.CLIMB else GameEnums.MoveState.IDLE

	if _moving:
		_aim(flat)
		var rate: float = walk_fps * clampf(speed / maxf(0.01, reference_speed), 0.35, 2.0)
		_frame_time += delta * rate
		while _frame_time >= 1.0:
			_frame_time -= 1.0
			_frame = (_frame + 1) % _layout.frames
	else:
		# Settle on the neutral pose rather than freezing mid-stride.
		_frame = 0
		_frame_time = 0.0
	_apply_frame()


## Face a direction without moving, for dialogue and scripted moments.
func face_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.0001:
		return
	_aim(direction)
	_apply_frame()


func facing() -> GameEnums.Facing:
	return _facing


## Map a world-space XZ direction to a GameEnums.Facing, corrected for camera yaw so that
## "towards the camera" is always the front-facing value even if an area frames its camera from
## a different angle. Sector 0 is towards the camera, matching Facing.SOUTH.
##
## THE SECTOR COUNT COMES FROM THE ENUM, never from a literal, for exactly the reason the
## column's comes from the layout: `TAU / 8.0` sitting beside a separate `8` is two places
## holding one number, and this file used to have both.
func facing_from_direction(direction: Vector2) -> GameEnums.Facing:
	var count: int = GameEnums.Facing.size()
	var sector: int = roundi(_screen_angle(direction) / (TAU / float(count)))
	return posmod(sector, count) as GameEnums.Facing


## Which sheet column a direction draws. The layout owns the quantisation because it owns the
## facing count; this is the only caller that needs the answer.
func column_from_direction(direction: Vector2) -> int:
	return _layout.column_for_angle(_screen_angle(direction))


## Set the enum value and the column together, so the two cannot drift apart by one being
## updated at a call site and the other forgotten.
func _aim(direction: Vector2) -> void:
	_facing = facing_from_direction(direction)
	_column = column_from_direction(direction)


func _screen_angle(direction: Vector2) -> float:
	return atan2(direction.x, direction.y) - _camera_yaw()


## The layout to draw with. Unwired is legal and LOUD: an unwired @export renders something
## plausible and says nothing, which is the whole of gotcha 2, so this one says something.
func _resolved_layout() -> SpriteSheetLayout:
	if layout != null:
		return layout
	var assumed := SpriteSheetLayout.new()
	assumed.facings = DEFAULT_FACINGS
	assumed.frames = DEFAULT_FRAMES
	assumed.cell_size = DEFAULT_CELL
	Log.warn("world", "%s has no SpriteSheetLayout; assuming %d facings x %d frames" % [
		name, assumed.facings, assumed.frames,
	])
	return assumed


func _camera_yaw() -> float:
	var view: Viewport = get_viewport()
	if view == null:
		return 0.0
	var active: Camera3D = view.get_camera_3d()
	if active == null:
		return 0.0
	return active.global_rotation.y


func _apply_frame() -> void:
	if sprite == null or _layout == null:
		return
	sprite.frame = _layout.frame_index(_column, _frame, _layout.animation_for(_state))


## Diagnostic for the dev capture tool. Cheap, and the first thing worth knowing when a
## character does not appear on screen.
func describe() -> String:
	if sprite == null:
		return "no sprite"
	return "sprite visible=%s frame=%d/%d pos=%s size_px=%s" % [
		str(sprite.visible), sprite.frame, sprite.hframes * sprite.vframes,
		str(sprite.global_position), str(sprite.texture.get_size() if sprite.texture else Vector2.ZERO),
	]
