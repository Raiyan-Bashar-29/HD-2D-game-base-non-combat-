extends TestCase
## The interaction loop and per-object persistence, driven by direct calls rather than
## simulated input: a gate that refuses until a lever is thrown, and object state that
## survives the object being destroyed and rebuilt.
##
## OWNS: assertions about interactables. MUST NOT: assert on the sensor's ranking, which
## needs real geometry and belongs in a scene-level test.

var _gate: Gate = null
var _lever: Lever = null


func run() -> void:
	_gating()
	_persistence()


func _gating() -> void:
	Flags.clear_all()
	# Configure BEFORE attaching: object_id is forwarded in _enter_tree.
	_lever = build("res://scenes/objects/lever.tscn") as Lever
	_lever.object_id = &"t_lever"
	_lever.world_flag = &"test/gate_unlocked"
	_lever.label_key = "object.lever.gate.label"
	attach(_lever)
	_gate = build("res://scenes/objects/gate.tscn") as Gate
	_gate.object_id = &"t_gate"
	_gate.requires_flag = &"test/gate_unlocked"
	_gate.label_key = "object.gate.north.label"
	attach(_gate)

	# Locked: the interaction is offered and refused, not hidden. A player must be able to
	# tell a locked gate from scenery, or they never learn to come back.
	equal("gate is offerable while locked", _gate.is_offerable(), true)
	equal("gate refuses with LOCKED", _gate.refusal(null), GameEnums.RefusalReason.LOCKED)
	equal("locked gate attempt fails", _gate.attempt(null), false)
	equal("locked gate did not open", _gate.is_open(), false)

	# The lever knows nothing about the gate; it only publishes a flag.
	equal("lever starts off", _lever.is_on(), false)
	equal("lever throw succeeds", _lever.attempt(null), true)
	equal("lever is on", _lever.is_on(), true)
	equal("lever published its flag", Flags.get_bool(&"test/gate_unlocked"), true)

	# Same gate, same button, now allowed.
	equal("gate no longer refuses", _gate.refusal(null), GameEnums.RefusalReason.NONE)
	equal("gate opens", _gate.attempt(null), true)
	equal("gate is open", _gate.is_open(), true)
	equal("open gate refuses as ALREADY_DONE", _gate.refusal(null), GameEnums.RefusalReason.ALREADY_DONE)
	equal("open gate stops being offered", _gate.is_offerable(), false)


func _persistence() -> void:
	# Identity is authored, so state is addressable without knowing the node path.
	equal("state key format", String(_gate.state().key(&"open")), "obj/global/t_gate/open")
	equal("state landed in Flags", Flags.get_bool(&"obj/global/t_gate/open"), true)

	var gate_scene: PackedScene = load("res://scenes/objects/gate.tscn")
	if _lever != null and is_instance_valid(_lever):
		_lever.free()
	_gate.free()
	_lever = null
	_gate = null

	# Destroy and rebuild, which is what an area reload does. State must survive.
	var rebuilt: Gate = gate_scene.instantiate() as Gate
	rebuilt.object_id = &"t_gate"
	rebuilt.label_key = "object.gate.north.label"
	add_child(rebuilt)
	equal("rebuilt gate is still open", rebuilt.is_open(), true)
	equal("rebuilt gate is not offered again", rebuilt.is_offerable(), false)

	# Clearing one object forgets only that object.
	Flags.set_flag(&"unrelated/keep", true)
	rebuilt.state().clear()
	equal("cleared object state is gone", Flags.has_flag(&"obj/global/t_gate/open"), false)
	equal("unrelated flag survived", Flags.get_bool(&"unrelated/keep"), true)

	rebuilt.free()
	Flags.clear_all()
