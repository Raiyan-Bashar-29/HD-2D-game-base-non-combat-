class_name AreaDb
extends RefCounted
## Every AreaDef in the project, found by scanning data/areas and cached by id.
##
## THE FIFTH REGISTRY, AND IT MAKES T3.1 A STRONGER CASE RATHER THAN A WEAKER ONE.
## `schedule_db.gd` said "three is a pattern, four is a problem"; WP-08 produced the fourth,
## reconsidered, and kept the copy with a board row rather than a shrug — because GDScript has
## no generics, so a shared base could only cache `Resource` and hand it back untyped, making
## all four accessors a cast at the call site against non-negotiable #2. That reasoning has not
## changed and is not repeated here. What HAS changed is the arithmetic: five copies of the same
## thirty lines is thirty lines of duplication with five places to fix a scan bug, and the
## refactor that pays — a base holding the cache plus a thin typed façade each — is now worth
## measurably more than it was. **T3.1 on the board, and this file is the evidence for it.**
##
## THE ID HAS NO PREFIX, unlike `item/` and `quest/`. See `area_def.gd`'s header: an area id is
## already a public identifier, because it is a folder name, and prefixing it here would put a
## translation table between this registry and `Director`.
##
## Everything else is ADR-0006 verbatim: a scan is the only option where dropping a .tres in a
## folder is the entire act, a hand-maintained list rots, and a generated manifest fails
## SILENTLY when someone forgets to regenerate it.
##
## OWNS: finding area definitions on disk, caching them by id, and reporting what is wrong.
## MUST NOT: know whether an area is discovered, load an area scene, or touch an autoload.
## Problems are RETURNED, never logged, so tools/check_content.gd can use this class under
## `--script`.

const AREA_DIR: String = "res://data/areas"

## The directory actually scanned. A CONTENT ROOT rather than a constant, for the reason every
## other registry has one: a game may keep its areas somewhere else, and the test fixtures point
## this at a temp directory so the map can be proved with no authored content on disk at all.
static var content_dir: String = AREA_DIR

static var _by_id: Dictionary[StringName, AreaDef] = {}
static var _problems: PackedStringArray = PackedStringArray()
static var _loaded: bool = false


## The definition for an area id, or null. Null is the ordinary answer for an area a game has
## not put on its map, not an error: an area with no def is simply not somewhere you can see or
## travel to, which is a legitimate thing for a side room to be.
static func area(area_id: StringName) -> AreaDef:
	_ensure_loaded()
	if not _by_id.has(area_id):
		return null
	return _by_id[area_id]


static func has(area_id: StringName) -> bool:
	_ensure_loaded()
	return _by_id.has(area_id)


static func all() -> Dictionary[StringName, AreaDef]:
	_ensure_loaded()
	return _by_id


## Every mapped area id, sorted. THROUGH `String`, never `Array[StringName].sort()`, which
## orders by the StringName's internal handle and not alphabetically — gotcha 33, measured in
## WP-09 where two ids came back reversed with one failing assertion as the only trace. A map
## and an assertion both need a stable order out of a Dictionary that has none.
static func ids() -> Array[StringName]:
	_ensure_loaded()
	var out: Array[StringName] = []
	for area_id: StringName in _by_id:
		out.append(area_id)
	out.sort_custom(_before)
	return out


static func _before(a: StringName, b: StringName) -> bool:
	return String(a) < String(b)


static func count() -> int:
	_ensure_loaded()
	return _by_id.size()


static func problems() -> PackedStringArray:
	_ensure_loaded()
	return _problems


## rescan() AND NOT reload(). `Script` declares `reload()`, and a GDScript identifier IS the
## script object, so `AreaDb.reload()` would dispatch to the native method and silently reset
## every static variable in this file, `content_dir` included. See gotcha 17.
static func rescan() -> void:
	_by_id.clear()
	_problems = PackedStringArray()
	_loaded = false
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	for path: String in ItemDb.resource_paths(content_dir):
		_register(path)
	# NO AREAS ON THE MAP IS NOT A PROBLEM, and the folder need not exist. Same reasoning as
	# every other registry, and the same T1.2 finding: an empty content root is the legal
	# starting state of a base template. A game with no world map authors none of these and
	# `MapScreen` draws its empty state.


static func _register(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	var found: AreaDef = resource as AreaDef
	if found == null:
		_problems.append("%s is not an AreaDef" % path)
		return
	var required: StringName = StringName(path.get_file().get_basename())
	if found.id != required:
		_problems.append("%s declares id '%s' but its file name requires '%s'" % [
			path, found.id, required,
		])
		return
	if _by_id.has(found.id):
		_problems.append("duplicate area id '%s' at %s" % [found.id, path])
		return
	_problems.append_array(found.problems())
	_by_id[found.id] = found
