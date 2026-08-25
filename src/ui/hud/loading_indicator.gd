extends Label
## What the player looks at while the curtain is black.
##
## THE ONE THING DRAWN ABOVE THE FADE, and the only exception to the rule in `ui_root.gd`'s
## header that `ScreenFade` is the last child of `UILayer`. The curtain has to cover every
## screen; this has to be visible while the curtain is up, so it sits after it. Child order in
## a `CanvasLayer` is draw order, and that ordering is the entire mechanism.
##
## It reads `Events.area_load_progress` rather than polling `ResourceLoader`, so the path
## template lives in exactly one file. Between the request and the first progress report there
## is no ratio to show, which is why it shows the word first and the percentage only once
## there is one.
##
## PROCESS_MODE_ALWAYS: a transition in flight must still finish behind a pause, so the thing
## reporting on it has to keep drawing too. Pause table: src/ui/root/ui_root.gd.
##
## OWNS: the loading text and its visibility.
## MUST NOT: load anything, know which area is loading beyond the id it is handed, or decide
## when a transition ends. It renders three signals.

const LOADING_KEY: String = "ui.loading.working"
const PROGRESS_KEY: String = "ui.loading.progress"
const FONT_SIZE: int = 20


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# _and_offsets_ matters: set_anchors_preset alone leaves a zero-size box and the text
	# lands off the corner.
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	offset_top = -70.0
	offset_bottom = -30.0
	offset_right = -32.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	text = ""
	visible = false

	Events.area_unloading.connect(_on_area_unloading)
	Events.area_load_progress.connect(_on_progress)
	Events.area_entered.connect(_on_area_entered)


## Shown from the moment the old area starts leaving, not from the first progress report: the
## fade out happens before the load begins, and a blank black screen with nothing on it is
## indistinguishable from a hang.
func _on_area_unloading(_area_id: StringName) -> void:
	text = tr(LOADING_KEY)
	visible = true


func _on_progress(_area_id: StringName, ratio: float) -> void:
	if not visible:
		return
	text = tr(PROGRESS_KEY).format({"percent": roundi(clampf(ratio, 0.0, 1.0) * 100.0)})


## Hidden on area_entered, which fires before the fade in begins, so the last frame the player
## sees behind the curtain is the one where loading finished.
func _on_area_entered(_area_id: StringName) -> void:
	text = ""
	visible = false
