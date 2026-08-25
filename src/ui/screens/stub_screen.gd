class_name StubScreen
extends UiScreen
## Proof that the stack works, and deliberately nothing else. It exists so WP-02 can be
## verified without WP-03: a real screen would drag in a HUD, an inventory model and a theme,
## and then a failure could be any of those rather than the stack.
##
## Open it with `godot_console -- --open-screen` and look at the capture. What the picture has
## to show is that the world is still drawn behind it and has stopped moving, and what the
## keyboard has to show is that escape gives control back.
##
## DELETE THIS FILE once two real screens exist. It is scaffolding, and scaffolding that
## outlives the building becomes furniture.
##
## OWNS: two labels and a dim panel.
## MUST NOT: grow. It is not the pause menu and it is not the template for one. A real screen
## is a UiScreen with actual content; this one is a placeholder for a photograph.

const TITLE_KEY: String = "ui.stub.title"
const HINT_KEY: String = "ui.stub.hint"
const SCREEN_ID: StringName = &"stub"

const DIM: Color = Color(0.04, 0.03, 0.06, 0.82)
const TITLE_SIZE: int = 64
const HINT_SIZE: int = 28


func _build() -> void:
	screen_id = SCREEN_ID
	pauses_world = true
	add_child(_panel())
	add_child(_line(TITLE_KEY, TITLE_SIZE, -70.0, 20.0))
	add_child(_line(HINT_KEY, HINT_SIZE, 40.0, 100.0))


## Translucent rather than opaque on purpose: the frozen world has to stay visible behind the
## screen, because "the world is still there and has stopped" is the thing being verified.
func _panel() -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.color = DIM
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _line(key: String, size: int, top: float, bottom: float) -> Label:
	var label := Label.new()
	# _and_offsets_ again. With set_anchors_preset alone this Label is zero-width and the text
	# lands off the left edge of the screen, which has already cost this project an hour once.
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.offset_left = 0.0
	label.offset_right = 0.0
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_top = top
	label.offset_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", size)
	label.text = tr(key)
	return label
