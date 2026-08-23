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
## OWNS: the sprite, its facing, and its animation frame.
## MUST NOT: read input, move the character, or contain game rules. It is told a velocity
## and a state, and it draws.

## Cells across the sheet: one per facing, in GameEnums.Facing order.
const FACING_COUNT: int = 8
## Rows down the sheet: the walk cycle.
const FRAME_COUNT: int = 4

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

var _facing: GameEnums.Facing = GameEnums.Facing.SOUTH
var _frame_time: float = 0.0
var _frame: int = 0
var _moving: bool = false


func _ready() -> void:
	sprite = get_node_or_null(^"Sprite3D") as Sprite3D
	if sprite == null:
		sprite = Sprite3D.new()
		sprite.name = "Sprite3D"
		add_child(sprite)
	_configure_sprite()


func _configure_sprite() -> void:
	if texture != null:
		sprite.texture = texture
	sprite.hframes = FACING_COUNT
	sprite.vframes = FRAME_COUNT
	sprite.pixel_size = pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = true
	sprite.double_sided = true
	# Anchor the sprite by its feet. The sprite stays centred and is lifted by half its
	# height, so the node origin sits on the ground where the collision capsule does.
	sprite.centered = true
	sprite.offset = Vector2(0.0, float(_cell_height()) * 0.5)
	sprite.position = Vector3(0.0, ground_offset, 0.0)
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_apply_frame()


## Called every physics frame by whatever drives this character.
## `velocity` is world-space; only the horizontal part is used.
func update_from_velocity(velocity: Vector3, delta: float) -> void:
	var flat: Vector2 = Vector2(velocity.x, velocity.z)
	var speed: float = flat.length()
	_moving = speed > 0.05

	if _moving:
		_facing = facing_from_direction(flat)
		var rate: float = walk_fps * clampf(speed / maxf(0.01, reference_speed), 0.35, 2.0)
		_frame_time += delta * rate
		while _frame_time >= 1.0:
			_frame_time -= 1.0
			_frame = (_frame + 1) % FRAME_COUNT
	else:
		# Settle on the neutral pose rather than freezing mid-stride.
		_frame = 0
		_frame_time = 0.0
	_apply_frame()


## Face a direction without moving, for dialogue and scripted moments.
func face_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.0001:
		return
	_facing = facing_from_direction(direction)
	_apply_frame()


func facing() -> GameEnums.Facing:
	return _facing


## Map a world-space XZ direction to a sheet column, corrected for camera yaw so that
## "towards the camera" is always the front-facing cell even if an area frames its camera
## from a different angle.
func facing_from_direction(direction: Vector2) -> GameEnums.Facing:
	var angle: float = atan2(direction.x, direction.y) - _camera_yaw()
	# Eight sectors of 45 degrees. Sector 0 is towards the camera, matching Facing.SOUTH.
	var sector: int = roundi(angle / (TAU / 8.0))
	return posmod(sector, FACING_COUNT) as GameEnums.Facing


func _camera_yaw() -> float:
	var view: Viewport = get_viewport()
	if view == null:
		return 0.0
	var active: Camera3D = view.get_camera_3d()
	if active == null:
		return 0.0
	return active.global_rotation.y


func _apply_frame() -> void:
	if sprite == null:
		return
	sprite.frame = _frame * FACING_COUNT + int(_facing)


## Height of one sheet cell in texture pixels, derived rather than hard-coded so a
## different sheet size does not silently misplace every character in the game.
func _cell_height() -> int:
	if sprite == null or sprite.texture == null:
		return 48
	return sprite.texture.get_height() / FRAME_COUNT


## Diagnostic for the dev capture tool. Cheap, and the first thing worth knowing when a
## character does not appear on screen.
func describe() -> String:
	if sprite == null:
		return "no sprite"
	return "sprite visible=%s frame=%d/%d pos=%s size_px=%s" % [
		str(sprite.visible), sprite.frame, sprite.hframes * sprite.vframes,
		str(sprite.global_position), str(sprite.texture.get_size() if sprite.texture else Vector2.ZERO),
	]
