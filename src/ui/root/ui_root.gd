class_name UiRoot
extends Control
## The screen stack, and the one place in this game that decides whether gameplay input is
## being read right now.
##
## THE PROBLEM THIS EXISTS TO KILL
## Before this file there was no home for modal UI at all. `InteractionSensor` polled input
## every physics frame with no notion of an open screen, and the only hand-over mechanism was
## a single boolean on `PlayerController`. Build the inventory screen first and you get one
## boolean per screen, forever, each one owned by a different file and each one able to clear
## the others. So the stack comes first and every screen is built on it.
##
## PAUSE IS NOT A BLUNT INSTRUMENT. This does set `get_tree().paused`, but which nodes that
## actually stops is decided node by node, and here is the whole table:
##
##     WorldRoot and everything under it   pausable   this is the point of pausing
##     Clock, Weather                      pausable   in-game time must not pass behind a menu
##     Audio                               ALWAYS     music and ambience keep playing
##     Director                            ALWAYS     a transition in flight must still finish
##     ScreenFade                          ALWAYS     a pause mid-fade must not stick on black
##     NotificationToast                   ALWAYS     a queued toast must not freeze half-shown
##     InteractPrompt                      pausable   gameplay UI; it hides on ui_mode_changed
##     UiRoot and the top screen           ALWAYS     they have to answer the button that closes
##     DevCapture                          ALWAYS     a capture of a paused screen must work
##
## Each of those is set in the owning node's own _ready(), never from here. This comment is
## the index, not the implementation - a central pause that reaches into ten nodes is the
## god object all over again.
##
## OWNS: the stack, the tree's paused state, and the UiMode announcement.
## MUST NOT: know what any screen contains, know the player exists, or read gameplay input.
## It announces the mode; the player's own components take their own lock on hearing it.

## Anything may find the stack with UiRoot.find(node) rather than a hard-coded scene path,
## which would break the first time the UI tree is rearranged.
const GROUP: StringName = &"ui_root"

var _stack: Array[UiScreen] = []
var _mode: GameEnums.UiMode = GameEnums.UiMode.GAMEPLAY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# IGNORE, not STOP: the host must not swallow clicks meant for the world. Each screen sets
	# MOUSE_FILTER_STOP on itself, so only an actually-open screen blocks the pointer.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(GROUP)
	Log.info("ui", "Screen stack ready")


## A stack that leaves the tree while it holds a pause would strand the game paused with
## nothing left alive to unpause it. Area teardown and quit both go through here.
func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if _stack.is_empty():
		return
	if not event.is_action_pressed(Actions.CANCEL) and not event.is_action_pressed(Actions.PAUSE):
		return
	if not _stack[-1].closes_on_cancel:
		return
	get_viewport().set_input_as_handled()
	close_top()


## THE ONE TRUTH. Everything that reads gameplay input answers to this, either by calling it
## or by listening to the ui_mode_changed it drives.
func is_gameplay_input_allowed() -> bool:
	return _stack.is_empty()


func mode() -> GameEnums.UiMode:
	return _mode


func depth() -> int:
	return _stack.size()


func top() -> UiScreen:
	return _stack[-1] if not _stack.is_empty() else null


func has_screen(screen_id: StringName) -> bool:
	for screen: UiScreen in _stack:
		if screen.screen_id == screen_id:
			return true
	return false


## Put a screen on top. The stack takes ownership from here: it adds the child, and closing is
## what frees it. Returns false for a null screen or one that is already open.
func open(screen: UiScreen) -> bool:
	if screen == null:
		Log.error("ui", "Refused to open a null screen")
		return false
	if _stack.has(screen):
		Log.warn("ui", "Screen '%s' is already open" % screen.screen_id)
		return false
	_stack.append(screen)
	add_child(screen)
	# DEFERRED so a screen asking to close cannot free itself from inside its own emission,
	# which is a crash rather than a bug report.
	screen.close_requested.connect(_on_close_requested.bind(screen), CONNECT_DEFERRED)
	_settle()
	screen.notify_opened()
	Log.info("ui", "Opened '%s' at depth %d" % [screen.screen_id, _stack.size()])
	return true


## Close the topmost screen. Returns false when there was nothing to close, so a caller can
## tell "I dismissed a menu" from "cancel meant something else".
func close_top() -> bool:
	if _stack.is_empty():
		return false
	return _close(_stack[-1])


## Unwind everything, top first. For an area change or a return to the main menu.
func close_all() -> void:
	while not _stack.is_empty():
		if not _close(_stack[-1]):
			return


func _close(screen: UiScreen) -> bool:
	if not _stack.has(screen):
		return false
	_stack.erase(screen)
	screen.notify_closed()
	remove_child(screen)
	screen.queue_free()
	_settle()
	# The screen underneath has REACHED THE TOP OF THE STACK AGAIN, which is exactly what
	# `_opened` is documented to mean - "each time the screen reaches the top" - and until WP-12
	# this call was missing, so it only ever meant "once". Without it a menu backed out of is
	# visible and processing but has no focused row, and a player on a gamepad is stranded on a
	# menu that answers nothing. Found by the WP-12 input probe; no assertion could press the
	# escape that reveals it.
	var revealed: UiScreen = top()
	if revealed != null:
		revealed.notify_opened()
	Log.info("ui", "Closed '%s', depth now %d" % [screen.screen_id, _stack.size()])
	return true


func _on_close_requested(screen: UiScreen) -> void:
	if is_instance_valid(screen):
		var closed: bool = _close(screen)
		if not closed:
			Log.warn("ui", "A screen asked to close twice")


## Re-derive everything the stack implies, in one place, after every push and pop. Only the
## top screen processes: a covered screen must not answer the button that closes the one on
## top of it. And only the top screen is DRAWN - see below.
func _settle() -> void:
	var last: int = _stack.size() - 1
	for index: int in _stack.size():
		var covered: bool = index != last
		_stack[index].process_mode = Node.PROCESS_MODE_DISABLED if covered else Node.PROCESS_MODE_ALWAYS
		# A COVERED SCREEN IS NOT DRAWN EITHER. Every screen in this game dims rather than
		# blanks, on purpose, so that the stopped world stays visible behind it - which means
		# two of them stacked let the lower one's rows print through the upper one's. A WP-12
		# capture caught the pause menu's status line running through the settings screen's
		# first heading. Visibility of a covered screen is stack business, not screen business,
		# so it is derived here with everything else rather than fixed in one screen's panel.
		_stack[index].visible = not covered
	var next: GameEnums.UiMode = _derive_mode()
	if is_inside_tree():
		get_tree().paused = next == GameEnums.UiMode.MODAL
	if next == _mode:
		return
	_mode = next
	var names: Array = GameEnums.UiMode.keys()
	var label: String = names[_mode]
	Log.debug("ui", "Mode -> %s" % label)
	Events.ui_mode_changed.emit(_mode)


## Any pausing screen anywhere in the stack pauses the world, not just the top one. Otherwise
## a confirmation overlay dropped over the inventory would quietly restart the clock behind it.
func _derive_mode() -> GameEnums.UiMode:
	if _stack.is_empty():
		return GameEnums.UiMode.GAMEPLAY
	for screen: UiScreen in _stack:
		if screen.pauses_world:
			return GameEnums.UiMode.MODAL
	return GameEnums.UiMode.OVERLAY


## The stack, found by group rather than by path. Returns null before the UI tree is built,
## which callers must handle: a dev tool or a test may run without one.
static func find(from: Node) -> UiRoot:
	if from == null or not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group(GROUP) as UiRoot
