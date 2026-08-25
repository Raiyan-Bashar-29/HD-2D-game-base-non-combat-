class_name ScreenKeys
extends Node
## The one place a thing becomes a screen: an input action, or a request on the bus.
##
## WHY THIS IS A NODE OF ITS OWN
## `UiRoot` must not know what a screen contains, and the player must not know a screen
## exists. Something still has to say "I opens the inventory", and if that binding lives in
## either of them, then the journal key, the map key and the pause key each end up in a
## different file — which is where a boolean per screen came from last time. One node holds
## the whole table, and WP-08's journal and WP-11's map join it here.
##
## PROCESS_MODE_ALWAYS, so the key that opened a screen can also close it while the world is
## paused. It never asks "is a screen open" with a flag of its own: `UiRoot.top()` and
## `is_gameplay_input_allowed()` are the only truth, and this node reads them.
##
## OWNS: the action-to-screen and request-to-screen bindings.
## MUST NOT: hold a reference to any screen, pause anything, or decide what a screen shows.

const CATEGORY: String = "ui"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# A conversation is REQUESTED by something in the gameplay layer, which must not name a
	# screen. This is the ui-side half of that hand-over.
	Events.dialogue_requested.connect(_on_dialogue_requested)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(Actions.INVENTORY):
		return
	var stack: UiRoot = UiRoot.find(self)
	if stack == null:
		Log.error(CATEGORY, "No UiRoot in the tree; %s does nothing" % Actions.INVENTORY)
		return
	get_viewport().set_input_as_handled()
	toggle_inventory(stack)


## Toggle rather than open: the key that raised a screen closing it again is what every player
## expects, and CANCEL closing the top is the stack's business either way.
##
## Only when the inventory is ITSELF on top. Pressing I under a confirmation prompt must not
## reach past it, and pressing it during a conversation must not open a second window over one.
func toggle_inventory(stack: UiRoot) -> bool:
	var top: UiScreen = stack.top()
	if top != null and top.screen_id == InventoryScreen.SCREEN_ID:
		return stack.close_top()
	if not stack.is_gameplay_input_allowed():
		return false
	return stack.open(InventoryScreen.for_carrier(Director.player))


## Open the dialogue box and start the conversation in it. The runner is a component of the
## screen, so opening the screen IS starting the conversation and the two cannot get out of
## step - the alternative, a global runner the UI observes, is one more thing that can be
## running while nothing is on screen.
##
## Returns nothing on purpose: the asker already emitted and moved on. A conversation with
## nothing to say closes immediately rather than leaving an empty box.
func _on_dialogue_requested(talk_id: StringName) -> void:
	var stack: UiRoot = UiRoot.find(self)
	if stack == null:
		Log.error(CATEGORY, "No UiRoot in the tree; '%s' cannot be said" % talk_id)
		return
	var screen: DialogueScreen = DialogueScreen.for_conversation()
	if not stack.open(screen):
		return
	# AFTER opening, never before: _build runs from _ready, which runs on add_child, so the
	# first line has nowhere to land until the screen is in the tree.
	if not screen.runner.begin(talk_id):
		stack.close_top()
