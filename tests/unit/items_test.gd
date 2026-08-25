extends TestCase
## The item catalogue, the inventory, and whether every computed localization key resolves.
##
## OWNS: assertions about content data and carrying it.
## MUST NOT: assert about world objects - pickups and containers are pickups_test.

var _carrier: Node3D = null
var _bag: Inventory = null
var _gained: Array = []
var _changes: int = 0


func run() -> void:
	ItemDb.reload()
	_registry()
	_build_carrier()
	_inventory()
	_signals()
	_save_round_trip()
	_localization()
	_tear_down()


## The claim under test is docs/ARCHITECTURE.md's "adding the fiftieth item must not touch a
## single line of code". So this counts the files on disk rather than hard-coding three: add a
## fourth .tres and this case still passes, which is the whole point. It also cross-checks the
## undocumented ResourceLoader.list_directory against a plain DirAccess listing, so a change
## in either fails here instead of silently shrinking the catalogue.
func _registry() -> void:
	equal("catalogue has no problems: %s" % str(ItemDb.problems()), ItemDb.problems().is_empty(), true)

	var on_disk: int = 0
	for file_name: String in DirAccess.get_files_at(ItemDb.ITEM_DIR):
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			on_disk += 1
	equal("registry found every definition on disk", ItemDb.count(), on_disk)
	equal("registry found at least the three authored", ItemDb.count() >= 3, true)

	var key_def: ItemDefinition = ItemDb.definition(&"item/rose_key")
	equal("rose_key exists", key_def != null, true)
	equal("rose_key id", String(key_def.id), "item/rose_key")
	equal("rose_key is unique", key_def.is_unique(), true)
	equal("rose_key is a key item", key_def.category, GameEnums.ItemCategory.KEY_ITEM)
	equal("rose_key category name", key_def.category_name(), "KEY_ITEM")
	equal("petals stack", ItemDb.definition(&"item/rose_petal").max_stack, 20)

	# A typo is a null, not a crash.
	equal("unknown id returns null", ItemDb.definition(&"item/nope"), null)
	equal("unknown id is not has()", ItemDb.has(&"item/nope"), false)


## A bare Node3D, not the player scene: this also proves Inventory.of() works on any carrier,
## which is the reason it is a component rather than an autoload.
func _build_carrier() -> void:
	_carrier = Node3D.new()
	_bag = Inventory.new()
	# Set before add_child: _ready registers with SaveSystem under this id, and colliding with
	# the real player's "inventory" would make one of them silently never save.
	_bag.save_id = &"test_bag"
	_carrier.add_child(_bag)
	add_child(_carrier)
	equal("of() finds the bag on its carrier", Inventory.of(_carrier), _bag)
	var empty_carrier: Node3D = Node3D.new()
	equal("of() on a carrier with no bag is null", Inventory.of(empty_carrier) == null, true)
	empty_carrier.free()
	equal("of(null) is null", Inventory.of(null) == null, true)


func _inventory() -> void:
	equal("starts empty", _bag.total_count(), 0)
	equal("add a petal", _bag.add(&"item/rose_petal", 3), true)
	equal("count reflects it", _bag.count_of(&"item/rose_petal"), 3)
	equal("has enough", _bag.has(&"item/rose_petal", 3), true)
	equal("does not have more", _bag.has(&"item/rose_petal", 4), false)
	equal("stacks onto the same entry", _bag.add(&"item/rose_petal", 2), true)
	equal("stacked count", _bag.count_of(&"item/rose_petal"), 5)
	equal("one distinct item", _bag.distinct_count(), 1)

	# max_stack is the only capacity rule while capacity itself is unlimited.
	equal("cannot exceed max_stack", _bag.add(&"item/rose_petal", 20), false)
	equal("refused add changed nothing", _bag.count_of(&"item/rose_petal"), 5)
	equal("a unique item can be held once", _bag.add(&"item/rose_key"), true)
	equal("but not twice", _bag.add(&"item/rose_key"), false)
	equal("an unknown item is refused", _bag.add(&"item/nope"), false)

	equal("remove some", _bag.remove(&"item/rose_petal", 2), true)
	equal("count after remove", _bag.count_of(&"item/rose_petal"), 3)
	equal("cannot remove more than held", _bag.remove(&"item/rose_petal", 99), false)
	equal("failed remove changed nothing", _bag.count_of(&"item/rose_petal"), 3)
	equal("removing all erases the entry", _bag.remove(&"item/rose_petal", 3), true)
	equal("entry gone", _bag.count_of(&"item/rose_petal"), 0)
	equal("only the key remains", _bag.distinct_count(), 1)

	# Order is category then id, so a future UI has a stable grouping that does not shift
	# with the display language.
	_bag.add(&"item/stone_chip", 1)
	var order: Array[StringName] = _bag.ids()
	equal("key items sort before materials", String(order[0]), "item/rose_key")


func _signals() -> void:
	_gained = []
	_changes = 0
	var on_gain: Callable = func(id: StringName, n: int) -> void: _gained.append([id, n])
	var on_change: Callable = func() -> void: _changes += 1
	Events.item_gained.connect(on_gain)
	Events.inventory_changed.connect(on_change)

	_bag.add(&"item/rose_petal", 2)
	equal("item_gained fired once", _gained.size(), 1)
	equal("item_gained carried the count added, not the total", _gained[0][1], 2)
	equal("inventory_changed fired", _changes, 1)

	# A refused add must be completely silent, or a UI would flicker on every failed grab.
	_bag.add(&"item/rose_key")
	equal("a refused add emits nothing", _changes, 1)

	Events.item_gained.disconnect(on_gain)
	Events.inventory_changed.disconnect(on_change)


func _save_round_trip() -> void:
	SaveSystem.unregister(&"world")
	var slot: int = SaveSystem.MAX_SLOTS - 2
	equal("save the bag", SaveSystem.save_to_slot(slot), OK)

	var petals: int = _bag.count_of(&"item/rose_petal")
	_bag.clear_all()
	equal("scrambled", _bag.total_count(), 0)

	equal("load the bag", SaveSystem.load_from_slot(slot), OK)
	equal("petals restored", _bag.count_of(&"item/rose_petal"), petals)
	equal("key restored", _bag.has(&"item/rose_key"), true)
	SaveSystem.delete_slot(slot)


## Verb and refusal keys are BUILT at runtime from enum names, so no text-scanning validator
## can ever follow them. An enum loop is the only thing that can, and tr() returning the key
## unchanged is exactly how a missing translation presents.
func _localization() -> void:
	var verbs: Array = GameEnums.InteractVerb.keys()
	var missing_verbs: int = 0
	for index: int in verbs.size():
		var raw: String = verbs[index]
		var key: String = "verb.%s" % raw.to_lower()
		if tr(key) == key:
			missing_verbs += 1
			Log.warn("test", "no translation for %s" % key)
	equal("every InteractVerb has a translation", missing_verbs, 0)

	var reasons: Array = GameEnums.RefusalReason.keys()
	var missing_reasons: int = 0
	for index: int in reasons.size():
		var raw: String = reasons[index]
		# refusal.none is deliberately blank: NONE means "allowed", so it is never displayed.
		if raw == "NONE":
			continue
		var key: String = "refusal.%s" % raw.to_lower()
		if tr(key) == key:
			missing_reasons += 1
			Log.warn("test", "no translation for %s" % key)
	equal("every RefusalReason has a translation", missing_reasons, 0)

	var missing_names: int = 0
	for item_id: StringName in ItemDb.all():
		var definition: ItemDefinition = ItemDb.definition(item_id)
		if tr(definition.name_key) == definition.name_key:
			missing_names += 1
			Log.warn("test", "no translation for %s" % definition.name_key)
	equal("every item name has a translation", missing_names, 0)

	# The substitution the toast relies on. Without it a pickup could not name what was taken.
	equal("toast placeholder substitutes", tr("notify.item_taken").format({"item": "Thing"}).contains("Thing"), true)


func _tear_down() -> void:
	_carrier.free()
	_carrier = null
	_bag = null
