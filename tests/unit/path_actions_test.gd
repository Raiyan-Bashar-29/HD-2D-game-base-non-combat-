extends TestCase
## Path actions: refused before they run, or committed and then succeeding or failing.
##
## THE HEADLINE ASSERTION IS _barter_fails_then_succeeds(). One action, one player, three
## attempts: refused while a stranger, committed and FAILED at neutral standing, then committed
## and succeeded once standing has been earned. That is the WP-07 criterion walked in one go —
## an action that can fail and change standing — rather than inferred from four separate cases.
##
## THE DISTINCTION UNDER TEST is refusal versus failure. A refusal happens before anything and
## costs nothing; a failure happens after committing and costs standing. An action that could
## only refuse would be a lock with extra steps, and one that could only fail would give the
## player no way to read the situation first. Both halves are asserted, including that a refusal
## really does leave standing untouched.
##
## OWNS: assertions about PathAction data, PathActionPoint outcomes, and the Standing namespace.
## MUST NOT: assert what a prompt looks like, or how the sensor ranks overlapping targets.

const KEEPER: StringName = &"keeper"
const SCRUTINISE: String = "res://data/actions/keeper_scrutinise.tres"
const BARTER: String = "res://data/actions/keeper_barter.tres"

var _point: PathActionPoint = null
var _outcomes: Array[bool] = []


func run() -> void:
	Flags.clear_all()
	_standing_is_a_clamped_namespace()
	_the_authored_actions_are_sound()
	_a_refusal_costs_nothing()
	_barter_fails_then_succeeds()
	_once_applies_to_success_only()
	_standing_survives_a_save()
	_tear_down()


## Standing is a namespace over Flags, not a store. What this file owns is the key shape and the
## clamp — and the clamp matters, because a repeatable action against an unbounded number would
## let the player farm a value that later gates content.
func _standing_is_a_clamped_namespace() -> void:
	Flags.clear_all()
	equal("an unmet person is neutral", Standing.of(KEEPER), 0)
	equal("with no flag stored at all", Flags.has_flag(Standing.key(KEEPER)), false)
	equal("the key is namespaced", String(Standing.key(KEEPER)), "standing/keeper")

	equal("a gain returns the new value", Standing.change(KEEPER, 2), 2)
	equal("and is readable", Standing.of(KEEPER), 2)
	equal("at_least is inclusive", Standing.at_least(KEEPER, 2), true)
	equal("and refuses above", Standing.at_least(KEEPER, 3), false)

	equal("it clamps at the ceiling", Standing.change(KEEPER, 99), Standing.MAXIMUM)
	equal("and at the floor", Standing.change(KEEPER, -99), Standing.MINIMUM)
	equal("two people are separate", Standing.of(&"someone_else"), 0)
	equal("and all() finds the one that exists", Standing.all().size(), 1)
	Flags.clear_all()


## The authored .tres files, checked as data before anything performs them. An action whose
## failure branch is unreachable, or which says nothing when it fails, is a content bug that no
## amount of playing the happy path would reveal.
func _the_authored_actions_are_sound() -> void:
	for path: String in [SCRUTINISE, BARTER]:
		var action: PathAction = load(path) as PathAction
		equal("%s loads as a PathAction" % path.get_file(), action != null, true)
		equal("and is sound", action.problems(path.get_file()).size(), 0)
		equal("and names a verb key that is translated",
			tr("verb.%s" % action.verb_name().to_lower()) != "verb.%s" % action.verb_name().to_lower(), true)

	var barter: PathAction = load(BARTER) as PathAction
	equal("barter can genuinely fail", barter.success_standing > barter.required_standing, true)
	equal("it fails below its line", barter.succeeds_at(barter.success_standing - 1), false)
	equal("and succeeds at it", barter.succeeds_at(barter.success_standing), true)


## A refusal happens BEFORE anything. The player is told why, and has lost nothing — asserted
## against the standing value, not merely against the returned reason.
func _a_refusal_costs_nothing() -> void:
	Flags.clear_all()
	_point = _build_point(BARTER, &"probe_barter")
	equal("a stranger is refused", _point.refusal(null), GameEnums.RefusalReason.LOW_STANDING)
	equal("the attempt fails", _point.attempt(null), false)
	equal("and standing did NOT move", Standing.of(KEEPER), 0)
	equal("nor was the success flag set", Flags.has_flag(&"story/keeper_bartered"), false)
	equal("the refusal names the shortfall", _point.refusal_args(null).has("needed"), true)
	_drop_point()


## THE HEADLINE. Refused, then committed and failed, then committed and succeeded — one action,
## three outcomes, driven only by the standing between them.
func _barter_fails_then_succeeds() -> void:
	Flags.clear_all()
	_point = _build_point(BARTER, &"probe_barter")
	_point.resolved.connect(_on_resolved)
	var action: PathAction = _point.action

	Standing.change(KEEPER, action.required_standing - Standing.of(KEEPER))
	equal("at exactly the required standing it is offered",
		_point.refusal(null), GameEnums.RefusalReason.NONE)
	equal("but it is below the success line", action.succeeds_at(Standing.of(KEEPER)), false)

	var before: int = Standing.of(KEEPER)
	equal("the attempt COMMITS and returns true", _point.attempt(null), true)
	equal("it resolved as a failure", _outcomes, [false] as Array[bool])
	equal("failure cost standing", Standing.of(KEEPER), before + action.standing_on_failure)
	equal("and set no flag", Flags.has_flag(action.success_flag), false)
	equal("a failed action is still on offer", _point.is_done(), false)

	Standing.change(KEEPER, action.success_standing - Standing.of(KEEPER))
	equal("now it is at the success line", action.succeeds_at(Standing.of(KEEPER)), true)
	var earned: int = Standing.of(KEEPER)
	equal("the second attempt succeeds", _point.attempt(null), true)
	equal("it resolved as a success", _outcomes.size(), 2)
	equal("and the second outcome was true", _outcomes[1], true)
	equal("success raised standing", Standing.of(KEEPER), earned + action.standing_on_success)
	equal("and set its flag", Flags.get_bool(action.success_flag), true)
	_drop_point()


## `once` applies to SUCCESS only. A single early failure must not lock the player out of an
## action forever with no way back — which is what `once` on any outcome would do.
func _once_applies_to_success_only() -> void:
	Flags.clear_all()
	_point = _build_point(BARTER, &"probe_barter")
	equal("the action is marked once", _point.action.once, true)

	Standing.change(KEEPER, _point.action.required_standing)
	equal("it fails first", _point.attempt(null), true)
	equal("and is NOT done", _point.is_done(), false)
	equal("so it is still offerable", _point.is_offerable(), true)

	Standing.change(KEEPER, _point.action.success_standing - Standing.of(KEEPER))
	equal("then it succeeds", _point.attempt(null), true)
	equal("and NOW it is done", _point.is_done(), true)
	equal("so it stops being offered", _point.is_offerable(), false)
	equal("and a further attempt is refused", _point.attempt(null), false)
	_drop_point()


## Standing rides the save machinery that already exists, because it IS a flag. Asserted rather
## than assumed, because "it is just a flag" is exactly the kind of claim that turns out to have
## been written to the wrong namespace.
func _standing_survives_a_save() -> void:
	Flags.clear_all()
	Standing.change(KEEPER, 3)
	Standing.change(&"someone_else", -2)
	var slot: int = 2
	equal("the save succeeds", SaveSystem.save_to_slot(slot), OK)
	Standing.change(KEEPER, -3)
	equal("the value is destroyed before reloading", Standing.of(KEEPER), 0)
	equal("the load succeeds", SaveSystem.load_from_slot(slot), OK)
	equal("standing came back", Standing.of(KEEPER), 3)
	equal("including the negative one", Standing.of(&"someone_else"), -2)
	SaveSystem.delete_slot(slot)


## Built and attached in two steps, because PathActionPoint forwards object_id to its
## PersistentState child in _enter_tree — anything set after add_child is too late and the node
## silently stops persisting.
func _build_point(action_path: String, object_id: StringName) -> PathActionPoint:
	_outcomes.clear()
	var point: PathActionPoint = build("res://scenes/objects/path_action.tscn") as PathActionPoint
	point.action = load(action_path) as PathAction
	point.standing_id = KEEPER
	point.object_id = object_id
	attach(point)
	return point


func _drop_point() -> void:
	if _point != null:
		if _point.resolved.is_connected(_on_resolved):
			_point.resolved.disconnect(_on_resolved)
		_point.queue_free()
		_point = null


func _on_resolved(success: bool) -> void:
	_outcomes.append(success)


func _tear_down() -> void:
	_drop_point()
	Flags.clear_all()
