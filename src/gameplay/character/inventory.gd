class_name Inventory
extends Node
## What one carrier is holding. A COMPONENT, not an autoload, and not only for the player.
##
## WHY NOT AN AUTOLOAD - the question everyone asks, and the answer is load-bearing.
## The only things that need to find a bag are interactables, and the interaction contract
## already hands them the interactor: `attempt(who)` -> `refusal(who)` / `perform(who)`. So
## `of(who)` resolves it with no global at all, and it resolves it better: a gate then asks
## "does WHOEVER IS OPENING ME carry the key?", which is also true for an NPC, a follower or
## a stash. A global inventory would hard-code "there is exactly one bag in the universe"
## into every interactable in the game. The player already outlives every area (GameRoot
## spawns them once and Director repositions them), so an autoload would buy no lifetime this
## node does not have. Adding an autoload needs an ADR; this one would have nothing to put in
## it. And an autoload table of services is where `PlayerState` is born, which is one rename
## from `GameManager`.
##
## THE DATA SHAPE is item id -> count. No slots, no stack objects. That is what makes the save
## section one flat readable dictionary, and it is exactly as much structure as an inventory
## with no screen can justify. Slots later become a change to can_accept() alone.
##
## OWNS: the counts it holds, its capacity rule, and its save section.
## MUST NOT: know where an item came from, how items are displayed, or what any item does.

const CATEGORY: String = "inventory"
const SAVE_VERSION: int = 1

## Unique per carrier. A second bag - a stash, a cart, an NPC satchel - MUST override this:
## two participants sharing an id means the second silently replaces the first and one of
## them never saves at all.
@export var save_id: StringName = &"inventory"

var _counts: Dictionary[StringName, int] = {}


func _ready() -> void:
	SaveSystem.register(save_id, _collect_save, _apply_save, SAVE_VERSION)


func _exit_tree() -> void:
	# ADR-0004 names the dead-callable cost of a freed participant. This is how it is paid.
	SaveSystem.unregister(save_id)


## The one way anything finds a carrier's bag. Scans children by type rather than by node
## name, so renaming the node cannot silently disconnect every interactable in the game.
static func of(who: Node) -> Inventory:
	if who == null:
		return null
	for child: Node in who.get_children():
		var bag: Inventory = child as Inventory
		if bag != null:
			return bag
	return null


## THE CAPACITY SEAM. Every caller asks this one question before offering the player
## anything, so slots, weight or a carry-strength skill go HERE and nowhere else - no item
## and no caller changes. Capacity is currently unlimited, so the only rule enforced is the
## definition's own max_stack.
func can_accept(item_id: StringName, count: int = 1) -> bool:
	if count <= 0:
		return false
	var definition: ItemDefinition = ItemDb.definition(item_id)
	if definition == null:
		Log.warn(CATEGORY, "No definition for '%s' — refusing it" % item_id)
		return false
	return count_of(item_id) + count <= definition.max_stack


## All or nothing, deliberately. A partial add with no inventory screen is invisible to the
## player and awkward to reason about; when a UI can show "3 of 5 taken", add add_up_to().
func add(item_id: StringName, count: int = 1) -> bool:
	if not can_accept(item_id, count):
		return false
	_counts[item_id] = count_of(item_id) + count
	Events.item_gained.emit(item_id, count)
	Events.inventory_changed.emit()
	Log.debug(CATEGORY, "+%d %s (now %d)" % [count, item_id, count_of(item_id)])
	return true


func remove(item_id: StringName, count: int = 1) -> bool:
	if count <= 0 or count_of(item_id) < count:
		return false
	var left: int = count_of(item_id) - count
	if left > 0:
		_counts[item_id] = left
	else:
		_counts.erase(item_id)
	Events.item_lost.emit(item_id, count)
	Events.inventory_changed.emit()
	return true


func count_of(item_id: StringName) -> int:
	return _counts[item_id] if _counts.has(item_id) else 0


func has(item_id: StringName, count: int = 1) -> bool:
	return count_of(item_id) >= count


func distinct_count() -> int:
	return _counts.size()


func total_count() -> int:
	var total: int = 0
	for item_id: StringName in _counts:
		total += _counts[item_id]
	return total


## Stable display order for a future UI: category, then id. Deliberately NOT sorted by
## translated name - that would put tr() in a gameplay file and make the order change with
## the language. The UI re-sorts by display name when it exists.
func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for item_id: StringName in _counts:
		out.append(item_id)
	out.sort_custom(_before)
	return out


func clear_all() -> void:
	_counts.clear()
	Events.inventory_changed.emit()


func _before(a: StringName, b: StringName) -> bool:
	var first: ItemDefinition = ItemDb.definition(a)
	var second: ItemDefinition = ItemDb.definition(b)
	if first == null or second == null:
		return String(a) < String(b)
	if first.category != second.category:
		return first.category < second.category
	return String(a) < String(b)


func _collect_save() -> Dictionary:
	# StringName keys become strings in JSON and come back as strings, exactly as Flags does.
	var out: Dictionary = {}
	for item_id: StringName in _counts:
		out[String(item_id)] = _counts[item_id]
	return out


## Counts whose definition has since disappeared are KEPT, not dropped: a definition missing
## because someone renamed a .tres must never silently delete a player's key item. Lookups
## warn and ids() falls back to sorting by id, so the item stays visible and recoverable.
func _apply_save(data: Dictionary, _from_version: int) -> void:
	_counts.clear()
	for key: String in data:
		var amount: int = DictRead.get_int(data, key, 0)
		if amount > 0:
			_counts[StringName(key)] = amount
	Log.info(CATEGORY, "Restored %d distinct items, %d total" % [distinct_count(), total_count()])
	# inventory_changed only. item_gained means "the player just got something" and would fire
	# pickup toasts on every load - the same reason Gate restores without announcing.
	Events.inventory_changed.emit()
