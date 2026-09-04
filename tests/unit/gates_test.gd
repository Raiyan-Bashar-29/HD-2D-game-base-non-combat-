extends TestCase
## The three enforcement gates T5.4 added, and the one structural question none of the four
## older gates asked: DOES A DECLARED THING HAVE A CONSUMER?
##
## WHY A CASE AT ALL, WHEN THE GATES ARE ALREADY IN THE LADDER. A checker that runs is not a
## checker that WORKS. Each of the three was proved red by planting a real violation and green
## by removing it, and both results are in DEVLOG.md — but a plant is a one-off, and the thing
## that rots afterwards is the CLASSIFIER: the four lines that decide whether a reference is an
## emit or a connect, whether a path is core or ui, whether a key names content. Those are
## static, pure, and take strings, so they are assertable here, at every run, forever. This is
## gotcha 42's lesson applied to the tools themselves: assert the mechanism, not the fact that
## the file exists.
##
## THE METHOD TRAP IS THE ASSERTION THAT MATTERS MOST. Three quest signals are dispatched
## INDIRECTLY, as first-class `Signal` values handed to a helper that calls `.emit` on them, so
## a naive scan for `quest_started.emit` finds zero sites and would report three false
## positives. Measured, at the time of writing: 0, 0 and 0 direct sites for `quest_started`,
## `quest_advanced` and `quest_completed`. The dispatch-role classifier is what tells them
## apart from a genuinely dead declaration, and it is asserted below in both directions.
##
## NO FIXTURE CONTENT IS ACTIVATED and no demo name appears: every string below is synthetic
## GDScript written for the assertion, which is what lets `check_boundary.gd` scan this file.
##
## OWNS: the three classifiers, and the fact that each tool's own gate is wired into the ladder.
## MUST NOT: run a checker (they call quit(), which would end the suite), name demo content, or
## assert a violation COUNT — that is a property of today's tree, not a contract.

const LAYERS_TOOL = preload("res://tools/check_layers.gd")
const SIGNALS_TOOL = preload("res://tools/check_signals.gd")
const BOUNDARY_TOOL = preload("res://tools/check_boundary.gd")
const REGISTRY: String = "res://src/core/events/events.gd"
const WORKFLOW: String = "res://.github/workflows/ladder.yml"

## Every checker in the ladder, and the CI step that must run it. A gate nobody runs is a
## document, which is the state the layer rule was in until this package.
const LADDER: Array[String] = [
	"tools/check_budgets.gd", "tools/check_content.gd", "tools/check_boundary.gd",
	"tools/check_strings.gd", "tools/check_layers.gd", "tools/check_signals.gd",
]


func run() -> void:
	plan(33)
	_the_layer_of_a_path_comes_from_the_path()
	_an_indirect_signal_reference_is_read_from_its_files_dispatch()
	_a_whole_word_match_is_shared_by_both_gates()
	_a_reserved_signal_says_so_where_the_reader_is_looking()
	_every_checker_is_wired_into_the_ladder()


## LAYER IS DERIVED, NEVER LISTED, which is what stops the gate going stale when a file moves.
## The index IS the ordering, so the whole rule reduces to one integer comparison.
func _the_layer_of_a_path_comes_from_the_path() -> void:
	var tool_script := LAYERS_TOOL
	equal("core is layer 0", tool_script.layer_of("res://src/core/log/log.gd"), 0)
	equal("content is layer 1", tool_script.layer_of("res://src/content/item/thing.gd"), 1)
	equal("systems is layer 2", tool_script.layer_of("res://src/systems/audio/a.gd"), 2)
	equal("gameplay is layer 3", tool_script.layer_of("res://src/gameplay/world/b.gd"), 3)
	equal("ui is layer 4", tool_script.layer_of("res://src/ui/hud/c.gd"), 4)
	equal("outside src/ is not a layer", tool_script.layer_of("res://tests/unit/d.gd"), -1)


## THE TRAP, ASSERTED IN BOTH DIRECTIONS. A file that calls `.emit` on a `Signal`-typed
## identifier is an emitter and its bare bus references are emit sites; a file that calls
## `.connect` on one is a listener. A file that does neither returns 0, and a bare reference in
## it is counted as nothing — the conservative direction, because it can only ever produce a
## reported failure, never a missed violation.
func _an_indirect_signal_reference_is_read_from_its_files_dispatch() -> void:
	var tool_script := SIGNALS_TOOL
	var emitter: String = "func f(fact: Signal, a: Array) -> void:\n\tfact.emit.callv(a)\n"
	var listener: String = "func g() -> void:\n\tfor fact: Signal in _f():\n\t\tfact.connect(h)\n"
	equal("a helper that emits a Signal parameter is an emitter",
		tool_script._dispatch_role(emitter), 1)
	equal("a loop that connects a Signal is a listener",
		tool_script._dispatch_role(listener), -1)
	equal("a file with no Signal-typed identifier has no role",
		tool_script._dispatch_role("func h() -> void:\n\tpass\n"), 0)
	equal("a Signal declared and never used has no role",
		tool_script._dispatch_role("func i(fact: Signal) -> void:\n\tpass\n"), 0)


## ONE DEFINITION OF "NAMES THIS IDENTIFIER" FOR BOTH GATES, so a fix to one is a fix to both.
## The substring version was a real defect: an item called `pear` failed on the word `appeared`.
func _a_whole_word_match_is_shared_by_both_gates() -> void:
	var boundary := BOUNDARY_TOOL
	var layers := LAYERS_TOOL
	equal("a bare identifier matches", boundary.names_whole_word("var x: Thing = null", "Thing"),
		true)
	equal("a longer word does not",
		boundary.names_whole_word("var x: ThingBase = null", "Thing"), false)
	equal("a prefixed word does not",
		boundary.names_whole_word("var x: SubThing = null", "Thing"), false)
	equal("the layer gate uses the same definition",
		layers.names_whole_word("var x: ThingBase = null", "Thing"), false)
	equal("and agrees on a real match",
		layers.names_whole_word("load(\"res://a/Thing.gd\")", "Thing"), true)


## THE ESCAPE HATCH IS A PHRASE IN THE DECLARATION'S OWN DOC BLOCK, not a list inside the tool,
## so the next reader of the signal sees the decision without opening anything. Two signals
## carry it today and both say WHY in the same breath; this asserts the mechanism is present
## and spelled the one way the gate reads, because a typo in it silently un-exempts a signal.
func _a_reserved_signal_says_so_where_the_reader_is_looking() -> void:
	var tool_script := SIGNALS_TOOL
	var phrase: String = tool_script.RESERVED
	var source: String = FileAccess.get_file_as_string(REGISTRY)
	equal("the phrase is not empty", phrase.is_empty(), false)
	equal("the registry loads", source.is_empty(), false)
	equal("the registry declares at least one reserved signal", source.contains(phrase), true)
	var reserved: int = source.split(phrase).size() - 1
	equal("and the phrase is uppercase, so prose cannot grant an exemption by accident",
		phrase, phrase.to_upper())
	equal("every use of it sits in a comment", _all_uses_are_comments(source, phrase), reserved)


func _all_uses_are_comments(source: String, phrase: String) -> int:
	var found: int = 0
	for line: String in source.split("\n"):
		if line.contains(phrase) and line.strip_edges().begins_with("#"):
			found += 1
	return found


## SIX CHECKERS NOW, NOT FOUR, AND CI MUST NAME EACH ONE AS ITS OWN STEP so a failure says
## which gate failed rather than "the ladder". This is the assertion that would have caught a
## gate written, committed, and never wired — which is the defect the whole package is about,
## applied to the package itself.
func _every_checker_is_wired_into_the_ladder() -> void:
	var workflow: String = FileAccess.get_file_as_string(WORKFLOW)
	equal("the workflow loads", workflow.is_empty(), false)
	for checker: String in LADDER:
		equal("CI runs %s" % checker, workflow.contains(checker), true)
		equal("%s exists" % checker, FileAccess.file_exists("res://" + checker), true)
