class_name InteractionSensor
extends Area3D
## Finds what the player could interact with, decides which one they mean, and fires it.
## Lives as a child of the player.
##
## THE ACTUAL PROBLEM THIS SOLVES
## Detection is trivial; *selection* is not. Stand where a sign, a lever and a door all
## overlap and the game must pick the one the player means, let them override it, and never
## silently swap the target while they are reaching for the button. Nearest-wins is not enough:
## a player facing a lever with a sign fractionally closer will press the button and read the
## sign, which reads as a bug.
##
## The ranking is: priority first (authored intent wins), then proximity, then how squarely
## the player is facing it. Ties are broken by node name so the order is stable frame to
## frame rather than dependent on physics callback order.
##
## OWNS: the candidate set, the ranking, the cycle override, and hold timing.
## MUST NOT: know what any interactable does, or contain any object's behaviour.
##
## NOTE ON INPUT: this reads input directly. It is a component of the player, and the
## alternative - routing interaction input through PlayerController - would force the
## controller to know about interaction, which its own MUST NOT line forbids.

## How far the player can reach. The Area3D shape should be at least this big.
@export var max_distance: float = 2.4
## How much facing the target matters relative to being close to it. Raise it if selection
## feels like it ignores where the player is looking.
@export var facing_weight: float = 1.2
## Authored priority is worth this much, so a deliberate priority always beats geometry.
@export var priority_weight: float = 100.0

var _candidates: Array[Interactable] = []
var _current: Interactable = null
var _cycle: int = 0
var _hold: float = 0.0
var _facing: Vector3 = Vector3.FORWARD
var _body: CharacterBody3D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.INTERACT_MASK
	monitoring = true
	monitorable = false
	_body = get_parent() as CharacterBody3D
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	Log.info("interact", "Sensor ready, reach %.1fm" % max_distance)


func _physics_process(delta: float) -> void:
	_track_facing()
	_prune()
	var best: Interactable = _select()
	if best != _current:
		_current = best
		_cycle = 0
		_hold = 0.0
		_announce()
	_handle_input(delta)


## The interactable the player would act on right now, or null.
func current() -> Interactable:
	return _current


## 0.0 to 1.0 while a hold-to-confirm interaction is in progress. The UI draws this.
func hold_progress() -> float:
	if _current == null or _current.hold_seconds <= 0.0:
		return 0.0
	return clampf(_hold / _current.hold_seconds, 0.0, 1.0)


func _handle_input(delta: float) -> void:
	if _current == null:
		_hold = 0.0
		return

	if Input.is_action_just_pressed(Actions.INTERACT_CYCLE) and _candidates.size() > 1:
		_cycle += 1
		_hold = 0.0
		_current = _select()
		_announce()
		return

	if _current.hold_seconds > 0.0:
		if Input.is_action_pressed(Actions.INTERACT):
			_hold += delta
			if _hold >= _current.hold_seconds:
				_hold = 0.0
				_current.attempt(_body)
		else:
			_hold = 0.0
		return

	if Input.is_action_just_pressed(Actions.INTERACT):
		_current.attempt(_body)


## Rank every candidate and return the one the cycle offset points at.
func _select() -> Interactable:
	var ranked: Array[Interactable] = []
	for candidate: Interactable in _candidates:
		if candidate.is_offerable() and _score(candidate) > -INF:
			ranked.append(candidate)
	if ranked.is_empty():
		return null
	# Stable order: score descending, then name, so physics callback order cannot reshuffle
	# the prompt between frames.
	ranked.sort_custom(func(a: Interactable, b: Interactable) -> bool:
		var sa: float = _score(a)
		var sb: float = _score(b)
		if is_equal_approx(sa, sb):
			return a.name < b.name
		return sa > sb)
	return ranked[posmod(_cycle, ranked.size())]


## Higher is better. Returns -INF for anything out of reach.
func _score(target: Interactable) -> float:
	var to_target: Vector3 = target.focus_point() - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance > max_distance:
		return -INF
	var alignment: float = 0.0
	if distance > 0.01:
		alignment = _facing.dot(to_target / distance)
	return float(target.interact_priority) * priority_weight + (max_distance - distance) + alignment * facing_weight


## Remember the last direction the player actually moved, so selection respects where they
## are pointing even while standing still.
func _track_facing() -> void:
	if _body == null:
		return
	var flat: Vector3 = Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	if flat.length_squared() > 0.04:
		_facing = flat.normalized()


## Drop anything freed or removed from the tree while it was in the set.
func _prune() -> void:
	var kept: Array[Interactable] = []
	for candidate: Interactable in _candidates:
		if is_instance_valid(candidate) and candidate.is_inside_tree():
			kept.append(candidate)
	_candidates = kept


func _announce() -> void:
	if _current == null:
		Events.interact_target_changed.emit(null, GameEnums.InteractVerb.LOOK, "")
		return
	Events.interact_target_changed.emit(_current, _current.verb, _current.label_key)


func _on_area_entered(area: Area3D) -> void:
	var target: Interactable = area as Interactable
	if target == null or _candidates.has(target):
		return
	_candidates.append(target)
	# An object that unlocks while the player stands next to it must become selectable at
	# once, not after they step away and back.
	if not target.availability_changed.is_connected(_on_availability_changed):
		target.availability_changed.connect(_on_availability_changed)


func _on_area_exited(area: Area3D) -> void:
	var target: Interactable = area as Interactable
	if target == null:
		return
	_candidates.erase(target)
	if target.availability_changed.is_connected(_on_availability_changed):
		target.availability_changed.disconnect(_on_availability_changed)


func _on_availability_changed() -> void:
	_current = _select()
	_announce()
