extends TestCase
## The dialogue runner: conditions, branching, effects, and what happens to a conversation that
## is saved in the middle.
##
## THE HEADLINE ASSERTION IS _the_whole_exit_criterion(). One conversation that reads a flag,
## branches on it, sets another, and is then saved mid-line — which is the WP-05 criterion
## verbatim, walked in one go rather than inferred from four separate cases.
##
## Driven through the runner directly, never through the screen: `TestCase.run()` is
## synchronous, so a typewriter reveal that needs frames cannot be asserted here. What the box
## draws is proved by a windowed capture instead.
##
## OWNS: assertions about conversation data, condition evaluation, branching and effects.
## MUST NOT: assert what the dialogue box looks like, or re-assert the input lock. ui_test.gd
## owns the lock, and the capture owns the look.

const TALK: StringName = &"talk/gardener"
const MET: StringName = &"met/gardener"
const TALLY: StringName = &"count/gardener_talks"
const SLOT: int = 4

var _runner: DialogueRunner = null
var _lines: Array[StringName] = []
var _started: Array[StringName] = []
var _ended: Array[StringName] = []


func run() -> void:
	_set_up()
	_the_catalogue_is_sound()
	_conditions_choose_the_entry_point()
	_a_hidden_choice_is_omitted_not_disabled()
	_a_dangling_link_ends_it_rather_than_hanging()
	_the_whole_exit_criterion()
	_tear_down()


func _set_up() -> void:
	Flags.clear_all()
	DialogueDb.reload()
	_runner = DialogueRunner.new()
	_runner.name = "TestRunner"
	attach(_runner)
	_runner.line_changed.connect(_on_line_changed)
	Events.dialogue_started.connect(_on_started)
	Events.dialogue_finished.connect(_on_ended)


## The authored conversation, checked as data before anything walks it. A test that only walks
## the happy path passes on a conversation with three broken links in the branches nobody took.
func _the_catalogue_is_sound() -> void:
	equal("the gardener exists", DialogueDb.has(TALK), true)
	equal("and the catalogue is clean", DialogueDb.problems().size(), 0)
	var talk: Conversation = DialogueDb.conversation(TALK)
	equal("its id matches its filename", talk.id, TALK)
	equal("it has nodes", talk.nodes.size() > 0, true)
	equal("no dangling links anywhere in it", talk.problems().size(), 0)
	equal("an invented conversation is null", DialogueDb.conversation(&"talk/nobody"), null)


## The entry point is the first node whose condition PASSES, not nodes[0]. That is what makes
## "greet me differently once we have met" two nodes in authored order and no wiring at all.
func _conditions_choose_the_entry_point() -> void:
	Flags.clear_all()
	equal("a stranger is greeted", _runner.begin(TALK), true)
	equal("with the first-meeting line", _runner.current_node().node_id, &"greet_first")
	equal("and dialogue_started was announced", _started, [TALK] as Array[StringName])
	equal("arriving set the met flag", Flags.get_bool(MET), true)
	equal("a second begin is refused while running", _runner.begin(TALK), false)
	_runner.stop()
	equal("and dialogue_finished was announced", _ended, [TALK] as Array[StringName])

	equal("now the same call greets an acquaintance", _runner.begin(TALK), true)
	equal("with the other line", _runner.current_node().node_id, &"greet_again")
	equal("which counts the visit", Flags.get_int(TALLY), 1)
	_runner.stop()
	equal("and again", _runner.begin(TALK), true)
	equal("counting each time", Flags.get_int(TALLY), 2)
	_runner.stop()


## A choice whose condition fails is NOT SHOWN, and `choose(index)` indexes what is on screen
## rather than the authored array. The two differ the moment a condition hides an option, and
## indexing the wrong one silently takes the wrong branch.
func _a_hidden_choice_is_omitted_not_disabled() -> void:
	var talk: Conversation = DialogueDb.conversation(TALK)
	var menu: DialogueNode = talk.node(&"menu")
	equal("the menu exists", menu != null, true)
	var authored: int = menu.choices.size()
	equal("it has more than one option", authored > 1, true)

	# Hide the first option by giving it a condition that cannot pass right now.
	var hidden: DialogueChoice = menu.choices[0]
	var restore_flag: StringName = hidden.condition_flag
	var restore_test: GameEnums.FlagTest = hidden.condition_test
	hidden.condition_flag = &"test/never"
	hidden.condition_test = GameEnums.FlagTest.IS_TRUE

	Flags.clear_all()
	equal("the conversation opens", _runner.begin(TALK), true)
	_runner.advance()
	equal("we are at the menu", _runner.current_node().node_id, &"menu")
	var offered: Array[DialogueChoice] = _runner.available_choices()
	equal("one option is withheld", offered.size(), authored - 1)
	equal("and it is not the hidden one", offered.has(hidden), false)
	equal("choosing past the end is refused", _runner.choose(offered.size()), false)
	equal("and a negative index too", _runner.choose(-1), false)
	_runner.stop()

	hidden.condition_flag = restore_flag
	hidden.condition_test = restore_test
	Flags.clear_all()
	equal("restored, every option is offered again", _offered_count_at_menu(), authored)


## A `next_node` naming a node that does not exist must END the conversation and hand control
## back. The alternative is a player standing in a box with no way out, which is worse than a
## conversation that stops early.
func _a_dangling_link_ends_it_rather_than_hanging() -> void:
	var talk: Conversation = DialogueDb.conversation(TALK)
	var node: DialogueNode = talk.node(&"who")
	var restore: Array[DialogueChoice] = node.choices.duplicate()
	var restore_next: StringName = node.next_node
	node.choices = [] as Array[DialogueChoice]
	node.next_node = &"nowhere_at_all"

	Flags.clear_all()
	_ended.clear()
	equal("it opens", _runner.begin(TALK), true)
	_runner.advance()
	equal("at the menu", _runner.current_node().node_id, &"menu")
	equal("taking the first branch works", _runner.choose(0), true)
	equal("we reached the broken node", _runner.current_node().node_id, &"who")
	_runner.advance()
	equal("the dangling link ended it", _runner.is_running(), false)
	equal("and control was handed back", _ended, [TALK] as Array[StringName])

	node.choices = restore
	node.next_node = restore_next


## THE HEADLINE, and the WP-05 exit criterion walked end to end: read a flag, branch on it, set
## another, then save in the middle.
func _the_whole_exit_criterion() -> void:
	Flags.clear_all()
	Flags.set_flag(MET, true)
	_lines.clear()

	equal("it READ the flag and branched", _runner.begin(TALK), true)
	equal("taking the acquaintance line", _runner.current_node().node_id, &"greet_again")
	equal("and SET another flag on arrival", Flags.get_int(TALLY), 1)
	_runner.advance()
	equal("we are at the branch", _runner.current_node().node_id, &"menu")
	equal("every line was announced to the UI", _lines.size(), 2)
	equal("taking a branch moves us", _runner.choose(1), true)
	equal("to the node the choice named", _runner.current_node().node_id, &"gate")

	# SAVED MID-CONVERSATION. The conversation is deliberately not persisted: a saved node id
	# would make every node id in every .tres a permanent public identifier, and renaming one
	# would load old saves into a position that no longer exists.
	equal("the save succeeds", SaveSystem.save_to_slot(SLOT), OK)
	equal("and the conversation is still running for the player", _runner.is_running(), true)
	_ended.clear()

	equal("the load succeeds", SaveSystem.load_from_slot(SLOT), OK)
	equal("the conversation was ENDED rather than resumed", _runner.is_running(), false)
	equal("control was handed back", _ended.has(TALK), true)
	equal("the flags it set survived", Flags.get_bool(MET), true)
	equal("including the counter", Flags.get_int(TALLY), 1)
	SaveSystem.delete_slot(SLOT)


func _offered_count_at_menu() -> int:
	_runner.begin(TALK)
	_runner.advance()
	var count: int = _runner.available_choices().size()
	_runner.stop()
	return count


func _on_line_changed(node: DialogueNode, _choices: Array[DialogueChoice]) -> void:
	_lines.append(node.node_id)


func _on_started(talk_id: StringName) -> void:
	_started.append(talk_id)


func _on_ended(talk_id: StringName) -> void:
	_ended.append(talk_id)


func _tear_down() -> void:
	if _runner != null:
		_runner.stop()
	if Events.dialogue_started.is_connected(_on_started):
		Events.dialogue_started.disconnect(_on_started)
	if Events.dialogue_finished.is_connected(_on_ended):
		Events.dialogue_finished.disconnect(_on_ended)
	# The .tres resources are CACHED and static, so any field this case edited would leak into
	# every later case and into the running game. Reloading is the only honest reset.
	DialogueDb.reload()
	Flags.clear_all()
	_runner = null
