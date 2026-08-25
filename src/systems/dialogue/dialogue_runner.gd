class_name DialogueRunner
extends Node
## Walks a Conversation: picks the next node, tests conditions, applies effects, and announces
## what should be on screen. The only thing in the game that reads dialogue data.
##
## A COMPONENT, NOT AN AUTOLOAD, and for the same reason as `Inventory`. Adding an autoload
## needs an ADR and this one would have nothing to put in it: the runner has no lifetime the
## UI layer does not already have, and a global would hard-code "there is exactly one
## conversation in the universe", which is wrong the first time an NPC talks to another NPC.
## `DialogueScreen` owns one.
##
## IT DOES NOT DRAW ANYTHING AND IT DOES NOT PAUSE ANYTHING. It emits `line_changed` and
## `finished`; the screen renders them, and `UiRoot` decides what an open screen does to the
## world. `Events.dialogue_started` and `dialogue_finished` were declared in Phase 0 and are
## already listened to by `PlayerController` and `InteractionSensor`, which take their own
## `&"dialogue"` token, so nothing here locks the player either.
##
## MID-CONVERSATION SAVES ARE REFUSED, LOUDLY. See `_collect_save`.
##
## OWNS: the current position in a conversation, condition evaluation and effect application.
## MUST NOT: draw, pause, lock input, or know what any flag means.

## The line to show now. `choices` is empty for a plain line.
signal line_changed(node: DialogueNode, choices: Array[DialogueChoice])
## The conversation ended, for any reason including a dangling link.
signal finished(talk_id: StringName)

const CATEGORY: String = "dialogue"
const SAVE_ID: StringName = &"dialogue"

var _talk: Conversation = null
var _node: DialogueNode = null


func _ready() -> void:
	SaveSystem.register(SAVE_ID, _collect_save, _apply_save)


func _exit_tree() -> void:
	SaveSystem.unregister(SAVE_ID)


## Begin a conversation by id. Returns false if there is nothing to say, so a caller can tell
## "I opened a conversation" from "that speaker has no lines right now".
func begin(talk_id: StringName) -> bool:
	if is_running():
		Log.warn(CATEGORY, "Refusing '%s': '%s' is still running" % [talk_id, _talk.id])
		return false
	var found: Conversation = DialogueDb.conversation(talk_id)
	if found == null:
		Log.error(CATEGORY, "No conversation '%s'" % talk_id)
		return false
	_talk = found
	# The entry point is the first node whose condition passes, NOT nodes[0]. That is what lets
	# "if we have met, greet me differently" be two nodes in authored order and no wiring.
	_node = _first_passing()
	if _node == null:
		Log.warn(CATEGORY, "'%s' has no node whose condition passes right now" % talk_id)
		_talk = null
		return false
	Events.dialogue_started.emit(talk_id)
	_arrive(_node)
	return true


func is_running() -> bool:
	return _talk != null


func current_node() -> DialogueNode:
	return _node


func conversation_id() -> StringName:
	return _talk.id if _talk != null else &""


## The choices the player may actually see: those whose condition passes. A failing choice is
## omitted rather than shown disabled. See the header of dialogue_choice.gd.
func available_choices() -> Array[DialogueChoice]:
	var out: Array[DialogueChoice] = []
	if _node == null:
		return out
	for choice: DialogueChoice in _node.choices:
		if choice == null:
			continue
		if _passes(choice.condition_flag, choice.condition_test, choice.condition_value):
			out.append(choice)
	return out


## Move on from a plain line. Does nothing while the node is waiting on a choice, so a stray
## advance cannot skip a branch the player has not answered.
func advance() -> void:
	if _node == null or _node.has_choices():
		return
	_go_to(_node.next_node)


## Take a branch. The index is into `available_choices()`, i.e. into what is on screen, not into
## the authored array: the two differ whenever a condition hid an option.
func choose(index: int) -> bool:
	var offered: Array[DialogueChoice] = available_choices()
	if index < 0 or index >= offered.size():
		Log.warn(CATEGORY, "Choice %d is not on offer" % index)
		return false
	_go_to(offered[index].target_node)
	return true


## End it early: the player walked away, an area is unloading, a save was loaded. Safe to call
## when nothing is running.
func stop() -> void:
	if _talk == null:
		return
	var ended: StringName = _talk.id
	_talk = null
	_node = null
	Events.dialogue_finished.emit(ended)
	finished.emit(ended)


func _go_to(node_id: StringName) -> void:
	if node_id == &"":
		stop()
		return
	var next: DialogueNode = _talk.node(node_id)
	if next == null:
		# Recoverable, deliberately. A dangling link ends the conversation and hands control
		# back rather than leaving the player stuck in a box with no way out of it.
		Log.error(CATEGORY, "'%s' leads to '%s', which does not exist" % [_talk.id, node_id])
		stop()
		return
	_node = next
	_arrive(next)


## Effects fire on ARRIVAL, so a node has the same consequence however it was reached.
func _arrive(node: DialogueNode) -> void:
	_apply_effect(node)
	line_changed.emit(node, available_choices())


## THE SEAM for many effects per node. When a conversation genuinely needs two, this method
## loops and `effect_flag` becomes an array, and every .tres authored so far stays valid.
func _apply_effect(node: DialogueNode) -> void:
	if node.effect_write == GameEnums.FlagWrite.NONE or node.effect_flag == &"":
		return
	match node.effect_write:
		GameEnums.FlagWrite.SET_TRUE:
			Flags.set_flag(node.effect_flag, true)
		GameEnums.FlagWrite.SET_FALSE:
			Flags.set_flag(node.effect_flag, false)
		GameEnums.FlagWrite.SET_INT:
			Flags.set_flag(node.effect_flag, node.effect_value)
		GameEnums.FlagWrite.ADD:
			Flags.advance(node.effect_flag, node.effect_value)


## The first node whose condition passes. Falling THROUGH a failed node to the next in authored
## order is what makes a conversation read like a script rather than like a graph.
func _first_passing() -> DialogueNode:
	for entry: DialogueNode in _talk.nodes:
		if entry == null:
			continue
		if _passes(entry.condition_flag, entry.condition_test, entry.condition_value):
			return entry
	return null


func _passes(flag: StringName, test: GameEnums.FlagTest, value: int) -> bool:
	if test == GameEnums.FlagTest.ALWAYS or flag == &"":
		return true
	match test:
		GameEnums.FlagTest.IS_TRUE:
			return Flags.get_bool(flag, false)
		GameEnums.FlagTest.IS_FALSE:
			return not Flags.get_bool(flag, false)
		GameEnums.FlagTest.EQUALS:
			return Flags.get_int(flag, 0) == value
		GameEnums.FlagTest.AT_LEAST:
			return Flags.get_int(flag, 0) >= value
		GameEnums.FlagTest.AT_MOST:
			return Flags.get_int(flag, 0) <= value
	return true


## A CONVERSATION IS NOT SAVED, and that is a decision rather than an omission.
##
## Persisting a position would mean writing a node id into the save file, which makes every node
## id in every .tres a permanent public identifier: rename one and old saves load into a
## conversation position that no longer exists. The cost is that a save taken mid-conversation
## resumes with the conversation over and control returned, which is recoverable and obvious,
## where the alternative fails silently, later, in someone else's save file.
##
## So the section exists, is always empty, and SAYS SO when it discards something.
func _collect_save() -> Dictionary:
	if is_running():
		Log.warn(CATEGORY, "Saving during '%s'; the conversation is not saved" % _talk.id)
	return {}


func _apply_save(_data: Dictionary, _from_version: int) -> void:
	if is_running():
		Log.info(CATEGORY, "Load ended '%s' and returned control" % _talk.id)
	stop()
