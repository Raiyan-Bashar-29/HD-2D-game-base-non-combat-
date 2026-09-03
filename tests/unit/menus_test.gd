extends TestCase
## The menus as SCREENS: what each one offers, what raises it, and what closes it.
##
## THE HEADLINE ASSERTION IS _flags_are_declared_in_init(). `StubScreen` once set its flags in
## `_build`, which runs from `_ready` - i.e. after a caller has had its chance to override one -
## and that made the overlay assertion in ui_test.gd pass vacuously for a whole package. Every
## screen this package adds is checked against it twice: on a fresh instance that has never been
## built, and again through an override that has to survive being built.
##
## THE SECOND IS _travel_unwinds_the_stack(). No screen in this game closes the stack it is
## standing on; `ScreenKeys` does it once, for every screen, on `area_change_requested`. If that
## ever stops working, a menu survives a transition and sits over an area that no longer exists,
## which is exactly the bug WP-04 spent a package finding in the interaction prompt.
##
## Driven by direct calls, never by simulated input: TestCase.run() is synchronous, so an input
## event never reaches the frame that would deliver it.
##
## THIS CASE OWNS user://saves FOR THE RUN. It empties every slot at set-up, because "a first
## run offers no Continue" is not assertable while a slot exists, and empties them again after.
##
## OWNS: assertions about menu rows, what raises a menu, and slot headers.
## MUST NOT: re-assert the pause table or the input lock (ui_test.gd), what the inventory
## renders (screens_test.gd), or how a setting or a binding changes (options_test.gd).

const PROBE_SLOT: int = 2

var _stack: UiRoot = null
var _keys: ScreenKeys = null


func run() -> void:
	plan(98)
	_set_up()
	_every_menu_is_reachable_by_name()
	_flags_are_declared_in_init()
	_the_main_menu_omits_what_it_cannot_offer()
	_the_pause_key_binds_to_the_pause_menu()
	_backing_out_returns_focus()
	_travel_unwinds_the_stack()
	_the_slot_list_reads_headers()
	_the_keys_these_menus_draw_exist()
	_tear_down()


func _set_up() -> void:
	_stack = UiRoot.new()
	attach(_stack)
	_keys = ScreenKeys.new()
	attach(_keys)
	for slot: int in SaveSystem.MAX_SLOTS:
		SaveSystem.delete_slot(slot)


## One factory, five menus. A capture flag naming a screen on the command line goes through the
## same call the pause key does, so a photographed screen is the real one.
func _every_menu_is_reachable_by_name() -> void:
	var ids: Array[StringName] = [
		MainMenuScreen.SCREEN_ID, PauseMenuScreen.SCREEN_ID, SettingsScreen.SCREEN_ID,
		SaveScreen.SCREEN_ID, RebindScreen.SCREEN_ID,
	]
	for menu_id: StringName in ids:
		var screen: UiScreen = ScreenKeys.menu_for(menu_id)
		equal("menu_for builds '%s'" % menu_id, screen != null, true)
		if screen == null:
			continue
		equal("and '%s' declares that id" % menu_id, screen.screen_id, menu_id)
		equal("and '%s' stops the world" % menu_id, screen.pauses_world, true)
		screen.free()
	equal("an id nobody claims builds nothing", ScreenKeys.menu_for(&"no_such_menu") == null, true)


## Read on a FRESH instance, before _build could possibly have run, and then again through an
## override that has to survive being built. See the file header.
func _flags_are_declared_in_init() -> void:
	var main := MainMenuScreen.new()
	equal("the main menu is not yet built", main.rows == null, true)
	equal("and already knows cancel cannot dismiss it", main.closes_on_cancel, false)
	equal("and that it is opaque", main.opaque, true)
	main.free()

	var pause := PauseMenuScreen.new()
	equal("the pause menu can be cancelled out of", pause.closes_on_cancel, true)
	equal("and is translucent, so the stopped world shows through it", pause.opaque, false)
	pause.free()

	var overlay := SettingsScreen.new()
	overlay.pauses_world = false
	equal("the stack opens the overridden screen", _stack.open(overlay), true)
	equal("_build did NOT discard the override", overlay.pauses_world, false)
	equal("so the mode is OVERLAY, not MODAL", _stack.mode(), GameEnums.UiMode.OVERLAY)
	equal("cleanup", _stack.close_top(), true)


## Continue and Load are omitted on a first run, not shown disabled - the same reasoning the
## dialogue system omits a failing choice by.
func _the_main_menu_omits_what_it_cannot_offer() -> void:
	equal("no slot has been written", SaveSystem.latest_slot(), -1)
	var menu := MainMenuScreen.new()
	equal("the main menu opens", _stack.open(menu), true)
	var rows: Array[String] = menu.row_texts()
	equal("a first run offers four rows", rows.size(), 4)
	equal("the first is New Game", rows[0], tr(MainMenuScreen.NEW_KEY))
	equal("and it has focus, so a gamepad can start", _focused_text(menu), rows[0])
	equal("the last is Quit", rows[3], tr(MainMenuScreen.QUIT_KEY))

	equal("a save is written", SaveSystem.save_to_slot(PROBE_SLOT), OK)
	equal("and it is now the latest", SaveSystem.latest_slot(), PROBE_SLOT)
	menu.refresh()
	rows = menu.row_texts()
	equal("now the menu offers six", rows.size(), 6)
	equal("Continue names the slot it would restore", rows[1].contains(str(PROBE_SLOT + 1)), true)
	equal("and Load has appeared under it", rows[2], tr(MainMenuScreen.LOAD_KEY))
	equal("cleanup", _stack.close_top(), true)


## The same shape as the inventory key: the key that raised the screen closes it, and only when
## that screen is itself on top.
func _the_pause_key_binds_to_the_pause_menu() -> void:
	equal("the pause key opens the pause menu", _keys.toggle_pause_menu(_stack), true)
	equal("the stack has it", _stack.has_screen(PauseMenuScreen.SCREEN_ID), true)
	equal("and the world is stopped", _stack.mode(), GameEnums.UiMode.MODAL)
	equal("its first row is Resume", _top_menu().row_texts()[1], tr(PauseMenuScreen.RESUME_KEY))
	equal("under a status line that is not a button", _button_count(_top_menu()) < _top_menu().row_texts().size(), true)
	equal("pressing it again closes it", _keys.toggle_pause_menu(_stack), true)
	equal("and the stack is empty", _stack.depth(), 0)

	var other := SettingsScreen.new()
	equal("something else is on top", _stack.open(other), true)
	equal("the pause key does not reach past it", _keys.toggle_pause_menu(_stack), false)
	equal("and opened nothing", _stack.depth(), 1)
	equal("cleanup", _stack.close_top(), true)


## THE BUG THE WP-12 INPUT PROBE FOUND, and the reason `UiRoot._close` now notifies the screen
## it revealed. Focus follows the sub-screen when one opens, and does not come back on its own,
## so before this a player who backed out of Settings faced a pause menu with nothing selected
## and a gamepad that did nothing at all. Every other gate passed: no error, no warning, and a
## capture of either screen alone looks perfect.
func _backing_out_returns_focus() -> void:
	var pause := PauseMenuScreen.new()
	equal("the pause menu opens", _stack.open(pause), true)
	var first: String = _focused_text(pause)
	equal("and its first row has focus", first != "", true)

	equal("settings opens over it", _stack.open(SettingsScreen.new()), true)
	equal("the covered menu lost focus to the new top", _focused_text(pause), "")
	equal("backing out succeeds", _stack.close_top(), true)
	equal("and the menu underneath has focus again", _focused_text(pause), first)
	equal("cleanup", _stack.close_top(), true)


## No screen unwinds the stack it is standing on; travel does, in one place, for all of them.
func _travel_unwinds_the_stack() -> void:
	equal("the pause menu opens", _stack.open(PauseMenuScreen.new()), true)
	equal("and a settings screen over it", _stack.open(SettingsScreen.new()), true)
	equal("two deep", _stack.depth(), 2)
	_keys.unwind()
	equal("travel closes every one of them", _stack.depth(), 0)
	equal("and hands the world back", _stack.mode(), GameEnums.UiMode.GAMEPLAY)


## Headers are read out of the file, and reading one can never apply it.
func _the_slot_list_reads_headers() -> void:
	equal("hours and minutes, zero-padded", MenuScreen.played_as_text(3725.0), "01:02")
	equal("and a fresh run is zero", MenuScreen.played_as_text(0.0), "00:00")
	equal("a negative playtime cannot happen, and does not misprint", MenuScreen.played_as_text(-5.0), "00:00")

	var loading := SaveScreen.new()
	equal("the load list opens", _stack.open(loading), true)
	equal("it faces the reading way", loading.writing, false)
	equal("and wears the load title", loading.title_key, SaveScreen.LOAD_TITLE_KEY)
	equal("all six slots are listed", loading.row_texts().size(), SaveSystem.MAX_SLOTS)
	equal("but only the written one can be pressed", _button_count(loading), 1)

	var info: Dictionary = SaveSystem.slot_info(PROBE_SLOT)
	equal("reading a header does not carry the payload", info.has("sections"), false)
	equal("the row names the slot", loading.slot_text(PROBE_SLOT).contains(str(PROBE_SLOT + 1)), true)
	equal("and carries the stamp out of the file",
		loading.slot_text(PROBE_SLOT).contains(DictRead.get_string(info, "saved_utc", "?")), true)
	equal("an empty slot says empty", loading.slot_text(0), tr(SaveScreen.EMPTY_KEY).format({"slot": 1}))
	equal("cleanup", _stack.close_top(), true)
	_the_save_list_faces_the_other_way()


func _the_save_list_faces_the_other_way() -> void:
	var writing := SaveScreen.for_saving()
	equal("the save list opens", _stack.open(writing), true)
	equal("it faces the writing way", writing.writing, true)
	equal("and wears the save title", writing.title_key, SaveScreen.SAVE_TITLE_KEY)
	equal("every slot can be written, empty or not", _button_count(writing), SaveSystem.MAX_SLOTS)
	equal("cleanup", _stack.close_top(), true)


## tr() returns the key itself when a row is missing, so a key that renders as its own name is
## the failure mode. options_test.gd covers the COMPUTED keys; these are the literal ones.
func _the_keys_these_menus_draw_exist() -> void:
	for key: String in [
		MainMenuScreen.TITLE_KEY, MainMenuScreen.NEW_KEY, MainMenuScreen.CONTINUE_KEY,
		MainMenuScreen.LOAD_KEY, MainMenuScreen.SETTINGS_KEY, MainMenuScreen.CONTROLS_KEY,
		MainMenuScreen.QUIT_KEY, PauseMenuScreen.TITLE_KEY, PauseMenuScreen.STATUS_KEY,
		PauseMenuScreen.RESUME_KEY, PauseMenuScreen.SAVE_KEY, PauseMenuScreen.MAIN_MENU_KEY,
		PauseMenuScreen.HINT_KEY, SaveScreen.SAVE_TITLE_KEY, SaveScreen.LOAD_TITLE_KEY,
		SaveScreen.SLOT_KEY, SaveScreen.EMPTY_KEY, SaveScreen.HINT_KEY, SaveScreen.SAVED_KEY,
		SaveScreen.FAILED_KEY,
	]:
		equal("key %s is translated" % key, tr(key) != key, true)


func _top_menu() -> MenuScreen:
	return _stack.top() as MenuScreen


func _button_count(screen: MenuScreen) -> int:
	var count: int = 0
	for child: Node in screen.rows.get_children():
		var button: Button = child as Button
		if button != null and not button.is_queued_for_deletion():
			count += 1
	return count


func _focused_text(screen: MenuScreen) -> String:
	for child: Node in screen.rows.get_children():
		var button: Button = child as Button
		if button != null and button.has_focus():
			return button.text
	return ""


func _tear_down() -> void:
	if _stack != null:
		_stack.close_all()
		_stack = null
	get_tree().paused = false
	for slot: int in SaveSystem.MAX_SLOTS:
		SaveSystem.delete_slot(slot)
	_keys = null
