class_name Gate
extends Interactable
## A door or gate that can be locked. Proves the refusal path: the player presses the button,
## is told *why* nothing happened, and the same button works once the condition is met.
##
## WHY REFUSAL IS A FIRST-CLASS RESULT
## The cheap implementation is to hide the prompt when the gate is locked. That is worse than
## it sounds: the player cannot tell a locked door from scenery, so they never learn there is
## something to come back for. Offering the interaction and refusing it with a reason is what
## turns a wall into a goal.
##
## OWNS: whether it is open, and its persistence.
## MUST NOT: know how the condition became true, or what is on the other side.

const OPEN_FIELD: StringName = &"open"

## Must be true before this gate will open. Empty means it is never locked.
@export var requires_flag: StringName = &""
## The geometry that physically blocks the way. Disabled and hidden when the gate opens.
@export var blocker: StaticBody3D = null
## Shown when the player is refused, and when it opens.
@export var locked_key: String = "refusal.locked"
@export var opened_key: String = ""
## Once open, stay open. A gate that re-locks itself behind the player is a different object.
@export var stays_open: bool = true

signal opened()


func _ready() -> void:
	verb = GameEnums.InteractVerb.OPEN
	super()
	# Restore across a load before the first frame is drawn, so a gate the player already
	# opened is never briefly shut.
	if is_open():
		_apply_open(false)


func refusal(_who: Node3D) -> GameEnums.RefusalReason:
	if is_open():
		return GameEnums.RefusalReason.ALREADY_DONE
	if requires_flag != &"" and not Flags.get_bool(requires_flag):
		return GameEnums.RefusalReason.LOCKED
	return GameEnums.RefusalReason.NONE


func perform(_who: Node3D) -> void:
	var store: PersistentState = state()
	if store != null:
		store.store(OPEN_FIELD, true)
	_apply_open(true)
	if opened_key != "":
		Events.notify_requested.emit(opened_key, 2.5)
	opened.emit()


func is_open() -> bool:
	var store: PersistentState = state()
	return store != null and store.fetch_bool(OPEN_FIELD)


## `announce` is false when restoring a save, so loading does not replay the toast.
func _apply_open(announce: bool) -> void:
	if blocker != null:
		blocker.visible = false
		# Layer zero rather than disabling the node, so anything already resting on it is
		# not left standing on a shape that vanished mid-frame.
		blocker.collision_layer = 0
	if stays_open:
		set_available(false)
	if announce:
		Log.info("interact", "%s opened" % name)
