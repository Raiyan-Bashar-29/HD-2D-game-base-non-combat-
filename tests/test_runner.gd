extends Node
## Rung 4 of the verification ladder: headless integration tests with the real autoloads live.
##
## WHY THIS IS A SCENE AND NOT A --script TOOL
## Under `--headless --script foo.gd` the autoload *nodes* are created, but the autoload
## *identifiers* (`Log`, `Flags`, `SaveSystem`) fail to compile - proven, the error is
## `Compile Error: Identifier not found: Log`. So any test that touches a system cannot be a
## --script tool. It has to be a scene, entered positionally:
##
##     godot_console --headless res://tests/test_runner.tscn --quit-after 120
##
## Exit code 0 if every assertion passes, 1 otherwise, so this gates a commit or CI.
##
## WHY IT EXISTS AT ALL
## docs/ROADMAP.md claimed "a save participant can register, and the save envelope
## round-trips" as a met Phase 0 exit criterion. Registration was observed in a log line;
## the round-trip had never once been executed. That is the 409-passing-checks pathology in
## miniature, in this project, already. This file makes the claim true or fails loudly.
##
## OWNS: assertions and the pass/fail exit code.
## MUST NOT: contain game logic, or be depended on by anything that ships.

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []

## Round-trip probe state. A real save participant, owned by the test.
var _probe_value: int = 0
var _probe_name: StringName = &""
## Handed from the gating test to the persistence test, which continues with the same objects.
var _gate: Gate = null
var _lever: Lever = null


func _ready() -> void:
	Log.info("test", "=== test run starting ===")
	# Determinism: a clock that advances mid-assertion makes time tests flaky.
	Clock.paused = true

	_test_dict_read()
	_test_flags()
	_test_clock()
	_test_weather()
	_test_save_round_trip()
	_test_interaction_gating()
	_test_object_persistence()

	Log.info("test", "=== %d passed, %d failed ===" % [_passed, _failed])
	for failure: String in _failures:
		Log.error("test", "FAILED: %s" % failure)
	get_tree().quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------------------
# Cases
# ---------------------------------------------------------------------------------------

## DictRead is the single funnel for untyped external data, so its coercion rules matter
## more than their size suggests.
func _test_dict_read() -> void:
	var data: Dictionary = {"i": 5, "f": 2.5, "b": true, "s": "hi", "one": 1, "v": [1.0, 2.0, 3.0]}
	_equal("dict_read int", DictRead.get_int(data, "i"), 5)
	# JSON has one number type, so an int may arrive as a float and must survive.
	_equal("dict_read int from float", DictRead.get_int(data, "f"), 3)
	_equal("dict_read float from int", DictRead.get_float(data, "i"), 5.0)
	_equal("dict_read bool", DictRead.get_bool(data, "b"), true)
	_equal("dict_read bool from 1", DictRead.get_bool(data, "one"), true)
	_equal("dict_read string", DictRead.get_string(data, "s"), "hi")
	_equal("dict_read vector3", DictRead.get_vector3(data, "v"), Vector3(1.0, 2.0, 3.0))
	# Wrong type and missing key must both fall back, never crash.
	_equal("dict_read wrong type falls back", DictRead.get_int(data, "s", -1), -1)
	_equal("dict_read missing key falls back", DictRead.get_int(data, "nope", -2), -2)
	_equal("dict_read bad vector3 falls back", DictRead.get_vector3(data, "s"), Vector3.ZERO)


func _test_flags() -> void:
	Flags.clear_all()
	_equal("flags start empty", Flags.count(), 0)

	var heard: Array[StringName] = []
	var listener: Callable = func(flag: StringName, _value: Variant) -> void: heard.append(flag)
	Events.flag_changed.connect(listener)

	Flags.set_flag(&"test/bool", true)
	Flags.set_flag(&"test/int", 3)
	_equal("flags bool", Flags.get_bool(&"test/bool"), true)
	_equal("flags int", Flags.get_int(&"test/int"), 3)
	_equal("flags signal fired twice", heard.size(), 2)

	# Setting the same value again must be silent, so listeners are not woken for a non-change.
	Flags.set_flag(&"test/int", 3)
	_equal("flags no signal on no-op set", heard.size(), 2)

	_equal("flags advance", Flags.advance(&"test/count", 2), 2)
	_equal("flags advance again", Flags.advance(&"test/count", 3), 5)
	_equal("flags typed getter rejects wrong type", Flags.get_bool(&"test/int", false), false)
	_equal("flags prefix query", Flags.with_prefix("test/").size(), 3)

	Events.flag_changed.disconnect(listener)
	Flags.clear_all()
	_equal("flags cleared", Flags.count(), 0)


func _test_clock() -> void:
	Clock.set_time(1, 6, 0)
	_equal("clock hour", Clock.hour, 6)
	_equal("clock minutes_today", Clock.minutes_today(), 360)
	_equal("clock day_fraction", is_equal_approx(Clock.day_fraction(), 0.25), true)
	_equal("clock phase at 06:00", Clock.phase(), GameEnums.DayPhase.DAWN)

	# Phase boundaries, which lighting and NPC schedules both key off.
	_equal("phase 04:00 is deep night", Clock.phase_for_hour(4), GameEnums.DayPhase.DEEP_NIGHT)
	_equal("phase 12:00 is midday", Clock.phase_for_hour(12), GameEnums.DayPhase.MIDDAY)
	_equal("phase 23:00 is night", Clock.phase_for_hour(23), GameEnums.DayPhase.NIGHT)

	# Hour rollover.
	Clock.set_time(1, 6, 59)
	Clock.advance_minutes(1)
	_equal("clock rolls the hour", Clock.hour, 7)
	_equal("clock resets the minute", Clock.minute, 0)

	# Day rollover.
	Clock.set_time(1, 23, 59)
	Clock.advance_minutes(1)
	_equal("clock rolls the day", Clock.day, 2)
	_equal("clock wraps to hour zero", Clock.hour, 0)

	# Sleeping until morning crosses midnight, which is the case that is easy to get wrong.
	Clock.set_time(2, 22, 0)
	_equal("minutes until 06:00 from 22:00", Clock.minutes_until_hour(6), 480)
	Clock.set_time(2, 4, 0)
	_equal("minutes until 06:00 from 04:00", Clock.minutes_until_hour(6), 120)

	Clock.set_time(1, 6, 0)


func _test_weather() -> void:
	Weather.force(GameEnums.WeatherKind.RAIN)
	_equal("weather forced current", Weather.current(), GameEnums.WeatherKind.RAIN)
	_equal("weather forced target", Weather.target(), GameEnums.WeatherKind.RAIN)
	_equal("weather blend settled", is_equal_approx(Weather.blend(), 1.0), true)
	_equal("weather is wet", Weather.is_wet(), true)

	# Shelter hides the weather without changing it, so stepping outside shows the same storm.
	Weather.sheltered = true
	_equal("sheltered is not wet", Weather.is_wet(), false)
	_equal("sheltered keeps the state", Weather.current(), GameEnums.WeatherKind.RAIN)
	Weather.sheltered = false

	Weather.force(GameEnums.WeatherKind.CLEAR)
	_equal("clear is not wet", Weather.is_wet(), false)
	_equal("clear intensity is zero", is_equal_approx(Weather.intensity(), 0.0), true)


## The criterion the roadmap claimed and never ran.
func _test_save_round_trip() -> void:
	# Director's save section asks for an area change on restore, which needs a world root a
	# test scene has no business building. Drop it for this test; the transition path is
	# covered by the boot run instead.
	SaveSystem.unregister(&"world")

	_probe_name = &"test_probe"
	SaveSystem.register(_probe_name, _probe_collect, _probe_apply)

	var slot: int = SaveSystem.MAX_SLOTS - 1
	_probe_value = 42
	Flags.set_flag(&"save/marker", "kept")
	Clock.set_time(3, 14, 30)
	Weather.force(GameEnums.WeatherKind.FOG)

	_equal("save returns OK", SaveSystem.save_to_slot(slot), OK)
	_equal("slot now exists", SaveSystem.has_slot(slot), true)

	var header: Dictionary = SaveSystem.slot_info(slot)
	_equal("header carries the version", DictRead.get_int(header, "version"), SaveSystem.SCHEMA_VERSION)
	_equal("header excludes the payload", header.has("sections"), false)

	# Scramble everything, so a restore that does nothing cannot pass by accident.
	_probe_value = 7
	Flags.set_flag(&"save/marker", "lost")
	Clock.set_time(9, 1, 1)
	Weather.force(GameEnums.WeatherKind.STORM)

	_equal("load returns OK", SaveSystem.load_from_slot(slot), OK)
	_equal("participant value restored", _probe_value, 42)
	_equal("flag restored", Flags.get_string(&"save/marker"), "kept")
	_equal("clock day restored", Clock.day, 3)
	_equal("clock hour restored", Clock.hour, 14)
	_equal("clock minute restored", Clock.minute, 30)
	_equal("weather restored", Weather.current(), GameEnums.WeatherKind.FOG)

	# A missing slot must fail cleanly rather than crash.
	_equal("loading an empty slot is refused", SaveSystem.load_from_slot(slot - 1), ERR_FILE_NOT_FOUND)

	_equal("delete returns OK", SaveSystem.delete_slot(slot), OK)
	_equal("slot is gone", SaveSystem.has_slot(slot), false)

	SaveSystem.unregister(_probe_name)
	Flags.clear_all()


func _probe_collect() -> Dictionary:
	return {"v": _probe_value}


func _probe_apply(data: Dictionary) -> void:
	_probe_value = DictRead.get_int(data, "v", -1)


# ---------------------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------------------

func _equal(label: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		_passed += 1
		Log.debug("test", "  ok   %s" % label)
		return
	_failed += 1
	var message: String = "%s — expected %s, got %s" % [label, str(expected), str(actual)]
	_failures.append(message)
	Log.warn("test", "  FAIL %s" % message)


## A gate that refuses until a lever is thrown, without simulating a keypress. This is the
## loop every future interactable is built on, so it is tested directly.
func _test_interaction_gating() -> void:
	Flags.clear_all()
	var lever_scene: PackedScene = load("res://scenes/objects/lever.tscn")
	var gate_scene: PackedScene = load("res://scenes/objects/gate.tscn")

	var lever: Lever = lever_scene.instantiate() as Lever
	lever.object_id = &"t_lever"
	lever.world_flag = &"test/gate_unlocked"
	lever.label_key = "object.lever.gate.label"
	var gate: Gate = gate_scene.instantiate() as Gate
	_gate = gate
	_lever = null
	gate.object_id = &"t_gate"
	gate.requires_flag = &"test/gate_unlocked"
	gate.label_key = "object.gate.north.label"
	add_child(lever)
	add_child(gate)

	# Locked: the interaction is offered and refused, rather than hidden. A player must be
	# able to tell a locked gate from scenery.
	_equal("gate is offerable while locked", gate.is_offerable(), true)
	_equal("gate refuses with LOCKED", gate.refusal(null), GameEnums.RefusalReason.LOCKED)
	_equal("locked gate attempt fails", gate.attempt(null), false)
	_equal("locked gate did not open", gate.is_open(), false)

	# Throw the lever. It knows nothing about the gate; it only publishes a flag.
	_equal("lever starts off", lever.is_on(), false)
	_equal("lever throw succeeds", lever.attempt(null), true)
	_equal("lever is on", lever.is_on(), true)
	_equal("lever published its flag", Flags.get_bool(&"test/gate_unlocked"), true)
	_lever = lever

	# Same gate, same button, now allowed.
	_equal("gate no longer refuses", gate.refusal(null), GameEnums.RefusalReason.NONE)
	_equal("gate opens", gate.attempt(null), true)
	_equal("gate is open", gate.is_open(), true)
	_equal("open gate refuses as ALREADY_DONE", gate.refusal(null), GameEnums.RefusalReason.ALREADY_DONE)
	_equal("open gate stops being offered", gate.is_offerable(), false)



func _test_object_persistence() -> void:
	var gate_scene: PackedScene = load("res://scenes/objects/gate.tscn")
	var gate: Gate = _gate
	# Identity is authored, so state is addressable without knowing the node path.
	_equal("state key format", String(gate.state().key(&"open")), "obj/global/t_gate/open")
	_equal("state landed in Flags", Flags.get_bool(&"obj/global/t_gate/open"), true)

	# Destroy and rebuild, which is what an area reload does. State must survive.
	if _lever_node() != null:
		_lever_node().free()
	gate.free()
	var rebuilt: Gate = gate_scene.instantiate() as Gate
	rebuilt.object_id = &"t_gate"
	rebuilt.label_key = "object.gate.north.label"
	add_child(rebuilt)
	_equal("rebuilt gate is still open", rebuilt.is_open(), true)
	_equal("rebuilt gate is not offered again", rebuilt.is_offerable(), false)

	# And clearing the object forgets only that object.
	Flags.set_flag(&"unrelated/keep", true)
	rebuilt.state().clear()
	_equal("cleared object state is gone", Flags.has_flag(&"obj/global/t_gate/open"), false)
	_equal("unrelated flag survived", Flags.get_bool(&"unrelated/keep"), true)

	rebuilt.free()
	Flags.clear_all()


## The lever built by the gating test, if it is still alive.
func _lever_node() -> Lever:
	return _lever if _lever != null and is_instance_valid(_lever) else null
