class_name HD2DCameraRig
extends Node3D
## The diorama camera. This node, and its numbers, are most of the HD-2D look.
##
## WHAT MAKES THE LOOK, in order of importance:
##   1. A LONG LENS. A low FOV from far away flattens perspective, so the world reads as a
##      handmade model rather than a space you are standing in. This matters more than any
##      post-processing effect. 25-30 degrees at 12-16 metres is the range.
##   2. A FIXED PITCH. The camera never orbits. Around -32 degrees shows the tops of things
##      and keeps sprites upright and readable.
##   3. TILT-SHIFT DEPTH OF FIELD. Blurring both nearer and further than the character is
##      what sells "miniature". Blurring only the distance just looks like fog.
##   4. Smoothed following, with the character sitting slightly low in frame.
##
## OWNS: camera placement, framing and its depth-of-field attributes.
## MUST NOT: read input, or know what it is following beyond a Node3D target. It does not
## know the player exists; it is handed a target.
##
## PER-AREA FRAMING: this rig lives in the area scene, not in the player scene, so a tight
## courtyard can frame closer than an open field. Duplicate it and change the numbers.

## Metres from the target to the camera. Larger plus a smaller FOV equals more compression.
@export var distance: float = 14.0
## Downward tilt. Negative looks down.
@export var pitch_degrees: float = -32.0
## World yaw. Zero looks along -Z, which keeps sprite facing maths trivial.
@export var yaw_degrees: float = 0.0
## The long lens. Below about 20 the distortion becomes obvious; above 40 the look is lost.
@export_range(10.0, 60.0, 0.5) var fov: float = 27.0
## Metres above the target's origin to aim at, so the character is not dead centre.
@export var height_offset: float = 1.15
## Seconds for the camera to catch up. 0 is rigid, 0.25 is soft. Low values keep pixel art
## from smearing.
@export_range(0.0, 0.6, 0.01) var follow_lag: float = 0.10
## Vertical framing bias. Positive pushes the subject down the screen, showing more ahead.
@export var frame_bias: float = 0.10

@export_group("Depth of field")
@export var dof_enabled: bool = true
## Everything beyond target distance plus this blurs out.
@export var far_start: float = 4.0
@export var far_transition: float = 8.0
## Everything nearer than target distance minus this blurs out. This is the half that
## most people forget, and the half that creates the miniature effect.
@export var near_start: float = 5.0
@export var near_transition: float = 4.0
@export_range(0.0, 1.0, 0.01) var blur_amount: float = 0.12

var camera: Camera3D = null

var _target: Node3D = null
var _smoothed: Vector3 = Vector3.ZERO
var _attributes: CameraAttributesPractical = null


func _ready() -> void:
	camera = get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	_attributes = CameraAttributesPractical.new()
	camera.attributes = _attributes
	camera.fov = fov
	camera.current = true
	_apply_dof()

	# Adopt whoever is already here, then keep listening. Order of area load versus player
	# spawn is not guaranteed, so handle both directions.
	if Director.player != null:
		set_target(Director.player)
	Events.player_spawned.connect(set_target)
	Events.player_despawned.connect(_on_target_lost)

	if _target != null:
		_smoothed = _target.global_position
		_snap()
	Log.info("camera", "Rig ready: fov %.1f, distance %.1f, pitch %.1f" % [fov, distance, pitch_degrees])


func set_target(node: Node3D) -> void:
	_target = node
	if node != null:
		_smoothed = node.global_position
		_snap()
		Log.debug("camera", "Following %s" % node.name)


func _on_target_lost() -> void:
	_target = null


## Physics-frame following, because the target is a physics body. Following in _process
## against a body that moves in _physics_process is the usual cause of camera jitter.
func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if follow_lag <= 0.0:
		_smoothed = _target.global_position
	else:
		# Exponential smoothing, framerate-independent. Unlike a fixed lerp factor this
		# behaves the same at 60 and 144 fps.
		var t: float = 1.0 - exp(-delta / follow_lag)
		_smoothed = _smoothed.lerp(_target.global_position, t)
	_place()


func _snap() -> void:
	_place()


func _place() -> void:
	if camera == null:
		return
	var pitch: float = deg_to_rad(pitch_degrees)
	var yaw: float = deg_to_rad(yaw_degrees)

	var focus: Vector3 = _smoothed + Vector3.UP * height_offset
	# Offset backwards along the view direction, then aim at the focus point.
	var back: Vector3 = Vector3(0.0, 0.0, 1.0).rotated(Vector3.RIGHT, pitch).rotated(Vector3.UP, yaw)
	camera.global_position = focus + back * distance
	camera.look_at(focus - Vector3.UP * (frame_bias * distance * 0.1), Vector3.UP)
	_update_dof_distances()


func _apply_dof() -> void:
	if _attributes == null:
		return
	_attributes.dof_blur_far_enabled = dof_enabled
	_attributes.dof_blur_near_enabled = dof_enabled
	_attributes.dof_blur_far_transition = far_transition
	_attributes.dof_blur_near_transition = near_transition
	_attributes.dof_blur_amount = blur_amount
	_update_dof_distances()


## Depth of field is expressed relative to the target, so the character stays sharp no
## matter how the rig is reframed.
func _update_dof_distances() -> void:
	if _attributes == null:
		return
	_attributes.dof_blur_far_distance = distance + far_start
	_attributes.dof_blur_near_distance = maxf(0.1, distance - near_start)


## Turn depth of field off at runtime. Some players get motion sick from heavy DOF, so this
## is wired to a setting rather than being permanent.
func set_dof_enabled(enabled: bool) -> void:
	dof_enabled = enabled
	_apply_dof()
