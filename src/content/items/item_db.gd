class_name ItemDb
extends RefCounted
## Every ItemDefinition in the project, found by scanning data/items and cached by id.
##
## WHY A SCAN AND NOT A LIST
## docs/ARCHITECTURE.md's test is "adding the fiftieth item must not touch a single line of
## code". A hand-maintained registry fails that outright. A generated manifest fails it
## quietly, which is worse: a forgotten regeneration is indistinguishable from an item that
## was never added, and silent-wrong is the failure mode this project exists to prevent.
## A scan is the only option where dropping a .tres in a folder is the entire act.
##
## WHY TWO SCANNING METHODS
## ResourceLoader.list_directory() is the right tool - it understands the .remap indirection
## an exported .pck uses, which a raw DirAccess listing does not. But its documentation
## description is EMPTY in 4.7.2, i.e. undocumented, so its behaviour is treated as unproven:
## probed output showed bare filenames, _normalise handles full paths too, and DirAccess
## remains a fallback that is known to work from source. The test suite cross-checks the two
## counts, so a change in either fails a gate rather than silently shrinking the catalogue.
##
## WHY STATIC AND NOT AN AUTOLOAD
## It holds no mutable game state, has no lifecycle, is never saved and needs no init order,
## so an autoload would need an ADR and buy nothing. Decisively: an autoload CANNOT be used
## by tools/check_content.gd, because autoload identifiers do not resolve under
## `--headless --script` - the validator would have to duplicate the very loading code it is
## meant to test. A static class is shared verbatim by the game, the tests and the tool.
##
## OWNS: finding definitions on disk, caching them by id, and reporting what is wrong.
## MUST NOT: hold inventory state, know who carries anything, or touch an autoload. Problems
## are RETURNED, never logged, for the reason above.

const ITEM_DIR: String = "res://data/items"

## The directory actually scanned. A CONTENT ROOT rather than a constant: a game may keep its
## items somewhere else, and the test fixtures point it at a temp directory so this registry
## can be proved with no authored content on disk at all. Restore it to ITEM_DIR and reload().
static var content_dir: String = ITEM_DIR
const ID_PREFIX: String = "item/"

static var _by_id: Dictionary[StringName, ItemDefinition] = {}
static var _problems: PackedStringArray = PackedStringArray()
static var _loaded: bool = false


## The definition for an id, or null. A typo yields null rather than a crash; the caller
## decides whether that is a refusal or an error.
static func definition(item_id: StringName) -> ItemDefinition:
	_ensure_loaded()
	if not _by_id.has(item_id):
		return null
	return _by_id[item_id]


static func has(item_id: StringName) -> bool:
	_ensure_loaded()
	return _by_id.has(item_id)


static func all() -> Dictionary[StringName, ItemDefinition]:
	_ensure_loaded()
	return _by_id


static func count() -> int:
	_ensure_loaded()
	return _by_id.size()


## Every content error found while scanning. Empty means the catalogue is sound.
static func problems() -> PackedStringArray:
	_ensure_loaded()
	return _problems


## Static state survives a scene reload and a new game, which is right for immutable content
## and wrong while authoring or testing. Tests and the validator call this.
static func rescan() -> void:
	_by_id.clear()
	_problems = PackedStringArray()
	_loaded = false
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	for path: String in resource_paths(content_dir):
		_register(path)
	# NO ITEMS IS NOT A PROBLEM. It was one until T1.2, and it made a stripped template fail its
	# own content gate on the first command of docs/NEW_GAME.md. An empty folder is the legal
	# starting state of a base template; a file that is present and does not load is the real
	# error, and _register reports that per file. Whether a GAME needs items is that game's
	# question, not this base's.


## Public so the validator can print exactly what the scan saw. That printout is how the
## undocumented method's behaviour stays a recorded fact rather than an assumption.
static func resource_paths(directory: String) -> PackedStringArray:
	var found: PackedStringArray = ResourceLoader.list_directory(directory)
	if found.is_empty():
		found = DirAccess.get_files_at(directory)
	var out: PackedStringArray = PackedStringArray()
	for entry: String in found:
		var full: String = _normalise(directory, entry)
		if full != "" and not out.has(full):
			out.append(full)
	return out


## Absorbs every difference between running from source and from an exported .pck, and
## between the two scanning methods: bare name or full path, .tres or a converted .res, and
## the .remap/.import indirection.
static func _normalise(directory: String, entry: String) -> String:
	var name: String = entry.trim_suffix(".remap").trim_suffix(".import")
	if not (name.ends_with(".tres") or name.ends_with(".res")):
		return ""
	if name.begins_with("res://"):
		return name
	return "%s/%s" % [directory, name]


static func _register(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	var definition: ItemDefinition = resource as ItemDefinition
	if definition == null:
		_problems.append("%s is not an ItemDefinition" % path)
		return
	var required: StringName = StringName(ID_PREFIX + path.get_file().get_basename())
	if definition.id != required:
		_problems.append("%s declares id '%s' but its file name requires '%s'" % [
			path, definition.id, required,
		])
		return
	if _by_id.has(definition.id):
		_problems.append("duplicate item id '%s' at %s" % [definition.id, path])
		return
	_problems.append_array(definition.problems())
	_by_id[definition.id] = definition
