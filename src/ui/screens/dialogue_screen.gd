class_name DialogueScreen
extends UiScreen
## The dialogue box. The first screen in this game that does NOT stop the world.
##
## WHY pauses_world IS FALSE, and why that distinction was built two packages early: a
## conversation happens in the world, in real time. The clock keeps running, the weather keeps
## turning, and an NPC three streets away keeps walking. Only the player's own input yields,
## and it yields through the `&"dialogue"` token its components already take on
## `Events.ui_mode_changed` and `Events.dialogue_started`. Nothing here locks anybody.
##
## closes_on_cancel IS ALSO FALSE. Escape must not dismiss a conversation: a conversation has
## effects, and a player who can escape out of the middle of one can skip the effect of the
## node they were about to reach. A conversation ends when it ends.
##
## TEXT SPEED was the first consumer of `gameplay/text_speed`, one of the settings that had been
## declared with nothing reading them; `accessibility/reduce_motion` is the second, and its
## effect is the reveal not happening at all. Reveal is by `visible_ratio`, so a
## half-revealed line is one property rather than a substring, and a translator's line with
## multibyte characters cannot be cut in the middle of one.
##
## OWNS: the box, the reveal, and which choice has focus.
## MUST NOT: decide what comes next, read or write a flag, pause anything, or lock the player.
## `DialogueRunner` owns all of that; this renders `line_changed` and forwards two inputs.

const SCREEN_ID: StringName = &"dialogue"
const CONTINUE_KEY: String = "ui.dialogue.continue"
## The reveal is this template's one piece of animated TEXT, so it is where reduce-motion has to
## be honoured. Named on the consumer, beside `gameplay/text_speed`, which this file already read.
const REDUCE_MOTION: String = "accessibility/reduce_motion"

## Tall enough for a speaker, two wrapped lines and four choices at once. Sized from the
## WORST case rather than the common one: the box is anchored to the bottom, so anything that
## does not fit is clipped off the bottom edge of the screen where nobody can scroll to it. A
## capture caught the third of three choices half cut off at 260.
const BOX_HEIGHT: float = 380.0
## Theme lookups, named once so a typo cannot become a control that silently draws black. Every
## size, colour and inset this screen uses comes from `gui/theme/custom` — see
## assets/theme/ui_theme.tres. Until T2.1 they were constants right here, and the same accent
## colour and the same 24pt were also written out in menu_screen.gd and inventory_screen.gd.
const PALETTE: StringName = &"UiPalette"
const METRICS: StringName = &"UiMetrics"
const SPEAKER_VARIATION: StringName = &"SpeakerText"
const LINE_VARIATION: StringName = &"DialogueText"
const CHOICE_VARIATION: StringName = &"ChoiceRow"
const HINT_VARIATION: StringName = &"HintText"
const TEXT_COLOUR: StringName = &"text"
const ACCENT_COLOUR: StringName = &"accent"
## Characters revealed per second at a text_speed of 1.0. Fast enough to read along with,
## slow enough that the reveal is visible at all.
const CHARS_PER_SECOND: float = 45.0

var runner: DialogueRunner = null

var _speaker: Label = null
var _line: Label = null
var _choice_box: VBoxContainer = null
var _hint: Label = null
var _revealed: float = 0.0
var _length: int = 0


func _init() -> void:
	screen_id = SCREEN_ID
	pauses_world = false
	closes_on_cancel = false


## Built with its runner already attached, so the screen never has to cope with being open and
## unbound. The caller starts the conversation AFTER opening, because `_build` runs from
## `_ready` and the first line has to have somewhere to land.
static func for_conversation() -> DialogueScreen:
	var screen := DialogueScreen.new()
	screen.runner = DialogueRunner.new()
	screen.runner.name = "DialogueRunner"
	return screen


func _build() -> void:
	add_child(runner)
	add_child(_dim_panel())

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", get_theme_constant(&"separation", METRICS))
	_speaker = _label("", SPEAKER_VARIATION, ACCENT_COLOUR)
	_line = _label("", LINE_VARIATION, TEXT_COLOUR)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override(
		&"separation", get_theme_constant(&"tight_separation", METRICS)
	)
	_hint = _label(tr(CONTINUE_KEY), HINT_VARIATION, ACCENT_COLOUR)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_speaker)
	column.add_child(_line)
	column.add_child(_choice_box)
	column.add_child(_hint)

	var frame := MarginContainer.new()
	# Anchored to the BOTTOM, not full-rect: the world above the box has to stay visible,
	# because the world is still running and the player is still standing in it.
	frame.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	frame.offset_top = -BOX_HEIGHT
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		frame.add_theme_constant_override(side, get_theme_constant(&"box_margin", METRICS))
	frame.add_child(column)
	add_child(frame)

	runner.line_changed.connect(_on_line_changed)
	runner.finished.connect(_on_finished)


## The reveal. Runs while the world does, because this screen does not pause it.
func _process(delta: float) -> void:
	if _line == null or _revealed >= float(_length):
		return
	_revealed += delta * CHARS_PER_SECOND * maxf(0.1, Settings.get_float("gameplay/text_speed"))
	_line.visible_ratio = clampf(_revealed / maxf(1.0, float(_length)), 0.0, 1.0)
	if _revealed >= float(_length):
		_show_choices()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(Actions.INTERACT):
		return
	get_viewport().set_input_as_handled()
	# First press completes the reveal, second advances. Skipping the reveal must never also
	# skip the line: a player pressing twice quickly would otherwise miss one entirely.
	if _revealed < float(_length):
		_finish_reveal()
		return
	if runner != null and not _waiting_on_choice():
		runner.advance()


## True while the player owes an answer. Read from the runner rather than from a flag here,
## so there is one truth about whether a branch is open.
func _waiting_on_choice() -> bool:
	return runner != null and not runner.available_choices().is_empty()


func _on_line_changed(node: DialogueNode, choices: Array[DialogueChoice]) -> void:
	_speaker.text = tr(node.speaker_key) if node.speaker_key != "" else ""
	_line.text = tr(node.text_key)
	_length = _line.text.length()
	_revealed = 0.0
	_line.visible_ratio = 0.0
	_clear_choices()
	# Choices are built but hidden until the line finishes revealing, so the answer cannot be
	# picked before the question has been read.
	for choice: DialogueChoice in choices:
		_choice_box.add_child(_choice_button(choice))
	_choice_box.visible = false
	_hint.visible = choices.is_empty()
	# AND THE CONSUMER OF `accessibility/reduce_motion`. A typewriter reveal is animated text,
	# which is precisely what a reduce-motion preference asks to be spared, so the line arrives
	# whole. Done here rather than by zeroing the rate in `_process`, because a rate of zero
	# would leave the choices hidden forever: `_show_choices` fires when the reveal COMPLETES,
	# and a reveal that never advances never completes.
	if Settings.get_bool(REDUCE_MOTION):
		_finish_reveal()


func _show_choices() -> void:
	if _choice_box.get_child_count() == 0:
		return
	_choice_box.visible = true
	var first: Button = _choice_box.get_child(0) as Button
	if first != null:
		first.grab_focus()


func _choice_button(choice: DialogueChoice) -> Button:
	var button := Button.new()
	button.text = tr(choice.text_key)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme_type_variation = CHOICE_VARIATION
	# Bound to the CHOICE, not to its index. The world keeps running behind this box, so a flag
	# written between building the button and pressing it can change which options are available
	# and shift every index by one - and the player would take a branch they did not pick.
	button.pressed.connect(_on_choice_pressed.bind(choice))
	return button


func _on_choice_pressed(choice: DialogueChoice) -> void:
	if runner != null:
		runner.take(choice)


func _finish_reveal() -> void:
	_revealed = float(_length)
	_line.visible_ratio = 1.0
	_show_choices()


func _clear_choices() -> void:
	for child: Node in _choice_box.get_children():
		_choice_box.remove_child(child)
		child.queue_free()


## The runner decides the conversation is over; the screen then asks to be closed. It does NOT
## free itself - the stack owns the lifetime, and this screen may not be the top of it.
func _on_finished(_talk_id: StringName) -> void:
	request_close()


## Belt and braces. A screen closed from outside - an area unloading, a load - must not leave
## the runner believing a conversation is still in progress, because the player's `&"dialogue"`
## token is released by `dialogue_finished` and nothing else would emit it.
func _closed() -> void:
	if runner != null and runner.is_running():
		runner.stop()


func _dim_panel() -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	rect.offset_top = -BOX_HEIGHT
	rect.color = get_theme_color(&"dim", PALETTE)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## A label in one of the theme's roles. The variation carries the size, the palette the colour —
## see assets/theme/ui_theme.tres for why those are not the same entry.
func _label(text_value: String, variation: StringName, colour: StringName) -> Label:
	var label := Label.new()
	label.text = text_value
	label.theme_type_variation = variation
	label.add_theme_color_override(&"font_color", get_theme_color(colour, PALETTE))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Has the current line finished revealing? Public so a capture can wait for it rather than
## photographing half a sentence, which reads as a truncation bug rather than a feature.
func reveal_complete() -> bool:
	return _revealed >= float(_length)
