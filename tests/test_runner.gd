extends Node
## Rung 4 of the verification ladder: headless integration tests with the real autoloads live.
## This file is a dispatcher. The assertions live in tests/unit/, one file per area.
##
## RUN:
##     godot_console --headless res://tests/test_runner.tscn --quit-after 200
##
## Exit code 0 if every assertion passes, 1 otherwise, so this gates a commit or CI.
##
## WHY THIS IS A SCENE AND NOT A --script TOOL
## Under `--headless --script foo.gd` the autoload *nodes* are created, but the autoload
## *identifiers* (Log, Flags, SaveSystem) fail to compile - proven, the error is
## `Compile Error: Identifier not found: Log`. So no test that touches a system can be a
## --script tool. It has to be a scene, entered positionally.
##
## WHY THE SUITE IS SPLIT
## This file reached 184 of its 250 code lines with its largest case at 35 of the 40 allowed
## per function. Rather than raise the budget - the move that turns a file into 3,983 lines
## twenty reasonable lines at a time - the cases moved into tests/unit/ behind a TestCase base.
##
## OWNS: discovering cases, tallying them, and the exit code.
## MUST NOT: contain assertions of its own, or any game logic.

const CASES: Array[String] = [
	"res://tests/unit/core_test.gd",
	"res://tests/unit/world_test.gd",
	"res://tests/unit/interaction_test.gd",
	"res://tests/unit/items_test.gd",
	"res://tests/unit/pickups_test.gd",
	"res://tests/unit/traversal_test.gd",
	"res://tests/unit/ui_test.gd",
	"res://tests/unit/screens_test.gd",
]

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	Log.info("test", "=== test run starting ===")
	# Determinism: a clock that advances mid-assertion makes time assertions flaky.
	Clock.paused = true

	for path: String in CASES:
		_run_case(path)

	Log.info("test", "=== %d passed, %d failed ===" % [_passed, _failed])
	for failure: String in _failures:
		Log.error("test", "FAILED: %s" % failure)
	get_tree().quit(1 if _failed > 0 else 0)


func _run_case(path: String) -> void:
	var script: GDScript = load(path) as GDScript
	if script == null:
		_record_load_failure(path, "could not be loaded")
		return
	# Object, then a cast: casting a Variant directly would trip the unsafe_cast warning.
	var instance: Object = script.new()
	var test_case: TestCase = instance as TestCase
	if test_case == null:
		_record_load_failure(path, "does not extend TestCase")
		return

	test_case.name = path.get_file().get_basename()
	add_child(test_case)
	Log.debug("test", "--- %s ---" % test_case.name)
	test_case.run()

	_passed += test_case.passed
	_failed += test_case.failed
	_failures.append_array(test_case.failures)
	# Free explicitly: anything left alive at exit fills the log with leaked-RID errors, and
	# that noise is how a real error gets lost.
	test_case.free()


func _record_load_failure(path: String, why: String) -> void:
	_failed += 1
	_failures.append("%s %s" % [path, why])
	Log.error("test", "case %s %s" % [path, why])
