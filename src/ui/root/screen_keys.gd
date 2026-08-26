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
## OWNS: the action-to-screen and request-to-screen bindings, the one factory that turns a menu
## id into a screen, and unwinding the stack when the world travels.
## MUST NOT: hold a reference to any screen, pause anything, or decide what a screen shows.

const CATEGORY: String = "ui"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# A conversation is REQUESTED by something in the gameplay layer, which must not name a
	# screen. This is the ui-side half of that hand-over.
	Events.dialogue_requested.connect(_on_dialogue_requested)
	# So is the main menu, and GameRoot is in `core`, which may not name a `ui` class at all.
	Events.main_menu_requested.connect(_on_main_menu_requested)
	# THE STACK UNWINDS HERE, which is why no screen in this game calls close_all() on the stack
	# it is standing on. Every travel goes through this one signal - a door, a load, a new game -
	# so a menu left open across a transition cannot end up over an area that no longer exists.
	Events.area_change_requested.connect(_on_area_change_requested)


## Marked handled only when a binding actually did something, so an unclaimed press falls
## through to UiRoot - which is what lets ESCAPE close the inventory even though escape is also
## the pause key.
func _unhandled_input(event: InputEvent) -> void:
	var stack: UiRoot = UiRoot.find(self)
	if stack == null:
		return
	if event.is_action_pressed(Actions.PAUSE) and toggle_pause_menu(stack):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(Actions.INVENTORY) and toggle_inventory(stack):
		get_viewport().set_input_as_handled()


## Same shape as toggle_inventory, and for the same reason: the key that raised a screen closes
## it again, and only when that screen is ITSELF on top. Pressing pause under a settings screen
## must not reach past it, and pressing it during a conversation must not stop the world.
func toggle_pause_menu(stack: UiRoot) -> bool:
	var top: UiScreen = stack.top()
	if top != null and top.screen_id == PauseMenuScreen.SCREEN_ID:
		return stack.close_top()
	if not stack.is_gameplay_input_allowed():
		return false
	return stack.open(PauseMenuScreen.new())


## Every menu this game can be asked for by name, and how one is made. The ONE factory: a dev
## capture naming a screen on the command line must not become a second place that knows how a
## screen is constructed.
static func menu_for(menu_id: StringName) -> UiScreen:
	if menu_id == MainMenuScreen.SCREEN_ID:
		return MainMenuScreen.new()
	if menu_id == PauseMenuScreen.SCREEN_ID:
		return PauseMenuScreen.new()
	if menu_id == SettingsScreen.SCREEN_ID:
		return SettingsScreen.new()
	if menu_id == SaveScreen.SCREEN_ID:
		return SaveScreen.new()
	if menu_id == RebindScreen.SCREEN_ID:
		return RebindScreen.new()
	Log.error(CATEGORY, "No menu is named '%s'" % menu_id)
	return null


## Idempotent on purpose. GameRoot asks on boot and the pause menu asks on its way out; a second
## main menu stacked on the first would be unreachable and un-closable, because the main menu is
## the one screen in the game that cancel cannot dismiss.
func _on_main_menu_requested() -> void:
	var stack: UiRoot = UiRoot.find(self)
	if stack == null:
		Log.error(CATEGORY, "No UiRoot in the tree; the main menu cannot be shown")
		return
	if stack.has_screen(MainMenuScreen.SCREEN_ID):
		return
	stack.open(MainMenuScreen.new())


## DEFERRED: the request usually arrives from inside a menu row's own `pressed` handler, and
## unwinding the stack that owns the button mid-emission is a crash rather than a bug report -
## the same reasoning UiRoot connects `close_requested` deferred for.
func _on_area_change_requested(_area_id: StringName, _spawn_id: StringName) -> void:
	unwind.call_deferred()


## Close every screen. Separate from the handler above and public so the suite can assert what
## the deferred call does - TestCase.run() is synchronous and never reaches the idle frame a
## deferred call lands on. That the deferral itself works is proved by the boot run's log.
func unwind() -> void:
	var stack: UiRoot = UiRoot.find(self)
	if stack != null and stack.depth() > 0:
		stack.close_all()


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
