class_name InventoryScreen
extends UiScreen
## What the player is carrying, as a window. The first screen with real content in it.
##
## THE SCREEN IS DUMB, AND THAT IS THE DESIGN. It reads `Inventory.ids()` — already sorted by
## category then id, in the gameplay layer, where the sort belongs — and draws a row for each.
## It holds no rules: not what may be carried, not what an item does, not whether a stack is
## full. Every one of those questions has an owner already, and a screen that starts answering
## them is how a UI file becomes the second implementation of the game.
##
## IT ALSO DOES NOT PAUSE ANYTHING. It declares `pauses_world` and `UiRoot` does the rest; it
## never touches `get_tree().paused`, never locks the player, and never asks whether another
## screen is open. See src/ui/screens/ui_screen.gd for why that split exists.
##
## THE CARRIER IS INJECTED, not looked up. `for_carrier(who)` mirrors the interaction
## contract's `attempt(who)`: the same screen shows an NPC's satchel or a stash without
## knowing that `Director` or a player exists.
##
## OWNS: the rows it draws and which one has focus.
## MUST NOT: add, remove or reorder items, or reach for a global inventory.

const SCREEN_ID: StringName = &"inventory"
const TITLE_KEY: String = "ui.inventory.title"
const EMPTY_KEY: String = "ui.inventory.empty"
const HINT_KEY: String = "ui.inventory.hint"
const ROW_KEY: String = "ui.inventory.row"
const UNKNOWN_KEY: String = "ui.inventory.unknown"
const CATEGORY_PREFIX: String = "item.category."

const DIM: Color = Color(0.04, 0.03, 0.06, 0.78)
const HEADING_TINT: Color = Color(0.86, 0.74, 0.52)
const TITLE_SIZE: int = 40
const HEADING_SIZE: int = 20
const ROW_SIZE: int = 24
const HINT_SIZE: int = 18
const MARGIN: int = 64

var _list: VBoxContainer = null
var _inventory: Inventory = null


## Identity is set in _init, NOT in _build. _build runs from _ready, i.e. after the caller has
## had its chance to override a flag, so setting `pauses_world` there would silently discard
## an overlay's request to keep the world running.
func _init() -> void:
	screen_id = SCREEN_ID
	pauses_world = true
	closes_on_cancel = true


## Bind the bag before opening. A null carrier is not an error: the screen renders empty and
## says so, which is what a stash with nothing in it should look like anyway.
static func for_carrier(who: Node) -> InventoryScreen:
	var screen := InventoryScreen.new()
	screen._inventory = Inventory.of(who)
	if screen._inventory == null:
		Log.warn("ui", "Inventory screen opened with no bag to show")
	return screen


func _build() -> void:
	add_child(_dim_panel())
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	column.add_child(_label(TITLE_KEY, TITLE_SIZE, Color.WHITE))
	column.add_child(_scroller())
	column.add_child(_label(HINT_KEY, HINT_SIZE, HEADING_TINT))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, MARGIN)
	margin.add_child(column)
	add_child(margin)


## Bound to the signal only while the screen is open. A closed screen is about to be freed and
## a live connection to a bag that outlives it is a dead callable waiting to happen.
func _opened() -> void:
	if not Events.inventory_changed.is_connected(_on_inventory_changed):
		Events.inventory_changed.connect(_on_inventory_changed)
	refresh()


func _closed() -> void:
	if Events.inventory_changed.is_connected(_on_inventory_changed):
		Events.inventory_changed.disconnect(_on_inventory_changed)


## Public so a test can drive it without a frame. Rebuilds every row: an inventory of a few
## dozen entries redrawn on a change the player caused is not worth a diffing scheme.
func refresh() -> void:
	if _list == null:
		return
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	# A typed local, then a conditional assignment. `x if c else [] as Array[StringName]` is a
	# RUNTIME cast failure in 4.7: the empty literal is a plain Array and the ternary is typed
	# from it, so the assignment throws every time the bag is empty and the suite still passes.
	var ids: Array[StringName] = []
	if _inventory != null:
		ids = _inventory.ids()
	if ids.is_empty():
		_list.add_child(_label(EMPTY_KEY, ROW_SIZE, Color.WHITE))
		return
	_fill(ids)
	_focus_first()


## ids() arrives grouped by category already, so a heading is emitted wherever the category
## changes rather than by scanning the enum and asking the bag eight times.
func _fill(ids: Array[StringName]) -> void:
	var last: String = ""
	for item_id: StringName in ids:
		var definition: ItemDefinition = ItemDb.definition(item_id)
		var heading: String = _category_key(definition)
		if heading != last:
			last = heading
			_list.add_child(_label(heading, HEADING_SIZE, HEADING_TINT))
		_list.add_child(_row(item_id, definition))


## A row is a Button so it can take focus — that is the whole of the keyboard and gamepad
## navigation in this package, because a VBoxContainer of focusable children already answers
## ui_up and ui_down. Pressing one does nothing yet; use and tooltips are WP-09 and beyond.
func _row(item_id: StringName, definition: ItemDefinition) -> Button:
	var name_key: String = definition.name_key if definition != null else UNKNOWN_KEY
	var button := Button.new()
	button.add_theme_font_size_override(&"font_size", ROW_SIZE)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = tr(ROW_KEY).format({
		"item": tr(name_key).format({"id": String(item_id)}),
		"count": _inventory.count_of(item_id),
	})
	return button


func _focus_first() -> void:
	for child: Node in _list.get_children():
		var button: Button = child as Button
		if button != null:
			button.grab_focus()
			return


func _on_inventory_changed() -> void:
	refresh()


## A missing definition still gets a heading rather than being dropped. Inventory keeps counts
## whose .tres has vanished on purpose, so the screen has to be able to show one.
func _category_key(definition: ItemDefinition) -> String:
	if definition == null:
		return UNKNOWN_KEY
	return "%s%s" % [CATEGORY_PREFIX, definition.category_name().to_lower()]


## Translucent, not opaque: the frozen world stays visible behind the screen, which is how a
## capture shows that opening this stopped the world rather than left it.
func _dim_panel() -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.color = DIM
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _scroller() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", 6)
	scroll.add_child(_list)
	return scroll


func _label(key: String, size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
