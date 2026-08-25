class_name PlayerController
extends CharacterBody3D
## The player's body and movement.
##
## INPUT OWNERSHIP: this reads movement input only. Interaction input is read by
## InteractionSensor, which is a sibling component, because routing it through here would
## force this file to know about interaction - which the MUST NOT line below forbids.
##
## OWNS: the player's position, velocity, gait and movement state.
## MUST NOT: know about dialogue, inventory, interaction rules or the camera. It reacts to
## a small number of signals that say "you are busy now" and otherwise minds its own
## business. This is what stops a player controller becoming the second god object.
##
## MOVEMENT IS CAMERA-RELATIVE: pressing up moves away from the camera regardless of where
## the camera is, which is what players expect and what makes a fixed-angle camera feel
## natural instead of maddening.
##
## NO JUMPING, deliberately. In an exploration game with a fixed camera, a free jump makes
## the player try to reach ledges the level was not built for, and every collision gap
## becomes a bug report. Vertical movement will be authored: ladders, stairs, climb points.
## The gravity below is for slopes and falling, not for jumping.

@export var walk_speed: float = 3.2
@export var run_speed: float = 6.0
@export var sneak_speed: float = 1.4
## Metres per second squared. High values feel responsive; low values feel like ice.
@export var acceleration: float = 14.0
@export var friction: float = 18.0
## Whether run is held or toggled. Mirrors the "gameplay/run_is_toggle" setting.
@export var run_is_toggle: bool = false

@onready var visual: CharacterVisual = $Visual

var state: GameEnums.MoveState = GameEnums.MoveState.IDLE

var _gravity: float = 24.0
var _run_toggled: bool = false
## Set while dialogue, a cutscene or a multi-step interaction has control.
var _input_locked: bool = false


func _ready() -> void:
	var configured: float = ProjectSettings.get_setting("physics/3d/default_gravity", 24.0)
	_gravity = configured

	collision_layer = Layers.PLAYER
	collision_mask = Layers.PLAYER_MOVE_MASK
	# Let the body ride over small steps and stay glued to slopes when walking downhill.
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)

	run_is_toggle = Settings.get_bool("gameplay/run_is_toggle")
	Events.setting_changed.connect(_on_setting_changed)
	Events.dialogue_started.connect(_on_busy_started)
	Events.dialogue_finished.connect(_on_busy_finished)

	Events.player_spawned.emit(self)
	Log.info("character", "Player ready at %s" % str(global_position))


func _exit_tree() -> void:
	Events.player_despawned.emit()


func _physics_process(delta: float) -> void:
	_poll_run_toggle()
	var wish: Vector3 = Vector3.ZERO
	if not _input_locked:
		wish = _read_movement_input()

	var target_speed: float = _current_speed()
	var target_velocity: Vector3 = wish * target_speed

	# Accelerate towards the wish velocity, decelerate to a stop with friction.
	var rate: float = acceleration if wish != Vector3.ZERO else friction
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	move_and_slide()

	if visual != null:
		visual.update_from_velocity(velocity, delta)
	_update_state(wish)


## Input is read on the horizontal plane, then rotated into the camera's frame.
func _read_movement_input() -> Vector3:
	var raw: Vector2 = Vector2(
		Input.get_axis(Actions.MOVE_LEFT, Actions.MOVE_RIGHT),
		Input.get_axis(Actions.MOVE_UP, Actions.MOVE_DOWN),
	)
	if raw.length_squared() < 0.0001:
		return Vector3.ZERO
	# Clamp rather than normalise, so an analogue stick keeps its partial deflection while
	# two keyboard keys together do not produce faster diagonal movement.
	if raw.length() > 1.0:
		raw = raw.normalized()
	var direction: Vector3 = Vector3(raw.x, 0.0, raw.y).rotated(Vector3.UP, _camera_yaw())
	return direction


func _camera_yaw() -> float:
	var active: Camera3D = get_viewport().get_camera_3d()
	return active.global_rotation.y if active != null else 0.0


func _current_speed() -> float:
	if Input.is_action_pressed(Actions.SNEAK):
		return sneak_speed
	if _is_running():
		return run_speed
	return walk_speed


## A pure query. It used to poll is_action_just_pressed itself, but it is called twice per
## frame (from _current_speed and from _update_state), so the toggle flipped twice and never
## changed: toggle-run silently did nothing. Polling now happens once, in _poll_run_toggle.
func _is_running() -> bool:
	if _input_locked:
		return false
	if run_is_toggle:
		return _run_toggled
	return Input.is_action_pressed(Actions.RUN)


## Called once at the top of _physics_process, and nowhere else. Keep it that way.
func _poll_run_toggle() -> void:
	if run_is_toggle and not _input_locked and Input.is_action_just_pressed(Actions.RUN):
		_run_toggled = not _run_toggled


func _update_state(wish: Vector3) -> void:
	var next: GameEnums.MoveState = state
	if _input_locked:
		next = GameEnums.MoveState.BUSY
	elif not is_on_floor() and velocity.y < -0.5:
		next = GameEnums.MoveState.FALL
	elif wish == Vector3.ZERO:
		next = GameEnums.MoveState.IDLE
	elif Input.is_action_pressed(Actions.SNEAK):
		next = GameEnums.MoveState.SNEAK
	elif _is_running():
		next = GameEnums.MoveState.RUN
	else:
		next = GameEnums.MoveState.WALK

	if next == state:
		return
	state = next
	Events.player_state_changed.emit(state)


## Hand control to something else: dialogue, a cutscene, a held interaction.
## Kept as a public method so any system can borrow the player without this file needing
## to know which system it was.
func set_input_locked(locked: bool) -> void:
	_input_locked = locked
	if locked:
		velocity.x = 0.0
		velocity.z = 0.0


func _on_busy_started(_speaker: StringName) -> void:
	set_input_locked(true)


func _on_busy_finished(_speaker: StringName) -> void:
	set_input_locked(false)


func _on_setting_changed(section: String, key: String, value: Variant) -> void:
	if section == "gameplay" and key == "run_is_toggle" and value is bool:
		run_is_toggle = value
		_run_toggled = false
