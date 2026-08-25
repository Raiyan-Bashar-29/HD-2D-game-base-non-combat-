extends Label
## The interaction prompt. Shows the verb and the object's name, and the refusal reason when
## the player is turned down.
##
## Every string here goes through `tr()`. There is no path in this file by which raw
## player-facing text can reach the screen, which is the point: the previous project
## accumulated ~200 hard-coded strings because the easy path was the wrong one.
##
## OWNS: the prompt text and its visibility.
## MUST NOT: decide what can be interacted with, or perform an interaction. It renders what
## the sensor announces.

## Seconds a refusal message stays up before the normal prompt returns.
const REFUSAL_SECONDS: float = 1.8

var _sensor: InteractionSensor = null
var _target: Node3D = null
var _verb: GameEnums.InteractVerb = GameEnums.InteractVerb.LOOK
var _label_key: String = ""
var _refusal_left: float = 0.0
## A screen is covering the world. Gameplay UI has nothing to say while that is true.
var _ui_blocked: bool = false


func _ready() -> void:
	# _and_offsets_ matters: set_anchors_preset alone leaves the offsets at zero, which gives a
	# zero-width box and text that spills off the left edge of the screen.
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offset_top = -110.0
	offset_bottom = -60.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	text = ""
	visible = false

	Events.interact_target_changed.connect(_on_target_changed)
	Events.interaction_refused.connect(_on_refused)
	Events.player_spawned.connect(_on_player_spawned)
	Events.ui_mode_changed.connect(_on_ui_mode_changed)
	if Director.player != null:
		_on_player_spawned(Director.player)


func _process(delta: float) -> void:
	if _refusal_left > 0.0:
		_refusal_left -= delta
		if _refusal_left > 0.0:
			return
		_redraw()
	elif _sensor != null and _target != null and _sensor.hold_progress() > 0.0:
		_redraw()


func _on_player_spawned(player: Node3D) -> void:
	_sensor = player.get_node_or_null(^"InteractionSensor") as InteractionSensor


func _on_target_changed(target: Node3D, verb: GameEnums.InteractVerb, label_key: String) -> void:
	_target = target
	_verb = verb
	_label_key = label_key
	if _refusal_left <= 0.0:
		_redraw()


func _on_refused(_target: Node3D, reason: GameEnums.RefusalReason, args: Dictionary) -> void:
	text = tr(_refusal_key(reason)).format(args)
	visible = true
	_refusal_left = REFUSAL_SECONDS


func _on_ui_mode_changed(mode: GameEnums.UiMode) -> void:
	_ui_blocked = mode != GameEnums.UiMode.GAMEPLAY
	if _ui_blocked:
		_refusal_left = 0.0
	_redraw()


func _redraw() -> void:
	if _ui_blocked or _target == null:
		text = ""
		visible = false
		return
	var line: String = "%s  %s" % [tr(_verb_key(_verb)), tr(_label_key) if _label_key != "" else ""]
	# A hold interaction shows its progress, so the player knows to keep holding rather than
	# concluding the button is broken.
	if _sensor != null:
		var progress: float = _sensor.hold_progress()
		if progress > 0.0:
			line += "  [%s]" % "=".repeat(maxi(1, roundi(progress * 10.0)))
	text = line.strip_edges()
	visible = true


## Enum name to localization key: USE -> "verb.use". Keeps the key list mechanical, so a new
## verb cannot be added without a matching key showing up as a missing translation.
func _verb_key(verb: GameEnums.InteractVerb) -> String:
	var names: Array = GameEnums.InteractVerb.keys()
	var raw: String = names[verb]
	return "verb.%s" % raw.to_lower()


func _refusal_key(reason: GameEnums.RefusalReason) -> String:
	var names: Array = GameEnums.RefusalReason.keys()
	var raw: String = names[reason]
	return "refusal.%s" % raw.to_lower()
